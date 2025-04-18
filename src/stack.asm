; =============================================================================
; pForth - Z80 Stack Manipulation Primitives
; =============================================================================

; -----------------------------------------------------------------------------
; DUP ( x -- x x )
; Duplicates the top of the data stack.
; -----------------------------------------------------------------------------
DUP_NFA:
    ; Name Field: Length 3, bit 7 set in first ('D') and last ('P') characters
    ; Length 3 with bit 7 set = $83
    ; First char 'D' ($44) with bit 7 set = $C4
    ; Last char 'P' ($50) with bit 7 set = $D0
    db $83, $C4, 'U', $D0

    ; Link Field: Points to previous word's NFA (LEAVE_NFA)
    dw SEMICOLON_NFA

DUP_CFA:
    dw DUP_code

DUP_code:
    ; Push the current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    
    jp NEXT

; -----------------------------------------------------------------------------
; DROP ( x -- )
; Discards the top of the data stack.
; -----------------------------------------------------------------------------
DROP_NFA:
    ; Name Field: Length 4, bit 7 set in length ($84), first ('D') and last ('P') characters
    db $84, $C4, 'R', 'O', $D0

    ; Link Field: Points to DUP_NFA
    dw DUP_NFA

DROP_CFA:
    dw DROP_code

DROP_code:
    ; Load the new TOS (DE) from the data stack (IX) and adjust DSP (IX)
    ld a, (ix+0)
    ld e, a
    ld a, (ix+1)
    ld d, a
    inc ix
    inc ix
    
    jp NEXT

