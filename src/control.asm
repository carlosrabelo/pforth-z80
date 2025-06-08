; =============================================================================
; pForth - Z80 Control & Compiler Words
; =============================================================================
; z80asm-compatible syntax.

; -----------------------------------------------------------------------------
; STATE ( -- addr )
; -----------------------------------------------------------------------------
; Returns the address of the compilation state variable in the user area.
; 0 = interpreting, non-zero = compiling.
; -----------------------------------------------------------------------------
STATE_NFA:
    ; Name Field: Length 5, bit 7 set in first and last characters
    db $85, 'S', 'T', 'A', 'T', $C5

    ; Link Field: Points to previous word's NFA (EXECUTE_NFA)
    dw EXECUTE_NFA

    ; Code Field: Points to the code execution entry
    dw STATE_CFA
STATE_CFA:
    dw STATE_code

STATE_code:
    ; Push current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    ; Load absolute address of STATE variable in user area into TOS (DE)
    ld de, USER_AREA_START + U_STATE

    jp NEXT

