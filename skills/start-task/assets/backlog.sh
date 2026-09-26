#!/usr/bin/env bash
# Show backlog & progress from the task files in docs/tasks/ — main checkout + every task worktree.
#
#   backlog.sh [list]    open items by priority: features (+ progress) and tasks with Status: Backlog
#   backlog.sh active    tasks with Status: Active, with their branch & location
#   backlog.sh features  every feature with the status of each of its tasks
#
# When the same file exists in several places, the most advanced status wins
# (Backlog < Active < Done/Cancelled). Feature files only store Backlog | Cancelled;
# a feature's Split / Active / Done is computed from its task files.
set -euo pipefail

die() { echo "backlog.sh: $*" >&2; exit 1; }

common_dir=$(cd "$(git rev-parse --git-common-dir 2>/dev/null)" 2>/dev/null && pwd) || die "not inside a git repository"
MAIN_ROOT=$(dirname "$common_dir")

mode=${1:-list}
case "$mode" in list|active|features) ;; *) sed -n '2,9p' "$0"; exit 1 ;; esac

files=()
for f in "$MAIN_ROOT"/docs/tasks/*.md "$MAIN_ROOT"/.worktrees/*/docs/tasks/*.md; do
  [ -f "$f" ] && files+=("$f")
done
[ ${#files[@]} -gt 0 ] || { echo "(no task files in docs/tasks/)"; exit 0; }

awk -v mode="$mode" '
function val(line, key) {
  sub("^" key ":[ \t]*", "", line); gsub(/`/, "", line); sub(/[ \t]+$/, "", line)
  if (line ~ /^</) return ""
  if (line ~ /\|/) return "?"
  return line
}
function srank(s) {
  if (s == "Backlog") return 1; if (s == "Split") return 2; if (s == "Active") return 3
  if (s == "Done" || s == "Cancelled") return 4; return 0
}
function prank(p) { return p == "high" ? 1 : (p == "medium" ? 2 : (p == "low" ? 3 : 4)) }
function commit() {
  if (cur == "") return
  if (!(cur in S) || srank(s) >= srank(S[cur])) {
    T[cur] = t; J[cur] = (j == "" ? "Task" : j); S[cur] = s; P[cur] = p
    F[cur] = f; D[cur] = d; B[cur] = b; L[cur] = loc
  }
}
function blocked(k,    n, i, deps, out) {
  out = ""; n = split(D[k], deps, /[ ,]+/)
  for (i = 1; i <= n; i++) if (deps[i] != "" && S[deps[i]] != "Done") out = out (out == "" ? "" : ",") deps[i]
  return out
}
function featstate(k,    x, tot, done, act, canc) {
  tot = done = act = canc = 0
  for (x in S) if (F[x] == k) {
    tot++
    if (S[x] == "Done") done++; else if (S[x] == "Active") act++; else if (S[x] == "Cancelled") canc++
  }
  NDONE = done; NLIVE = tot - canc
  if (S[k] == "Cancelled") return "Cancelled"
  if (tot == 0) return (S[k] == "" ? "?" : S[k])
  if (NLIVE > 0 && done == NLIVE) return "Done"
  if (act > 0 || done > 0) return "Active"
  return "Split"
}
function prio(k) { return P[k] != "" ? P[k] : (F[k] != "" && P[F[k]] != "" ? P[F[k]] : "-") }

FNR == 1 {
  commit()
  cur = FILENAME; sub(/.*\//, "", cur); sub(/\.md$/, "", cur)
  loc = "main"
  if (FILENAME ~ /\/\.worktrees\//) { loc = FILENAME; sub(/.*\/\.worktrees\//, "", loc); sub(/\/.*/, "", loc) }
  t = j = s = p = f = d = b = ""; hdr = 1
  if ($0 ~ /^# /) t = substr($0, 3)
  next
}
/^## / { hdr = 0 }
hdr && /^Type:/     { j = val($0, "Type") }
hdr && /^Status:/   { s = val($0, "Status") }
hdr && /^Priority:/ { p = val($0, "Priority") }
hdr && /^Feature:/  { f = val($0, "Feature") }
hdr && /^Depends:/  { d = val($0, "Depends") }
hdr && /^Branch:/   { b = val($0, "Branch") }

END {
  commit()
  for (k in S) {
    if (mode == "list") {
      if (J[k] == "Feature") {
        st = featstate(k)
        if (st == "Done" || st == "Cancelled") continue
        info = (NLIVE > 0 ? NDONE "/" NLIVE " tasks done" : "not split yet")
        printf "%d|0|%s\t%-7s %-8s %-28s %-9s %-30s %s\n", prank(prio(k)), k, prio(k), "Feature", k, st, info, T[k]
      } else if (S[k] == "Backlog") {
        info = (F[k] != "" ? "feature: " F[k] : "")
        bl = blocked(k); if (bl != "") info = info (info == "" ? "" : "; ") "blocked by: " bl
        printf "%d|1|%s\t%-7s %-8s %-28s %-9s %-30s %s\n", prank(prio(k)), k, prio(k), "Task", k, S[k], info, T[k]
      }
    } else if (mode == "active") {
      if (J[k] != "Feature" && S[k] == "Active")
        printf "%s\t%-28s %-36s %-24s %s\n", k, k, (B[k] == "" ? "-" : B[k]), L[k], T[k]
    } else if (mode == "features") {
      if (J[k] == "Feature") {
        st = featstate(k)
        printf "%d|%s|0\t[%s] %s — %s (%s", prank(prio(k)), k, prio(k), k, T[k], st
        if (NLIVE > 0) printf ", %d/%d tasks done", NDONE, NLIVE
        printf ")\n"
      } else if (F[k] != "") {
        bl = blocked(k)
        printf "%d|%s|1|%s\t    - %-26s %-9s %s%s\n", prank(prio(F[k])), F[k], k, k, S[k], T[k], (bl != "" ? "  (blocked by: " bl ")" : "")
      }
    }
  }
}
' "${files[@]}" | sort | cut -f2- | {
  case "$mode" in
    list)   printf "%-7s %-8s %-28s %-9s %-30s %s\n" PRIO TYPE SLUG STATUS NOTE TITLE ;;
    active) printf "%-28s %-36s %-24s %s\n" SLUG BRANCH LOCATION TITLE ;;
  esac
  cat
}
