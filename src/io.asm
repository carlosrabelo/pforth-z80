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

; -----------------------------------------------------------------------------
; EMIT ( char -- )
; -----------------------------------------------------------------------------
; Writes a character from the top of the data stack (TOS) to port 1.
; -----------------------------------------------------------------------------
EMIT_NFA:
    ; Name Field: Length 4, bit 7 set in first and last characters
    db $84, 'E', 'M', 'I', $D4

    ; Link Field: Points to the previous word's NFA (KEY_NFA)
EMIT_LFA:
    dw KEY_NFA

    ; Code Field: Points to the code execution entry
EMIT_CFA:
    dw EMIT_code

EMIT_code:
    ld a, e
    call EMIT_char

    ; Pop the next value from the data stack (IX) into TOS (DE)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix

    jp NEXT


; -----------------------------------------------------------------------------
; WORD ( char -- addr )
; -----------------------------------------------------------------------------
; Parses the next token from the terminal input buffer (TIB) delimited by char.
; Copies the string to HERE (pointed to by DP), prepended with a count byte
; and followed by a trailing space. Returns the address of the counted string.
; -----------------------------------------------------------------------------
WORD_NFA:
    ; Name Field: Length 4, bit 7 set in first and last characters
    db $84, 'W', 'O', 'R', $C4

    ; Link Field: Points to BYE_NFA
WORD_LFA:
    dw EMIT_NFA

    ; Code Field: Points to the code execution entry
WORD_CFA:
    dw WORD_code

WORD_code:
    push bc                     ; Save Forth IP (BC)
    ; Read the delimiter from TOS (DE, lower byte E) into B
    ld a, e
    ld b, a

    ; Pop the next value from the data stack (IX) into TOS (DE) to restore stack
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix

    ; Push the restored TOS back to stack to prepare for returning the new value
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    call WORD_internal
    pop bc                      ; Restore Forth IP (BC)
    jp NEXT

WORD_internal:
    ; Get read source address: HL = TIB + IN
    ld hl, (USER_AREA_START + U_IN)
    ex de, hl
    ld hl, (USER_AREA_START + U_TIB)
    add hl, de                  ; HL = TIB + IN (initial read pointer)
    push hl                     ; Save initial read pointer to calculate offset later

    ; Get write destination address: DE = HERE (stored in DP)
    push hl                     ; Save current TIB read pointer (HL) temporarily
    ld hl, (USER_AREA_START + U_DP)
    ex de, hl                   ; DE = HERE
    pop hl                      ; Restore current TIB read pointer (HL)
    push de                     ; Save original HERE address to return as TOS
    inc de                      ; DE points to HERE + 1 (room for size byte)

    ld c, 0                     ; C = character count

    ; Step 1: Skip leading delimiters
WORD_skip:
    ld a, (hl)
    ; Check for end of line ($0D, $0A, or $00)
    cp $0d
    jr z, WORD_done
    cp $0a
    jr z, WORD_done
    cp 0
    jr z, WORD_done

    ; Compare with delimiter
    cp b
    jr nz, WORD_copy_start      ; If not delimiter, start copying

    ; It is a delimiter, skip it
    inc hl
    jr WORD_skip

    ; Step 2: Copy characters until next delimiter or end of line
WORD_copy_loop:
    ld a, (hl)
    cp $0d
    jr z, WORD_done
    cp $0a
    jr z, WORD_done
    cp 0
    jr z, WORD_done
    cp b
    jr z, WORD_delim_found      ; If delimiter, we are done

WORD_copy_start:
    ld (de), a                  ; Copy character to destination
    inc de
    inc c                       ; Increment count
    inc hl
    jr WORD_copy_loop

WORD_delim_found:
    inc hl                      ; Skip the delimiter itself so IN points past it

