#!/usr/bin/env bash
# EXAMPLE — a test-only DB instance whose data lives in RAM, shared by all worktrees.
# Worktrees are isolated by DB name (see wt_db_name in worktree.conf.example.sh).
# Data is lost on reboot / `down` — tests must recreate their own data.
# Copy it into the project repo and adapt it.
#
#   ENGINE=mysql|postgres PORT=3307 SIZE_MB=2048 ramdb.example.sh up|down|status
set -euo pipefail

ENGINE=${ENGINE:-mysql}
PORT=${PORT:-3307}
SIZE_MB=${SIZE_MB:-2048}
NAME=${NAME:-testdb-ram}

die() { echo "ramdb: $*" >&2; exit 1; }

ram_dir() {
  case "$(uname -s)" in
    Darwin) echo "/Volumes/$NAME" ;;
    Linux)  echo "/dev/shm/$NAME" ;;   # /dev/shm is tmpfs; max size follows /dev/shm
    *)      die "unsupported OS" ;;
  esac
}

DIR=$(ram_dir)

mount_ram() {
  [ -d "$DIR" ] && return 0
  case "$(uname -s)" in
    Darwin)
      local dev sectors=$((SIZE_MB * 2048))
      # `diskutil image attach` on newer macOS; `hdiutil attach` (deprecated) on older ones.
      dev=$(diskutil image attach --noMount "ram://$sectors" 2>/dev/null | awk '/^\/dev\/disk/{print $1; exit}') \
        || dev=""
      [ -n "$dev" ] || dev=$(hdiutil attach -nomount "ram://$sectors" | awk '{print $1; exit}')
      diskutil erasevolume HFS+ "$NAME" "$dev" >/dev/null
      ;;
    Linux) mkdir -p "$DIR" ;;
  esac
}

unmount_ram() {
  [ -d "$DIR" ] || return 0
  case "$(uname -s)" in
    Darwin) diskutil eject "$DIR" >/dev/null ;;
    Linux)  rm -rf "$DIR" ;;
  esac
}

is_running() {
  case "$ENGINE" in
    mysql)    [ -f "$DIR/mysql.pid" ] && kill -0 "$(cat "$DIR/mysql.pid")" 2>/dev/null ;;
    postgres) [ -d "$DIR/data" ] && pg_ctl -D "$DIR/data" status >/dev/null 2>&1 ;;
  esac
}

up() {
  is_running && { echo "already running on port $PORT"; return 0; }
  mount_ram
  case "$ENGINE" in
    mysql)
      [ -d "$DIR/data" ] || mysqld --initialize-insecure --datadir="$DIR/data" --log-error="$DIR/init.log"
      # Durability off: this instance is for tests only.
      mysqld --datadir="$DIR/data" --port="$PORT" --bind-address=127.0.0.1 \
        --socket="$DIR/mysql.sock" --pid-file="$DIR/mysql.pid" --log-error="$DIR/error.log" \
        --mysqlx=OFF --skip-log-bin --sync-binlog=0 \
        --innodb-flush-log-at-trx-commit=0 --skip-innodb-doublewrite \
        --daemonize
      ;;
    postgres)
      [ -d "$DIR/data" ] || initdb -D "$DIR/data" -U postgres --auth=trust >/dev/null
      # -F = fsync off. Durability off: this instance is for tests only.
      pg_ctl -D "$DIR/data" -l "$DIR/postgres.log" \
        -o "-p $PORT -k $DIR -c listen_addresses=127.0.0.1 -F -c synchronous_commit=off -c full_page_writes=off" \
        start >/dev/null
      ;;
    *) die "unknown ENGINE: $ENGINE" ;;
  esac
  echo "test DB ($ENGINE) running on 127.0.0.1:$PORT, data in $DIR"
}

down() {
  if is_running; then
    case "$ENGINE" in
      mysql)
        local pid; pid=$(cat "$DIR/mysql.pid")
        kill "$pid"
        while kill -0 "$pid" 2>/dev/null; do sleep 0.5; done
        ;;
      postgres) pg_ctl -D "$DIR/data" stop -m fast >/dev/null ;;
    esac
  fi
  unmount_ram
  echo "test DB stopped, RAM released"
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  status) is_running && echo "running (port $PORT, $DIR)" || echo "not running" ;;
  *) sed -n '2,8p' "$0"; exit 1 ;;
esac
