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

; -----------------------------------------------------------------------------
; XOR ( x1 x2 -- x3 )
; Performs a bitwise XOR on the top two stack values.
; -----------------------------------------------------------------------------
XOR_NFA:
    ; Name Field: Length 3, bit 7 set in length ($83), first ('X') and last ('R') characters
    db $83, $D8, 'O', $D2

    ; Link Field: Points to OR_NFA
    dw OR_NFA

XOR_CFA:
    dw XOR_code

XOR_code:
    ; Load the operand x1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Perform bitwise XOR of HL (x1) and DE (x2)
    ld a, l
    xor e
    ld l, a
    
    ld a, h
    xor d
    ld h, a
    
    ; Store result back into TOS (DE)
    ld d, h
    ld e, l
    
    ; Adjust DSP (IX) past x1
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; 0= ( x -- flag )
; Returns true (-1) if x is zero, false (0) otherwise.
; -----------------------------------------------------------------------------
ZERO_EQUALS_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('0') and last ('=') characters
    db $82, $B0, $BD

    ; Link Field: Points to XOR_NFA
    dw XOR_NFA

ZERO_EQUALS_CFA:
    dw ZERO_EQUALS_code

ZERO_EQUALS_code:
    ; Check if TOS (DE) is zero
    ld a, d
    or e
    jr nz, zero_eq_not_zero
    
    ; TOS is zero, return true ($FFFF)
    ld de, $FFFF
    jp NEXT
    
zero_eq_not_zero:
    ; TOS is not zero, return false ($0000)
    ld de, $0000
    jp NEXT

; -----------------------------------------------------------------------------
; 0< ( x -- flag )
; Returns true (-1) if x is negative, false (0) otherwise.
; -----------------------------------------------------------------------------
ZERO_LESS_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('0') and last ('<') characters
    db $82, $B0, $BC

    ; Link Field: Points to ZERO_EQUALS_NFA
    dw ZERO_EQUALS_NFA

ZERO_LESS_CFA:
    dw ZERO_LESS_code

ZERO_LESS_code:
    ; Check the sign bit (bit 15) of x (which is bit 7 of D)
    bit 7, d
    jr nz, zero_less_negative
    
    ; TOS is positive or zero, return false ($0000)
    ld de, $0000
    jp NEXT
    
zero_less_negative:
    ; TOS is negative, return true ($FFFF)
    ld de, $FFFF
    jp NEXT

; -----------------------------------------------------------------------------
; U< ( u1 u2 -- flag )
; Compares two unsigned 16-bit values and returns true (-1) if u1 < u2.
; -----------------------------------------------------------------------------
U_LESS_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('U') and last ('<') characters
    db $82, $D5, $BC

    ; Link Field: Points to ZERO_LESS_NFA
    dw ZERO_LESS_NFA

U_LESS_CFA:
    dw U_LESS_code

U_LESS_code:
    ; Load the operand u1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Compare HL (u1) and DE (u2) by subtracting DE from HL.
    ; If HL < DE, borrow occurs setting the Carry Flag (C).
    or a
    sbc hl, de
    
    jr c, u_less_true
    
    ; u1 >= u2, return false ($0000)
    ld de, $0000
    jr u_less_done
    
u_less_true:
    ; u1 < u2, return true ($FFFF)
    ld de, $FFFF
    
u_less_done:
    ; Adjust DSP (IX) past u1
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; = ( x1 x2 -- flag )
; Compares two 16-bit values and returns true (-1) if they are equal.
; -----------------------------------------------------------------------------
EQUALS_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '=' ($BD)
    db $81, $BD

    ; Link Field: Points to U_LESS_NFA
    dw U_LESS_NFA

EQUALS_CFA:
    dw EQUALS_code

EQUALS_code:
    ; Load the operand x1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Compare HL (x1) and DE (x2)
    or a
    sbc hl, de
    
    jr z, equals_true
    
    ; x1 != x2, return false ($0000)
    ld de, $0000
    jr equals_done
    
equals_true:
    ; x1 == x2, return true ($FFFF)
    ld de, $FFFF
    
equals_done:
    ; Adjust DSP (IX) past x1
    inc ix
    inc ix
    
    jp NEXT

