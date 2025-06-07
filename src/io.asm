; =============================================================================
; pForth - Z80 Input/Output Primitives
; =============================================================================
; z80asm-compatible syntax.

; -----------------------------------------------------------------------------
; KEY ( -- char )
; -----------------------------------------------------------------------------
; Reads a character from port 1 (z88dk-ticks -iochar=1).
; Places the ASCII character value onto the data stack.
; -----------------------------------------------------------------------------
KEY_NFA:
    ; Name Field: Length 3, bit 7 set in first and last characters
    db $83, 'K', 'E', $D9
    
    ; Link Field: First word in dictionary chain, points to 0
KEY_LFA:
    dw 0
    
    ; Code Field: Points to the code execution entry
KEY_CFA:
    dw KEY_code

KEY_code:
    in a, (TTY_DATA_PORT)

    ; Push the current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    ; Load the new character into TOS (DE)
    ld d, 0
    ld e, a

    jp NEXT

; -----------------------------------------------------------------------------
; EMIT ( char -- )
; -----------------------------------------------------------------------------
; Writes a character from the top of the data stack (TOS) to port 1.
; -----------------------------------------------------------------------------
EMIT_NFA:
    ; Name Field: Length 4, bit 7 set in first and last characters
    db $84, 'E', 'M', 'I', $D4

    ; Link Field: Points to the previous word's NFA (KEY_NFA)
EMIT_LFA:
    dw KEY_NFA

    ; Code Field: Points to the code execution entry
EMIT_CFA:
    dw EMIT_code

EMIT_code:
    ld a, e
    call EMIT_char

    ; Pop the next value from the data stack (IX) into TOS (DE)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix

    jp NEXT


; Scaffold: character output helper (moves to control.asm with QUIT)
EMIT_char:
    out (TTY_DATA_PORT), a
    ret
