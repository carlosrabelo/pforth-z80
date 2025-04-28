; =============================================================================
; pForth - Z80 Logic & Math Primitives
; =============================================================================

; -----------------------------------------------------------------------------
; + ( x1 x2 -- sum )
; Adds the top two values on the data stack.
; -----------------------------------------------------------------------------
PLUS_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '+' ($AB)
    db $81, $AB

    ; Link Field: Points to PLUS_STORE_NFA
    dw PLUS_STORE_NFA

PLUS_CFA:
    dw PLUS_code

PLUS_code:
    ; Load the operand x1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Add TOS (DE) to HL (x1)
    add hl, de
    
    ; Store the sum back into TOS (DE)
    ld d, h
    ld e, l
    
    ; Adjust DSP (IX) past x1
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; - ( x1 x2 -- diff )
; Subtracts x2 (TOS) from x1.
; -----------------------------------------------------------------------------
MINUS_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '-' ($AD)
    db $81, $AD

    ; Link Field: Points to PLUS_NFA
    dw PLUS_NFA

MINUS_CFA:
    dw MINUS_code

MINUS_code:
    ; Load the operand x1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Subtract TOS (DE) from HL (x1)
    or a
    sbc hl, de
    
    ; Store the difference back into TOS (DE)
    ld d, h
    ld e, l
    
    ; Adjust DSP (IX) past x1
    inc ix
    inc ix
    
    jp NEXT

