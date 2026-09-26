#!/usr/bin/env bash
# Run Playwright demo specs with project-local browsers and quiet output.
#   demo.sh install          install Chromium into node_modules (once per checkout)
#   demo.sh <spec file>...   run demo specs; converts new .demo/*.webm to .mp4 when ffmpeg exists
set -euo pipefail
export PLAYWRIGHT_BROWSERS_PATH=0

case "${1:-}" in
  "")      sed -n '2,4p' "$0"; exit 1 ;;
  install) exec npx playwright install chromium ;;
esac

status=0
npx playwright test "$@" --reporter=line || status=$?

if command -v ffmpeg >/dev/null; then
  for v in .demo/*.webm; do
    [ -f "$v" ] && [ "$v" -nt "${v%.webm}.mp4" ] || continue
    ffmpeg -loglevel error -y -i "$v" "${v%.webm}.mp4" || true
  done
fi
exit "$status"
