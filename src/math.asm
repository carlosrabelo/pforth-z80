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

; -----------------------------------------------------------------------------
; AND ( x1 x2 -- x3 )
; Performs a bitwise AND on the top two stack values.
; -----------------------------------------------------------------------------
AND_NFA:
    ; Name Field: Length 3, bit 7 set in length ($83), first ('A') and last ('D') characters
    db $83, $C1, 'N', $C4

    ; Link Field: Points to MINUS_NFA
    dw MINUS_NFA

AND_CFA:
    dw AND_code

AND_code:
    ; Load the operand x1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Perform bitwise AND of HL (x1) and DE (x2)
    ld a, l
    and e
    ld l, a
    
    ld a, h
    and d
    ld h, a
    
    ; Store result back into TOS (DE)
    ld d, h
    ld e, l
    
    ; Adjust DSP (IX) past x1
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; OR ( x1 x2 -- x3 )
; Performs a bitwise OR on the top two stack values.
; -----------------------------------------------------------------------------
OR_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('O') and last ('R') characters
    db $82, $CF, $D2

    ; Link Field: Points to AND_NFA
    dw AND_NFA

OR_CFA:
    dw OR_code

OR_code:
    ; Load the operand x1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Perform bitwise OR of HL (x1) and DE (x2)
    ld a, l
    or e
    ld l, a
    
    ld a, h
    or d
    ld h, a
    
    ; Store result back into TOS (DE)
    ld d, h
    ld e, l
    
    ; Adjust DSP (IX) past x1
    inc ix
    inc ix
    
    jp NEXT

