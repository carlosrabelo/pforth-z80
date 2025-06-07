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
start_end:

    ; Padding to align Forth Dictionary exactly at $0400
    defs $0400 - start_end

; -----------------------------------------------------------------------------
; Forth Dictionary Segment
; -----------------------------------------------------------------------------
    include "src/inner.asm"
    include "src/io.asm"

; -----------------------------------------------------------------------------
; Dictionary Entry Point configuration
; -----------------------------------------------------------------------------
LAST_NFA: equ EMIT_NFA

; -----------------------------------------------------------------------------
; End of Assembly-compiled Forth. Next memory is dynamically allocated.
; -----------------------------------------------------------------------------
FORTH_FREE_MEM:
