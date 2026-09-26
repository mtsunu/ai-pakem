#!/usr/bin/env bash
# Manage per-task worktrees in <repo>/.worktrees/<branch-slug>.
#
#   worktree.sh create  <branch> [base]   create worktree + dependencies (copy-on-write) + env + project setup
#   worktree.sh cleanup <branch>          project cleanup (e.g. drop DB) + remove worktree + delete local branch
#   worktree.sh list                      list task worktrees
#   worktree.sh graph [--no-cluster]      refresh graphify-out/ of the current checkout from its diff
#
# graphify (optional; project-local .agents/.venv/bin/graphify preferred over PATH):
# if the main checkout has graphify-out/ (gitignored), create copies it
# copy-on-write, and graph/cleanup re-extract only the files changed since the commit the graph
# was built at (graphify-out/.built-at). No LLM, no tokens. Output goes to .worktrees/.graphify.log.
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

# graphify binary + Python: project-local venv first, then PATH.
GRAPHIFY_BIN=""; GRAPHIFY_PY=""
if [ -x "$MAIN_ROOT/.agents/.venv/bin/graphify" ]; then
  GRAPHIFY_BIN="$MAIN_ROOT/.agents/.venv/bin/graphify"; GRAPHIFY_PY="$MAIN_ROOT/.agents/.venv/bin/python"
elif command -v graphify >/dev/null; then
  GRAPHIFY_BIN=graphify
fi

# Update graphify-out/ in $1 from the files changed since graphify-out/.built-at.
# $2 = 1 to recluster, 0 to skip clustering (faster). Never fails the caller.
graph_update() {
  local dir=$1 cluster=${2:-1} log="$WT_BASE_DIR/.graphify.log"
  [ -f "$dir/graphify-out/graph.json" ] && [ -n "$GRAPHIFY_BIN" ] || return 0
  mkdir -p "$WT_BASE_DIR"
  (
    cd "$dir" || exit 0
    full=1
    base=$(cat graphify-out/.built-at 2>/dev/null || true)
    if [ -n "$base" ] && git cat-file -e "$base^{commit}" 2>/dev/null; then
      changed=$( { git diff --name-only "$base"; git ls-files --others --exclude-standard; } \
        | { grep -v '^graphify-out/' || true; } | sort -u)
      if [ -z "$changed" ]; then git rev-parse HEAD > graphify-out/.built-at; exit 0; fi
      py=${GRAPHIFY_PY:-$(cat graphify-out/.graphify_python 2>/dev/null || echo python3)}
      rc=0
      # Diff mode uses graphify's internal _rebuild_code (as its post-commit hook does);
      # if that API is missing or changed, fall back to the public `graphify update`.
      printf '%s\n' "$changed" | "$py" -c '
import sys
from pathlib import Path
try:
    from graphify.watch import _rebuild_code
except Exception:
    sys.exit(3)
paths = [Path(line) for line in sys.stdin.read().splitlines() if line]
try:
    ok = _rebuild_code(Path("."), changed_paths=paths, no_cluster=sys.argv[1] == "0", block_on_lock=True)
except TypeError:
    sys.exit(3)
sys.exit(0 if ok else 1)
' "$cluster" >>"$log" 2>&1 || rc=$?
      case "$rc" in
        0) full=0 ;;
        1) echo "worktree.sh: graphify update failed (see $log)" >&2; exit 0 ;;
      esac
    fi
    if [ "$full" = 1 ]; then
      if [ "$cluster" = 0 ]; then set -- --no-cluster; else set --; fi
      "$GRAPHIFY_BIN" update . "$@" >>"$log" 2>&1 || { echo "worktree.sh: graphify update failed (see $log)" >&2; exit 0; }
    fi
    git rev-parse HEAD > graphify-out/.built-at
  )
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

  # graphify: copy the main graph; refresh it only if it was built at another commit.
  if [ -d "$MAIN_ROOT/graphify-out" ] && [ ! -e "$WT_DIR/graphify-out" ]; then
    if git -C "$WT_DIR" check-ignore -q graphify-out/; then
      cow_copy "$MAIN_ROOT/graphify-out" "$WT_DIR/graphify-out"
      [ "$(cat "$WT_DIR/graphify-out/.built-at" 2>/dev/null)" = "$(git -C "$WT_DIR" rev-parse HEAD)" ] \
        || graph_update "$WT_DIR" 0
    else
      echo "worktree.sh: graphify-out/ is not gitignored — not copied into the worktree" >&2
    fi
  fi

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
  graph_update "$MAIN_ROOT" 1
}

cmd_graph() {
  local cluster=1 dir
  [ "${1:-}" = "--no-cluster" ] && cluster=0
  dir=$(git rev-parse --show-toplevel)
  [ -f "$dir/graphify-out/graph.json" ] || die "no graphify-out/graph.json in $dir"
  [ -n "$GRAPHIFY_BIN" ] || die "graphify is not installed (.agents/.venv or PATH)"
  graph_update "$dir" "$cluster"
  echo "graph refreshed: $dir/graphify-out (log: $WT_BASE_DIR/.graphify.log)"
}

cmd_list() {
  git -C "$MAIN_ROOT" worktree list | grep -F "$WT_BASE_DIR/" || echo "(no task worktrees)"
}

case "${1:-}" in
  create)  shift; cmd_create "$@" ;;
  cleanup) shift; cmd_cleanup "$@" ;;
  list)    cmd_list ;;
  graph)   shift; cmd_graph "$@" ;;
  *)       sed -n '2,14p' "$0"; exit 1 ;;
esac