WORD_done:
    ; Append trailing space (pFORTH specification)
    ld a, ' '
    ld (de), a

    ; Pop original HERE address into DE
    pop de                      ; DE = HERE
    ld a, c
    ld (de), a                  ; Store character count at HERE

    ; Update IN offset: U_IN = U_IN + (HL_current - HL_initial)
    pop bc                      ; BC = HL_initial
    push hl                     ; Save current HL
    or a                        ; Clear carry
    sbc hl, bc                  ; HL = HL_current - HL_initial (bytes read)
    ld b, h
    ld c, l                     ; BC = bytes read
    
    ld hl, (USER_AREA_START + U_IN)
    add hl, bc
    ld (USER_AREA_START + U_IN), hl ; Update U_IN offset in user area
    pop hl                      ; Restore current HL
    ret


; -----------------------------------------------------------------------------
; NUMBER ( addr -- d flag )
; -----------------------------------------------------------------------------
; Converts a counted string at addr to a 32-bit double number d.
; flag is the count of unconverted characters (0 indicates success).
; Uses the base value stored in variable BASE (10 or 16).
; -----------------------------------------------------------------------------
NUMBER_NFA:
    ; Name Field: Length 6, bit 7 set in first and last characters
    db $86, 'N', 'U', 'M', 'B', 'E', $D2

    ; Link Field: Points to previous word's NFA (WORD_NFA)
NUMBER_LFA:
    dw WORD_NFA

    ; Code Field: Points to the code execution entry
NUMBER_CFA:
    dw NUMBER_code

NUMBER_code:
    ; Save string address from TOS (DE) into IY
    push de
    pop iy                      ; IY = string address (counted string)

    ; Pop next value from data stack (IX) to restore stack
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix

    ; Push the restored TOS back to data stack
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    call NUMBER_internal

    ; 2. Push low word (HL) to Forth data stack (IX)
    dec ix
    ld (ix+0), h
    dec ix
    ld (ix+0), l

    ; 3. Push high word (BC) to Forth data stack (IX)
    dec ix
    ld (ix+0), b
    dec ix
    ld (ix+0), c

    ; 4. Place status flag (A) into TOS (DE)
    ld d, 0
    ld e, a

    jp NEXT

NUMBER_internal:
    ; Read string length from first byte
    ld c, (iy+0)                ; C = string length
    inc iy                      ; IY points to first character

    ; Step 1: Check for sign
    ld a, c
    or a
    jr z, NUM_no_sign           ; Empty string

    ld a, (iy+0)
    cp '-'
    jr nz, NUM_no_sign          ; Not negative

    ; Negative number: skip '-' and decrement length
    inc iy
    dec c
    ld a, 1                     ; Flag = 1 (negative)
    push af
    jr NUM_init_acc

NUM_no_sign:
    ld a, 0                     ; Flag = 0 (positive)
    push af

NUM_init_acc:
    ; Save string length C to A before exx
    ld a, c
    ; Switch to alternative register set to preserve main registers (BC=IP, DE=TOS)
    exx
    ; Restore string length to C' from A
    ld c, a
    ; Alternative set: BC', DE', HL'
    
    ; Initialize 32-bit accumulator (DE':HL') to 0
    ld hl, 0                    ; HL' = lower 16-bits
    ld de, 0                    ; DE' = upper 16-bits

    ; Read BASE value from user area
    push hl                     ; Save 0 accumulator
    ld hl, USER_AREA_START + U_BASE
    ld a, (hl)                  ; Read base value (usually 10 or 16)
    ld b, a                     ; B' = BASE
    pop hl                      ; Restore 0 accumulator

NUM_loop:
    ld a, c                     ; C' is character count
    or a
    jr z, NUM_conv_done         ; Done converting all characters

    ; Read next character
    ld a, (iy+0)
    inc iy
    dec c                       ; Decrement count

    ; Convert ASCII to digit
    cp '0'
    jr c, NUM_invalid
    cp '9' + 1
    jr c, NUM_digit_0_9

    cp 'A'
    jr c, NUM_invalid
    cp 'F' + 1
    jr c, NUM_digit_A_F

    cp 'a'
    jr c, NUM_invalid
    cp 'f' + 1
    jr c, NUM_digit_a_f

