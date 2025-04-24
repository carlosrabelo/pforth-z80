; =============================================================================
; pForth - Z80 Memory & Register Access Primitives
; =============================================================================

; -----------------------------------------------------------------------------
; @ ( a -- x )
; Fetches a 16-bit value from memory address 'a'.
; -----------------------------------------------------------------------------
FETCH_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '@' ($C0)
    db $81, $C0

    ; Link Field: Points to R_FETCH_NFA
    dw R_FETCH_NFA

FETCH_CFA:
    dw FETCH_code

FETCH_code:
    ; Read the address from TOS (DE) into HL
    ld h, d
    ld l, e
    
    ; Load the 16-bit value at HL into TOS (DE)
    ld e, (hl)
    inc hl
    ld d, (hl)
    
    jp NEXT

