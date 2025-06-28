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

