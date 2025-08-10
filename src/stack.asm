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
    dw ALLOT_NFA

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

; -----------------------------------------------------------------------------
; SWAP ( x1 x2 -- x2 x1 )
; Swaps the top two elements of the data stack.
; -----------------------------------------------------------------------------
SWAP_NFA:
    ; Name Field: Length 4, bit 7 set in length ($84), first ('S') and last ('P') characters
    db $84, $D3, 'W', 'A', $D0

    ; Link Field: Points to DROP_NFA
    dw DROP_NFA

SWAP_CFA:
    dw SWAP_code

SWAP_code:
    ; Swap the TOS (DE) with the second element on the stack (at IX)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ld (ix+0), e
    ld (ix+1), d
    
    ld d, h
    ld e, l
    
    jp NEXT

; -----------------------------------------------------------------------------
; OVER ( x1 x2 -- x1 x2 x1 )
; Copies the second element on the stack to the top of the stack.
; -----------------------------------------------------------------------------
OVER_NFA:
    ; Name Field: Length 4, bit 7 set in length ($84), first ('O') and last ('R') characters
    db $84, $CF, 'V', 'E', $D2

    ; Link Field: Points to SWAP_NFA
    dw SWAP_NFA

OVER_CFA:
    dw OVER_code

OVER_code:
    ; Push the current TOS (DE) onto the data stack memory
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    
    ; Load the old second element (now at ix+2) into TOS (DE)
    ld a, (ix+2)
    ld e, a
    ld a, (ix+3)
    ld d, a
    
    jp NEXT

; -----------------------------------------------------------------------------
; ROT ( x1 x2 x3 -- x2 x3 x1 )
; Rotates the top three elements of the stack, moving the third to the top.
; -----------------------------------------------------------------------------
ROT_NFA:
    ; Name Field: Length 3, bit 7 set in length ($83), first ('R') and last ('T') characters
    db $83, $D2, 'O', $D4

    ; Link Field: Points to OVER_NFA
    dw OVER_NFA

ROT_CFA:
    dw ROT_code

ROT_code:
    ; Rotate the top three elements ( x1 x2 x3 -- x2 x3 x1 )
    ; Load x2 from (ix+0) into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    
    ; Store x3 (DE) into (ix+0)
    ld (ix+0), e
    ld (ix+1), d
    
    ; Load x1 from (ix+2) into DE
    ld a, (ix+2)
    ld e, a
    ld a, (ix+3)
    ld d, a
    
    ; Store x2 (HL) into (ix+2)
    ld a, l
    ld (ix+2), a
    ld a, h
    ld (ix+3), a
    
    jp NEXT

; -----------------------------------------------------------------------------
; ?DUP ( x -- [x] x )
; Duplicates the top of the stack if it is non-zero.
; -----------------------------------------------------------------------------
QDUP_NFA:
    ; Name Field: Length 4, bit 7 set in length ($84), first ('?') and last ('P') characters
    db $84, $BF, 'D', 'U', $D0

    ; Link Field: Points to ROT_NFA
    dw ROT_NFA

QDUP_CFA:
    dw QDUP_code

QDUP_code:
    ; Check if TOS (DE) is zero
    ld a, d
    or e
    jr z, qdup_skip
    
    ; Duplicate TOS onto the data stack memory
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    
qdup_skip:
    jp NEXT

; -----------------------------------------------------------------------------
; >R ( x -- )
; Moves the top of the data stack to the return stack.
; -----------------------------------------------------------------------------
TO_R_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('>') and last ('R') characters
    db $82, $BE, $D2

    ; Link Field: Points to QDUP_NFA
    dw QDUP_NFA

TO_R_CFA:
    dw TO_R_code

TO_R_code:
    ; Push the current TOS (DE) onto the return stack (SP)
    push de
    
    ; Load the new TOS from the data stack (IX) and adjust DSP (IX)
    ld a, (ix+0)
    ld e, a
    ld a, (ix+1)
    ld d, a
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; R> ( -- x )
; Moves the top of the return stack to the data stack.
; -----------------------------------------------------------------------------
FROM_R_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('R') and last ('>') characters
    db $82, $D2, $BE

    ; Link Field: Points to TO_R_NFA
    dw TO_R_NFA

FROM_R_CFA:
    dw FROM_R_code

FROM_R_code:
    ; Push the current TOS (DE) onto the data stack memory
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    
    ; Pop the top of the return stack (SP) into TOS (DE)
    pop de
    
    jp NEXT

; -----------------------------------------------------------------------------
; R@ ( -- x )
; Copies the top of the return stack to the data stack.
; -----------------------------------------------------------------------------
R_FETCH_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('R') and last ('@') characters
    db $82, $D2, $C0

    ; Link Field: Points to FROM_R_NFA
    dw FROM_R_NFA

R_FETCH_CFA:
    dw R_FETCH_code

R_FETCH_code:
    ; Push the current TOS (DE) onto the data stack memory
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    
    ; Copy the top of the return stack (SP) into TOS (DE) without popping it
    pop de
    push de
    
    jp NEXT








