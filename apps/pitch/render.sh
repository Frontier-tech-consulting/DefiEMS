#!/usr/bin/env bash
#
# Render the deck and the memo to PDF.
#
#   ./render.sh              both
#   ./render.sh deck         one of them
#
# No build step: both documents are static HTML whose geometry comes from `@page` in their own
# stylesheets, so Chrome's print pipeline is the whole toolchain.
#
# ## Why this does not trust Chrome's exit code
#
# `--print-to-pdf` returns non-zero when `--virtual-time-budget` expires, *even when it has already
# written a complete file* — which it does consistently, because the web fonts keep a connection open
# past the budget. Treating that as failure would report a broken build on every good run; treating
# it as success would hide a real one. So the exit code is ignored and the artifact is checked.
set -euo pipefail

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/out"
PROFILE="$HERE/.chrome-profile"

mkdir -p "$OUT"

if [ ! -x "$CHROME" ]; then
  echo "Chrome not found at: $CHROME" >&2
  echo "Set CHROME=/path/to/chrome if it lives elsewhere." >&2
  exit 1
fi

# A throwaway profile. Headless Chrome refuses to start against a profile another instance holds, and
# the default one is almost always held by the browser the author is working in.
rm -rf "$PROFILE"

render_one() {
  local name="$1" dir="$2" src="$HERE/$2/index.html"

  if [ ! -f "$src" ]; then
    echo "  $name: no $src" >&2
    return 1
  fi

  rm -f "$OUT/$name.pdf"

  # Chrome is started in the background and reaped by hand, rather than waited on. It writes a
  # complete PDF and then does not exit: the web fonts keep a connection open, a pending request
  # pauses virtual time, and so `--virtual-time-budget` never expires. Waiting on the process hangs
  # the build with a finished PDF already on disk. The artifact is the signal — polled until its size
  # settles — and Chrome is killed once it has one.
  "$CHROME" \
    --headless --disable-gpu --no-pdf-header-footer \
    --user-data-dir="$PROFILE" \
    --virtual-time-budget=25000 \
    --print-to-pdf="$OUT/$name.pdf" \
    "file://$src" >/dev/null 2>&1 &
  local chrome_pid=$!

  # Up to 60s, then the checks below report whatever is actually on disk.
  local waited=0 last=0 size
  while [ "$waited" -lt 60 ]; do
    size=$(stat -f%z "$OUT/$name.pdf" 2>/dev/null || echo 0)
    if [ "$size" -gt 10000 ] && [ "$size" = "$last" ]; then
      break
    fi
    last="$size"
    sleep 1
    waited=$((waited + 1))
  done

  kill "$chrome_pid" 2>/dev/null || true
  wait "$chrome_pid" 2>/dev/null || true

  if [ ! -s "$OUT/$name.pdf" ]; then
    echo "  $name: FAILED — no PDF written" >&2
    return 1
  fi

  local bytes pages
  bytes=$(stat -f%z "$OUT/$name.pdf" 2>/dev/null || echo 0)
  if [ "$bytes" -lt 10000 ]; then
    echo "  $name: FAILED — $bytes bytes is too small to be a rendered document" >&2
    return 1
  fi

  # macOS Spotlight indexes PDFs, which gives a page count without a PDF library. There is no
  # poppler and no working pip on this machine, so this is the check that exists. It indexes
  # asynchronously, so the count is usually not there the instant the file lands — without the
  # retries this reports "(null)" on every fresh render.
  local pages="?" tries=0
  while [ "$tries" -lt 5 ]; do
    pages=$(mdls -raw -name kMDItemNumberOfPages "$OUT/$name.pdf" 2>/dev/null || echo "?")
    case "$pages" in
      "" | "(null)") pages="?" ;;
      *) break ;;
    esac
    sleep 1
    tries=$((tries + 1))
  done

  echo "  $name: ok · $pages page(s) · $bytes bytes · $OUT/$name.pdf"
}

target="${1:-all}"
status=0

echo "rendering into $OUT"
case "$target" in
  all)
    render_one deck deck || status=1
    render_one memo memo || status=1
    ;;
  deck | memo)
    render_one "$target" "$target" || status=1
    ;;
  *)
    echo "usage: ./render.sh [deck|memo]" >&2
    exit 2
    ;;
esac

rm -rf "$PROFILE"
exit "$status"
