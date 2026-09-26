#!/usr/bin/env bash
# Manage per-task worktrees in <repo>/.worktrees/<branch-slug>.
#
#   worktree.sh create  <branch> [base]   create worktree + dependencies (copy-on-write) + env + project setup
#   worktree.sh cleanup <branch>          project cleanup (e.g. drop DB) + remove worktree + delete local branch
#   worktree.sh list                      list task worktrees
#
# Project config: <repo>/.agents/worktree.conf.sh (example: worktree.conf.example.sh).
# Variables available to config functions: MAIN_ROOT, WT_DIR, WT_BRANCH, WT_SLUG, WT_INDEX.
set -euo pipefail

die() { echo "worktree.sh: $*" >&2; exit 1; }

common_dir=$(cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd) || die "not inside a git repository"
[ "$(basename "$common_dir")" = ".git" ] || die "bare repository / unsupported git layout: $common_dir"
MAIN_ROOT=$(dirname "$common_dir")
WT_BASE_DIR="$MAIN_ROOT/.worktrees"
CONF="$MAIN_ROOT/.agents/worktree.conf.sh"

# Defaults — overridden by the project config
CLONE_DIRS=()
ENV_FILES=(.env)
wt_env_overrides() { :; }
wt_setup() { :; }
wt_cleanup() { :; }
# shellcheck source=/dev/null
[ -f "$CONF" ] && . "$CONF"

slugify() { printf '%s' "$1" | sed 's#[^A-Za-z0-9._-]#-#g'; }

set_wt_vars() {
  WT_BRANCH=$1
  WT_SLUG=$(slugify "$1")
  WT_DIR="$WT_BASE_DIR/$WT_SLUG"
  export MAIN_ROOT WT_BRANCH WT_SLUG WT_DIR
}

# Small number unique per active worktree (for ports, Redis DB numbers, etc.)
alloc_index() {
  local n=1
  while grep -qx "$n" "$WT_BASE_DIR"/.index-* 2>/dev/null; do n=$((n + 1)); done
  echo "$n"
}

# Copy-on-write when the filesystem supports it (APFS, btrfs, XFS); plain copy otherwise.
cow_copy() {
  local src=$1 dst=$2
  case "$(uname -s)" in
    Darwin) cp -Rc "$src" "$dst" 2>/dev/null || { rm -rf "$dst"; cp -R "$src" "$dst"; } ;;
    Linux)  cp -R --reflink=auto "$src" "$dst" ;;
    *)      cp -R "$src" "$dst" ;;
  esac
}

set_env_var() {
  local file=$1 key=$2 value=$3 tmp
  tmp=$(mktemp)
  awk -v k="$key" -v v="$value" '
    $0 ~ "^[[:space:]]*(export[[:space:]]+)?" k "=" { print k "=" v; done = 1; next }
    { print }
    END { if (!done) print k "=" v }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

cmd_create() {
  local branch=${1:?"usage: worktree.sh create <branch> [base]"} base=${2:-}
  set_wt_vars "$branch"
  [ -e "$WT_DIR" ] && die "worktree already exists: $WT_DIR"
  git -C "$MAIN_ROOT" check-ignore -q ".worktrees/$WT_SLUG" || die ".worktrees/ is not in .gitignore"

  mkdir -p "$WT_BASE_DIR"
  if git -C "$MAIN_ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$MAIN_ROOT" worktree add "$WT_DIR" "$branch"
  else
    git -C "$MAIN_ROOT" worktree add -b "$branch" "$WT_DIR" ${base:+"$base"}
  fi

  WT_INDEX=$(alloc_index)
  echo "$WT_INDEX" > "$WT_BASE_DIR/.index-$WT_SLUG"
  export WT_INDEX

  local d f line
  for d in ${CLONE_DIRS[@]+"${CLONE_DIRS[@]}"}; do
    [ -e "$MAIN_ROOT/$d" ] && [ ! -e "$WT_DIR/$d" ] || continue
    mkdir -p "$(dirname "$WT_DIR/$d")"
    cow_copy "$MAIN_ROOT/$d" "$WT_DIR/$d"
  done

  for f in ${ENV_FILES[@]+"${ENV_FILES[@]}"}; do
    [ -f "$WT_DIR/$f" ] || { [ -f "$MAIN_ROOT/$f" ] && cp "$MAIN_ROOT/$f" "$WT_DIR/$f"; } || continue
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      set_env_var "$WT_DIR/$f" "${line%%=*}" "${line#*=}"
    done < <(wt_env_overrides "$f")
  done

  (cd "$WT_DIR" && wt_setup) || die "wt_setup failed. Fix it, or remove the worktree with: worktree.sh cleanup $branch"
  echo "Worktree ready: $WT_DIR (index $WT_INDEX)"
}

cmd_cleanup() {
  local branch=${1:?"usage: worktree.sh cleanup <branch>"}
  set_wt_vars "$branch"
  [ -d "$WT_DIR" ] || die "worktree not found: $WT_DIR"
  # Checked before wt_cleanup so the DB is not dropped when the worktree cannot be removed.
  [ -z "$(git -C "$WT_DIR" status --porcelain)" ] \
    || die "worktree has uncommitted changes or untracked files; check it first"
  WT_INDEX=$(cat "$WT_BASE_DIR/.index-$WT_SLUG" 2>/dev/null || echo "")
  export WT_INDEX

  (cd "$WT_DIR" && wt_cleanup) || die "wt_cleanup failed; worktree not removed"
  git -C "$MAIN_ROOT" worktree remove "$WT_DIR"
  rm -f "$WT_BASE_DIR/.index-$WT_SLUG"
  git -C "$MAIN_ROOT" branch -d "$branch" \
    || echo "git does not consider branch '$branch' merged (squash merge?). If you are sure it is merged: git branch -D $branch" >&2
}

cmd_list() {
  git -C "$MAIN_ROOT" worktree list | grep -F "$WT_BASE_DIR/" || echo "(no task worktrees)"
}

case "${1:-}" in
  create)  shift; cmd_create "$@" ;;
  cleanup) shift; cmd_cleanup "$@" ;;
  list)    cmd_list ;;
  *)       sed -n '2,10p' "$0"; exit 1 ;;
esac
