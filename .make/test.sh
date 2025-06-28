#!/usr/bin/env bash
# test.sh - Source list check plus optional z88dk-ticks assembly tests
# -----------------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SRC_DIR="src"
BUILD_SCRIPT=".make/build.sh"
OUT_FILE="bin/pforth.bin"

./.make/build.sh

if [[ ! -f "$OUT_FILE" ]]; then
    echo "test: missing $OUT_FILE" >&2
    exit 1
fi

# Every source file must be listed in build.sh, exist on disk, and be
# pulled in from main.asm (except main.asm itself).
mapfile -t SRC_FILES < <(find "$SRC_DIR" -maxdepth 1 -type f -name '*.asm' | sed 's|.*/||' | sort)
for file in "${SRC_FILES[@]}"; do
    if ! grep -qE "^[[:space:]]*\"${file}\"" "$BUILD_SCRIPT"; then
        echo "test: $file is not listed in $BUILD_SCRIPT" >&2
        exit 1
    fi
    if [[ "$file" != "main.asm" ]] && ! grep -qE "include[[:space:]]+\"src/${file}\"" "${SRC_DIR}/main.asm"; then
        echo "test: $file is not included from ${SRC_DIR}/main.asm" >&2
        exit 1
    fi
done

echo "test: source list OK"

LABEL_SCAN="bin/pforth.asm"
LABELS=(
    start
    NEXT
    DOCOL
    SEMI
    KEY_code
    EMIT_char
    QUIT_code
    INTERPRET_internal
    FORTH_FREE_MEM
    LAST_NFA
)

for label in "${LABELS[@]}"; do
    if ! grep -qE "^[[:space:]]*${label}:" "$LABEL_SCAN"; then
        echo "test: missing label ${label} in $LABEL_SCAN" >&2
        exit 1
    fi
done

echo "test: labels OK"

if ! command -v z88dk-ticks >/dev/null 2>&1; then
    echo "test: z88dk-ticks not installed; skipping runtime tests"
    exit 0
fi

python3 tests/run_tests.py