NUM_invalid:
    ; Invalid character: restore count (we decremented it prematurely)
    inc c
    jr NUM_conv_done

NUM_digit_0_9:
    sub '0'
    jr NUM_check_base

NUM_digit_A_F:
    sub 'A'
    add a, 10
    jr NUM_check_base

NUM_digit_a_f:
    sub 'a'
    add a, 10

NUM_check_base:
    ; Verify digit < BASE (B')
    cp b
    jr nc, NUM_invalid          ; If digit >= BASE, invalid

    ; Multiply accumulator (DE':HL') by BASE (B')
    push af                     ; Save digit value
    ld a, b                     ; A = BASE
    cp 16
    jr z, NUM_mult_16

NUM_mult_10:
    ; DE:HL = DE:HL * 10
    ; 1. Save BC (BASE/length variables)
    push bc

    ; 2. DE:HL = X * 2
    add hl, hl
    rl e
    rl d

    ; 3. Save (X*2)_low to BC and (X*2)_high to stack
    ld b, h
    ld c, l
    push de

    ; 4. DE:HL = (X*2) * 4 = X * 8
    add hl, hl
    rl e
    rl d
    add hl, hl
    rl e
    rl d

    ; 5. HL = (X*8)_low + (X*2)_low (BC)
    add hl, bc

    ; 6. BC = (X*2)_high (pop from stack)
    pop bc

    ; 7. DE = (X*8)_high + (X*2)_high (BC) with carry
    ld a, e
    adc a, c
    ld e, a
    ld a, d
    adc a, b
    ld d, a

    ; 8. Restore BC (BASE/length)
    pop bc
    jr NUM_mult_done

NUM_mult_16:
    ; DE:HL = DE:HL * 16 (4 shifts)
    push bc                     ; Save loop control registers
    ld bc, 4                    ; Loop 4 times
NUM_shift_16:
    add hl, hl
    rl e
    rl d
    dec c
    jr nz, NUM_shift_16
    pop bc                      ; Restore loop control registers

NUM_mult_done:
    pop af                      ; Restore digit value (in A)

    ; Add digit to accumulator: DE':HL' = DE':HL' + A
    push bc                     ; Save loop control registers
    ld c, a
    ld b, 0                     ; BC = digit
    add hl, bc                  ; Add to lower 16-bits
    jr nc, NUM_add_done
    inc de                      ; Propagate carry to upper 16-bits
NUM_add_done:
    pop bc                      ; Restore loop control registers
    jr NUM_loop

NUM_conv_done:
    ; Save low_word (HL'), high_word (DE') and BC' (containing status flag in C') before exx
    push hl
    push de
    push bc

    exx                         ; Restore main registers (BC=IP, DE=TOS)

    ; Stack has: [ BC' (status), high_word, low_word, sinal, ret_addr ]
    pop de                      ; DE = BC' (status)
    pop bc                      ; BC = high_word
    pop hl                      ; HL = low_word

    ; Stack has: [ sinal, ret_addr ]
    pop af                      ; A = sinal (0 or 1)

    ; Check if negative
    or a
    jr z, NUM_sign_done         ; If positive, skip negation

    ; Negate 32-bit value in BC:HL
    ld a, l
    cpl
    ld l, a
    ld a, h
    cpl
    ld h, a
    
    ld a, c
    cpl
    ld c, a
    ld a, b
    cpl
    ld b, a
    
    inc hl
    ld a, h
    or l
    jr nz, NUM_sign_applied
    inc bc                      ; Propagate carry
NUM_sign_applied:

NUM_sign_done:
    ; Restore status flag to A from E (part of the popped BC')
    ld a, e
    ret


; Scaffold: character output helper (moves to control.asm with QUIT)
EMIT_char:
    out (TTY_DATA_PORT), a
    ret
