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

; -----------------------------------------------------------------------------
; ! ( x a -- )
; Stores a 16-bit value 'x' at memory address 'a'.
; -----------------------------------------------------------------------------
STORE_NFA:
    ; Name Field: Length 1, bit 7 set in length ($81) and character '!' ($A1)
    db $81, $A1

    ; Link Field: Points to FETCH_NFA
    dw FETCH_NFA

STORE_CFA:
    dw STORE_code

STORE_code:
    ; Read the address from TOS (DE) into HL
    ld h, d
    ld l, e
    
    ; Write the low byte of x (ix+0) to (hl)
    ld a, (ix+0)
    ld (hl), a
    
    inc hl
    
    ; Write the high byte of x (ix+1) to (hl)
    ld a, (ix+1)
    ld (hl), a
    
    ; Load the new TOS (DE) from the stack (at ix+2)
    ld a, (ix+2)
    ld e, a
    ld a, (ix+3)
    ld d, a
    
    ; Remove x and the new TOS from stack memory (4 bytes)
    inc ix
    inc ix
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; C@ ( a -- c )
; Fetches a single byte 'c' from memory address 'a'.
; -----------------------------------------------------------------------------
C_FETCH_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('C') and last ('@') characters
    db $82, $C3, $C0

    ; Link Field: Points to STORE_NFA
    dw STORE_NFA

C_FETCH_CFA:
    dw C_FETCH_code

C_FETCH_code:
    ; Read the address from TOS (DE) into HL
    ld h, d
    ld l, e
    
    ; Load the byte from (HL) into E, and clear D
    ld e, (hl)
    ld d, 0
    
    jp NEXT

; -----------------------------------------------------------------------------
; C! ( c a -- )
; Stores a single byte 'c' at memory address 'a'.
; -----------------------------------------------------------------------------
C_STORE_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('C') and last ('!') characters
    db $82, $C3, $A1

    ; Link Field: Points to C_FETCH_NFA
    dw C_FETCH_NFA

C_STORE_CFA:
    dw C_STORE_code

C_STORE_code:
    ; Read the address from TOS (DE) into HL
    ld h, d
    ld l, e
    
    ; Write the low byte of c (ix+0) to (hl)
    ld a, (ix+0)
    ld (hl), a
    
    ; Load the new TOS (DE) from the stack (at ix+2)
    ld a, (ix+2)
    ld e, a
    ld a, (ix+3)
    ld d, a
    
    ; Remove c and the new TOS from stack memory (4 bytes)
    inc ix
    inc ix
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; +! ( n a -- )
; Adds a 16-bit value 'n' to the 16-bit value at memory address 'a'.
; -----------------------------------------------------------------------------
PLUS_STORE_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('+') and last ('!') characters
    db $82, $AB, $A1

    ; Link Field: Points to C_STORE_NFA
    dw C_STORE_NFA

PLUS_STORE_CFA:
    dw PLUS_STORE_code

PLUS_STORE_code:
    ; Read the address from TOS (DE) into HL
    ld h, d
    ld l, e
    
    ; Load the current value at address 'a' into DE
    ld e, (hl)
    inc hl
    ld d, (hl)
    dec hl
    
    ; Save the address (HL) on the return stack
    push hl
    
    ; Load the operand 'n' from the data stack (IX) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Add the current value (DE) to 'n' (HL)
    add hl, de
    
    ; Move the sum to DE and restore the address in HL
    ld d, h
    ld e, l
    pop hl
    
    ; Store the sum (DE) back at address 'a' (HL)
    ld (hl), e
    inc hl
    ld (hl), d
    
    ; Load the new TOS (DE) from the stack (at ix+2)
    ld a, (ix+2)
    ld e, a
    ld a, (ix+3)
    ld d, a
    
    ; Remove 'n' and the new TOS from stack memory (4 bytes)
    inc ix
    inc ix
    inc ix
    inc ix
    
    jp NEXT




