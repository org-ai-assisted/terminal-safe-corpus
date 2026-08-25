#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file LICENSE for copying conditions.

## AI-Assisted

## Cross-repo drift gate for the terminal-safe-corpus demos.
##
## Every demos/*.txt is deterministic generator output -- the generators are the
## single source of truth and live in OTHER repos. This gate regenerates each
## file from its generator and byte-compares it against the committed copy, so a
## generator change (or a hand edit) that leaves the corpus stale fails CI
## instead of shipping silently.
##
## Generator sources:
##   demos/unicode-gallery-safe-to-cat.txt <- dist-ai unicode-gallery.py
##   demos/art-safe-to-cat.txt             <- dist-ai truecolor-art.py
##   demos/terminal-attack-demo-...txt     <- terminal-poc-corpus tui-showcase payload.hex
##
## Env overrides (default to the CI sibling-checkout layout):
##   DIST_AI_REPO      dist-ai checkout root             (default ./_dist-ai)
##   POC_CORPUS_REPO   terminal-poc-corpus checkout root (default ./_poc-corpus)

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
shopt -s inherit_errexit
shopt -s shift_verbose
export LC_ALL=C

## Force the Python generators to emit UTF-8 regardless of LC_ALL, so the
## byte-comparison stays locale-independent (truecolor-art.py writes str, not bytes).
export PYTHONUTF8=1

dist_ai_repo="${DIST_AI_REPO:-./_dist-ai}"
poc_corpus_repo="${POC_CORPUS_REPO:-./_poc-corpus}"

## Run from the corpus repo root regardless of the caller's cwd.
repo_root=""
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "${repo_root}"

shots_dir="${dist_ai_repo}/usr/share/secure-terminal-shots"
unicode_gen="${shots_dir}/unicode-gallery.py"
art_gen="${shots_dir}/truecolor-art.py"
board_hex="${poc_corpus_repo}/poc/tui-showcase/payload.hex"

fail=0

tmp=""
tmp="$(mktemp --directory)"

## style-ok: no-safe-rm -- ships into a bare CI container with no safe-rm helper; rm only ever touches our own mktemp dir.
cleanup() {
   rm --recursive --force -- "${tmp}"
}
trap cleanup EXIT

## Decode the read-safe hex board (strip inline # comments + whitespace, unhexlify)
## and write the raw bytes to stdout. Pure stdlib, deterministic.
decode_board() {
   python3 - "${board_hex}" <<'PY'
import binascii, sys
src = open(sys.argv[1]).read()
hexed = ''.join(''.join(line.split('#', 1)[0].split()) for line in src.splitlines())
sys.stdout.buffer.write(binascii.unhexlify(hexed))
PY
}

## Regenerate demos/$1 with the command in "$@" (from arg 3 on) and byte-compare
## it against the committed copy; on drift print the regenerate command and mark fail.
check() {
   local committed
   local label
   local got
   committed="demos/$1"
   label="$2"
   got="${tmp}/$1.out"
   shift 2

   if [ ! -e "${committed}" ]; then
      printf '%s\n' "DRIFT: ${committed} is missing from the corpus" >&2
      fail=1
      return
   fi
   if ! "$@" > "${got}"; then
      printf '%s\n' "ERROR: regenerating ${committed} failed (generator: ${label})" >&2
      fail=1
      return
   fi
   if cmp -s -- "${got}" "${committed}"; then
      printf '%s\n' "ok: ${committed} matches ${label}"
      return
   fi

   local diffstat
   diffstat="$(cmp -- "${got}" "${committed}" 2>&1 || true)"
   printf '%s\n' \
      "DRIFT: ${committed} no longer matches ${label}" \
      "       regenerate + commit: ${label} > ${committed}" \
      "       first difference: ${diffstat}" >&2
   fail=1
}

## Fail loud if a generator source is absent (a bad checkout is an env bug, not "no drift").
for src in "${unicode_gen}" "${art_gen}" "${board_hex}"; do
   if [ ! -e "${src}" ]; then
      printf '%s\n' \
         "ERROR: generator source not found: ${src}" \
         "       set DIST_AI_REPO / POC_CORPUS_REPO to the checkout roots." >&2
      exit 1
   fi
done

check unicode-gallery-safe-to-cat.txt \
   "python3 ${unicode_gen}" \
   python3 "${unicode_gen}"

check art-safe-to-cat.txt \
   "python3 ${art_gen}" \
   python3 "${art_gen}"

check terminal-attack-demo-WARNING-display-only-safe.txt \
   "decode ${board_hex}" \
   decode_board

if [ "${fail}" -ne 0 ]; then
   printf '%s\n' \
      "" \
      "corpus drift detected: a demo no longer matches its generator." >&2
   exit 1
fi

printf '%s\n' \
   "" \
   "all 3 corpus demos match their generators; no drift."
