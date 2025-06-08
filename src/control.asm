; =============================================================================
; pForth - Z80 Control & Compiler Words
; =============================================================================
; z80asm-compatible syntax.

; -----------------------------------------------------------------------------
; LIT ( -- n )
; -----------------------------------------------------------------------------
; Pushes the 16-bit literal value following this word in the execution token
; stream onto the data stack.
; -----------------------------------------------------------------------------
LIT_NFA:
    ; Name Field: Length 3, bit 7 set in first and last characters
    db $83, 'L', 'I', $D4

    ; Link Field: Points to previous word's NFA (EXECUTE_NFA in io.asm)
    dw EXECUTE_NFA

    ; Code Field: Points to the code execution entry
    dw LIT_CFA
LIT_CFA:
    dw LIT_code

LIT_code:
    ; Push current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    ; Read 16-bit literal from IP (BC) into TOS (DE)
    ld a, (bc)
    ld e, a
    inc bc
    ld a, (bc)
    ld d, a
    inc bc

    jp NEXT


; -----------------------------------------------------------------------------
; STATE ( -- addr )
; -----------------------------------------------------------------------------
; Returns the address of the compilation state variable in the user area.
; 0 = interpreting, non-zero = compiling.
; -----------------------------------------------------------------------------
STATE_NFA:
    ; Name Field: Length 5, bit 7 set in first and last characters
    db $85, 'S', 'T', 'A', 'T', $C5

    ; Link Field: Points to previous word's NFA (LIT_NFA)
    dw LIT_NFA

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

