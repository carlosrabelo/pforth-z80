#!/usr/bin/env bash
# build.sh - Assemble pForth Z80 sources
# -----------------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SRC_DIR="src"
OUT_DIR="bin"
ASM_FILE="${OUT_DIR}/pforth.asm"
OUT_FILE="${OUT_DIR}/pforth.bin"

mkdir -p "$OUT_DIR"

# Include/concatenation order. Labels may be referenced before they are defined.
# src/main.asm includes the remaining modules; this list is the source-of-truth
# for test.sh (every file on disk must appear here).
FILES=(
    "main.asm"
    "config.asm"
)

for file in "${FILES[@]}"; do
    if [[ ! -f "${SRC_DIR}/${file}" ]]; then
        echo "build: missing ${SRC_DIR}/${file}" >&2
        exit 1
    fi
done

# Expand include directives into a single translation unit (pbasic-style).
expand_asm() {
    local src="$1"
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*include[[:space:]]+\"([^\"]+)\" ]]; then
            expand_asm "${BASH_REMATCH[1]}"
        else
            printf '%s\n' "$line"
        fi
    done < "$src"
}

expand_asm "${SRC_DIR}/main.asm" > "$ASM_FILE"

if command -v sjasmplus >/dev/null 2>&1; then
    sjasmplus --raw="$OUT_FILE" "$ASM_FILE"
elif command -v z80asm >/dev/null 2>&1; then
    z80asm "$ASM_FILE" -o "$OUT_FILE"
else
    echo "build: need sjasmplus or z80asm" >&2
    exit 1
fi

echo "Compiled Z80 binary: ${OUT_FILE}"
