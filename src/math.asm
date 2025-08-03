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

; -----------------------------------------------------------------------------
; < ( n1 n2 -- flag )
; Compares two signed 16-bit values and returns true (-1) if n1 < n2.
; -----------------------------------------------------------------------------
LESS_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '<' ($BC)
    db $81, $BC

    ; Link Field: Points to EQUALS_NFA
    dw EQUALS_NFA

LESS_CFA:
    dw LESS_code

LESS_code:
    ; Load the operand n1 from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Compare HL (n1) and DE (n2) by subtracting DE from HL.
    or a
    sbc hl, de
    
    ; If overflow occurred, jump to overflow handler
    jp pe, less_overflow
    
    ; No overflow: HL < DE if sign flag is set (negative result)
    jp m, less_true
    jr less_false
    
less_overflow:
    ; Overflow occurred: HL < DE if sign flag is clear (positive result)
    jp p, less_true
    
less_false:
    ; n1 >= n2, return false ($0000)
    ld de, $0000
    jr less_done
    
less_true:
    ; n1 < n2, return true ($FFFF)
    ld de, $FFFF
    
less_done:
    ; Adjust DSP (IX) past n1
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; > ( n1 n2 -- flag )
; Compares two signed 16-bit values and returns true (-1) if n1 > n2.
; -----------------------------------------------------------------------------
GREATER_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '>' ($BE)
    db $81, $BE

    ; Link Field: Points to LESS_NFA
    dw LESS_NFA

GREATER_CFA:
    dw GREATER_code

GREATER_code:
    ; We want to check if n1 (on stack) > n2 (in DE).
    ; This is equivalent to checking if n2 < n1.
    ; So we put n2 (DE) into HL, and load n1 (from stack) into DE.
    
    ; HL = n2 (TOS)
    ld h, d
    ld l, e
    
    ; DE = n1 (stack)
    ld a, (ix+0)
    ld e, a
    ld a, (ix+1)
    ld d, a
    
    ; Compare HL (n2) and DE (n1) by subtracting DE from HL.
    or a
    sbc hl, de
    
    ; If overflow occurred, jump to overflow handler
    jp pe, greater_overflow
    
    ; No overflow: HL < DE (n2 < n1) if sign flag is set (negative result)
    jp m, greater_true
    jr greater_false
    
greater_overflow:
    ; Overflow occurred: HL < DE (n2 < n1) if sign flag is clear (positive result)
    jp p, greater_true
    
greater_false:
    ; n1 <= n2, return false ($0000)
    ld de, $0000
    jr greater_done
    
greater_true:
    ; n1 > n2, return true ($FFFF)
    ld de, $FFFF
    
greater_done:
    ; Adjust DSP (IX) past n1
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; * ( n1 n2 -- prod )
; Multiplies the top two 16-bit values on the stack and returns the 16-bit product.
; -----------------------------------------------------------------------------
STAR_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '*' ($AA)
    db $81, $AA

    ; Link Field: Points to GREATER_NFA
    dw GREATER_NFA

STAR_CFA:
    dw STAR_code

STAR_code:
    ; HL = n2 (TOS, which is in DE)
    ld h, d
    ld l, e
    
    ; DE = n1 (from stack)
    ld a, (ix+0)
    ld e, a
    ld a, (ix+1)
    ld d, a
    
    ; IY = 0 (result accumulator)
    ld iy, 0
    
    ; A = 16 (loop counter)
    ld a, 16
    
star_loop:
    ; Shift HL to the right, bit 0 goes to Carry
    srl h
    rr l
    
    jr nc, star_no_add
    
    ; Add multiplicand (DE) to result (IY)
    add iy, de
    
star_no_add:
    ; Shift multiplicand (DE) to the left for the next iteration
    sla e
    rl d
    
    dec a
    jr nz, star_loop
    
    ; Copy 16-bit result from IY to DE (TOS)
    push iy
    pop de
    
    ; Adjust DSP (IX) past n1
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; /MOD ( n1 n2 -- rem quot )
; Divides n1 by n2, leaving the remainder rem and the quotient quot.
; Symmetric (truncated) signed division.
; -----------------------------------------------------------------------------
SLASH_MOD_NFA:
    ; Name Field: Length 4, bit 7 set in length ($84), first ('/') and last ('D') characters
    db $84, $AF, $4D, $4F, $C4

    ; Link Field: Points to STAR_NFA
    dw STAR_NFA

SLASH_MOD_CFA:
    dw SLASH_MOD_code

SLASH_MOD_code:
    ; Load n1 (dividend) from data stack memory (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; TOS DE is n2 (divisor)
    
    ; Initialize sign flags variable
    xor a
    ld (div_flags), a
    
    ; Test n1 sign
    bit 7, h
    jr z, slash_mod_n1_pos
    
    ; n1 is negative
    ; Set bit 0 (quotient sign) and bit 1 (remainder sign) to 1 (value 3)
    ld a, 3
    ld (div_flags), a
    
    ; Negate HL to get |n1|
    ld a, l
    cpl
    ld l, a
    ld a, h
    cpl
    ld h, a
    inc hl
    
slash_mod_n1_pos:
    ; Test n2 sign
    bit 7, d
    jr z, slash_mod_n2_pos
    
    ; n2 is negative
    ; XOR bit 0 of div_flags
    ld a, (div_flags)
    xor 1
    ld (div_flags), a
    
    ; Negate DE to get |n2|
    ld a, e
    cpl
    ld e, a
    ld a, d
    cpl
    ld d, a
    inc de
    
slash_mod_n2_pos:
    ; Save Instruction Pointer (BC) on return stack (native stack SP)
    push bc
    
    ; Run unsigned 16-bit division: HL / DE -> HL = quotient, BC = remainder
    ld bc, 0
    ld a, 16
    
slash_mod_div_loop:
    ; Save loop counter A on native stack
    push af
    
    add hl, hl
    rl c
    rl b
    
    ; Try BC - DE
    push bc
    ld a, c
    sub e
    ld c, a
    ld a, b
    sbc a, d
    ld b, a
    
    jr c, slash_mod_div_restore
    
    ; Subtraction successful
    pop af ; Clean up saved BC
    inc l
    jr slash_mod_div_next
    
slash_mod_div_restore:
    pop bc
    
slash_mod_div_next:
    ; Restore loop counter A from native stack
    pop af
    dec a
    jr nz, slash_mod_div_loop
    
    ; Now quotient is in HL, remainder is in BC.
    ; Apply signs.
    
    ; Get flags in A and save AF to stack
    ld a, (div_flags)
    push af
    
    ; 1. Remainder sign (bit 1 of div_flags)
    bit 1, a
    jr z, slash_mod_rem_sign_done
    
    ; Negate remainder BC
    ld a, c
    cpl
    ld c, a
    ld a, b
    cpl
    ld b, a
    inc bc
    
slash_mod_rem_sign_done:
    ; Store remainder (BC) back to data stack memory (IX)
    ld a, c
    ld (ix+0), a
    ld a, b
    ld (ix+1), a
    
    ; 2. Quotient sign (bit 0 of div_flags)
    pop af ; Restore div_flags into A
    bit 0, a
    jr z, slash_mod_quot_sign_done
    
    ; Negate quotient HL
    ld a, l
    cpl
    ld l, a
    ld a, h
    cpl
    ld h, a
    inc hl
    
slash_mod_quot_sign_done:
    ; Restore Instruction Pointer (BC) from return stack
    pop bc
    
    ; Set TOS (DE) to quotient (HL)
    ld d, h
    ld e, l
    
    jp NEXT

div_flags:
    db 0

