; =============================================================================
; pForth - Z80 Main Entry Point & Bootstrap
; =============================================================================

    org $0000
    jp start                    ; Address $0000 (RST 00)

    ; Include configuration constants (does not emit code bytes)
    include "src/config.asm"

start:
    di                          ; Disable interrupts during setup
    ld sp, RETURN_STACK_BOTTOM  ; Initialize Return Stack (RSP)
    ld ix, DATA_STACK_BOTTOM    ; Initialize Data Stack (DSP)
    ld de, 0                    ; Initialize Top of Stack cache (TOS)
    halt
