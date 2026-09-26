#!/usr/bin/env bash
# EXAMPLE — a test-only DB instance with durability turned off, shared by all worktrees.
# Worktrees are isolated by DB name (see wt_db_name in worktree.conf.example.sh).
# Copy it into the project repo and adapt it.
#
#   ENGINE=mysql|postgres PORT=3307 RAM=1|0 ramdb.example.sh up|down|reset|status
#
#   RAM=1 (default)  data on a RAM disk; `down` releases the RAM and the data is gone.
#   RAM=0            data on disk in DISK_DIR (default <repo>/.worktrees/.testdb/<NAME>, gitignored);
#                    survives `down` and reboots. `reset` deletes it.
#
# Measured (MySQL 9.4, macOS SSD): turning durability off gives most of the speed-up
# (~2.6x on auto-commit inserts); RAM adds ~0-12% on top. RAM=0 is enough for most projects.
set -euo pipefail

ENGINE=${ENGINE:-mysql}
PORT=${PORT:-3307}
RAM=${RAM:-1}
SIZE_MB=${SIZE_MB:-2048}
NAME=${NAME:-testdb-ram}

die() { echo "ramdb: $*" >&2; exit 1; }

data_dir() {
  if [ "$RAM" = 1 ]; then
    case "$(uname -s)" in
      Darwin) echo "/Volumes/$NAME" ;;
      Linux)  echo "/dev/shm/$NAME" ;;   # /dev/shm is tmpfs; max size follows /dev/shm
      *)      die "unsupported OS" ;;
    esac
  else
    echo "${DISK_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.worktrees/.testdb/$NAME}"
  fi
}

DIR=$(data_dir)
# Unix socket paths are limited to ~104 characters (macOS) / 108 (Linux).
[ ${#DIR} -le 80 ] || die "data dir path too long for a unix socket (${#DIR} > 80 chars); set DISK_DIR to a shorter path"

prepare_dir() {
  [ -d "$DIR" ] && return 0
  if [ "$RAM" != 1 ]; then mkdir -p "$DIR"; return 0; fi
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

release_ram() {
  [ "$RAM" = 1 ] && [ -d "$DIR" ] || return 0
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
  prepare_dir
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
  echo "test DB ($ENGINE, $([ "$RAM" = 1 ] && echo RAM || echo disk)) running on 127.0.0.1:$PORT, data in $DIR"
}

stop() {
  is_running || return 0
  case "$ENGINE" in
    mysql)
      local pid; pid=$(cat "$DIR/mysql.pid")
      kill "$pid"
      while kill -0 "$pid" 2>/dev/null; do sleep 0.5; done
      ;;
    postgres) pg_ctl -D "$DIR/data" stop -m fast >/dev/null ;;
  esac
}

down() {
  stop
  if [ "$RAM" = 1 ]; then release_ram; echo "test DB stopped, RAM released"
  else echo "test DB stopped, data kept in $DIR"; fi
}

reset() {
  stop
  if [ "$RAM" = 1 ]; then release_ram; else rm -rf "$DIR"; fi
  echo "test DB stopped, data deleted"
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  reset) reset ;;
  status) is_running && echo "running (port $PORT, $DIR)" || echo "not running" ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac
