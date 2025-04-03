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

