# Project worktree config. Copy to <repo>/.agents/worktree.conf.sh and commit it.
# Read by .agents/skills/start-task/assets/worktree.sh.
#
# Variables available in the functions:
#   MAIN_ROOT  main repo folder         WT_DIR    worktree folder
#   WT_BRANCH  branch name              WT_SLUG   branch with odd characters replaced by "-"
#   WT_INDEX   1, 2, 3, … unique per active worktree (for ports, Redis DB numbers, etc.)

# Dependency folders cloned copy-on-write from the main checkout.
# Re-sync them in wt_setup (the install is fast because the content is already there).
# Do not list Python virtualenvs — they contain absolute paths and must be recreated.
CLONE_DIRS=(vendor node_modules)

# Env files (not committed) copied from the main checkout.
ENV_FILES=(.env .env.testing)

# Per-worktree DB name. Mind the DB name length limit (MySQL: 64 characters).
wt_db_name() {
  local s=${WT_SLUG//[-.]/_}
  echo "app_${s:0:50}"
}

# Values that must be unique per worktree. Called once per env file; print KEY=VALUE lines.
wt_env_overrides() {
  case "$1" in
    .env)
      echo "DB_DATABASE=$(wt_db_name)"
      echo "APP_PORT=$((8000 + WT_INDEX))"
      echo "REDIS_DB=${WT_INDEX}"
      echo "CACHE_PREFIX=${WT_SLUG}_"
      ;;
    .env.testing)
      echo "DB_DATABASE=$(wt_db_name)_test"
      # Example: test DB on the shared RAM instance (see ramdb.example.sh)
      # echo "DB_PORT=3307"
      ;;
  esac
}

# Runs inside the worktree once dependencies & env are ready.
wt_setup() {
  # Example — adapt to the project:
  # composer install --no-interaction
  # npm install
  # <create DB "$(wt_db_name)", then migrate + seed>
  :
}

# Runs inside the worktree before it is removed.
wt_cleanup() {
  # Example: drop DBs "$(wt_db_name)" and "$(wt_db_name)_test"
  :
}
