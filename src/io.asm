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
; CR ( -- )
; Outputs a Carriage Return ($0D) and a Line Feed ($0A) to port 1.
; -----------------------------------------------------------------------------
CR_NFA:
    ; Name Field: Length 2, bit 7 set in first ('C') and last ('R') characters ($82)
    ; 'C' = $43 -> $C3, 'R' = $52 -> $D2
    db $82, $C3, $D2

    ; Link Field: Points to EMIT_NFA
    dw EMIT_NFA

CR_CFA:
    dw CR_code

CR_code:
    ; 1. Emit Carriage Return ($0D)
    ld a, $0D
    call EMIT_char
    
    ; 2. Emit Line Feed ($0A)
    ld a, $0A
    call EMIT_char
    
    jp NEXT

; -----------------------------------------------------------------------------
; SPACE ( -- )
; Outputs a single space character ($20) to port 1.
; -----------------------------------------------------------------------------
SPACE_NFA:
    ; Name Field: Length 5, bit 7 set in first ('S') and last ('E') characters ($85)
    ; 'S' = $53 -> $D3, 'E' = $45 -> $C5
    db $85, $D3, 'P', 'A', 'C', $C5

    ; Link Field: Points to CR_NFA
    dw CR_NFA

SPACE_CFA:
    dw SPACE_code

SPACE_code:
    ; Emit space character ($20)
    ld a, $20
    call EMIT_char
    
    jp NEXT

; -----------------------------------------------------------------------------
; SPACES ( n -- )
; Outputs n space characters to port 1.
; -----------------------------------------------------------------------------
SPACES_NFA:
    ; Name Field: Length 6, bit 7 set in first ('S') and last ('S') characters ($86)
    ; 'S' = $53 -> $D3, 'S' = $53 -> $D3
    db $86, $D3, 'P', 'A', 'C', 'E', $D3

    ; Link Field: Points to SPACE_NFA
    dw SPACE_NFA

SPACES_CFA:
    dw SPACES_code

SPACES_code:
    ; 1. Check if n (DE) is greater than 0
    ld a, d
    and $80
    jr nz, spaces_done   ; If negative (n < 0), exit
    
    ld a, d
    or e
    jr z, spaces_done    ; If zero (n == 0), exit

    ; 2. Copy count to HL
    ld h, d
    ld l, e

spaces_loop:
    ; Emit space character ($20)
    ld a, $20
    call EMIT_char
    
    ; Decrement loop counter HL
    dec hl
    
    ; Test if HL == 0
    ld a, h
    or l
    jr nz, spaces_loop

spaces_done:
    ; 3. Pop the next value from the data stack (IX) into TOS (DE)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; TYPE ( addr u -- )
; Outputs u characters starting at address addr to port 1.
; -----------------------------------------------------------------------------
TYPE_NFA:
    ; Name Field: Length 4, bit 7 set in first ('T') and last ('E') characters ($84)
    ; 'T' = $54 -> $D4, 'E' = $45 -> $C5
    db $84, $D4, 'Y', 'P', $C5

    ; Link Field: Points to SPACES_NFA
    dw SPACES_NFA

TYPE_CFA:
    dw TYPE_code

TYPE_code:
    ; 1. Check if count u (DE) is greater than 0
    ld a, d
    and $80
    jr nz, type_done     ; If negative (u < 0), exit
    
    ld a, d
    or e
    jr z, type_done      ; If zero (u == 0), exit

    ; 2. Load address addr from stack into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a

type_loop:
    ; 3. Emit character at HL
    ld a, (hl)
    call EMIT_char
    
    ; 4. Advance address pointer HL
    inc hl
    
    ; 5. Decrement count DE
    dec de
    
    ; 6. Check if count DE is zero
    ld a, d
    or e
    jr nz, type_loop

type_done:
    ; 7. Pop next value from stack (which is below addr) into TOS (DE)
    ld e, (ix+2)
    ld d, (ix+3)
    
    ; 8. Clean up stack: increment IX by 4 (to discard addr and the new TOS from stack)
    inc ix
    inc ix
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; EXPECT ( addr u -- )
; Reads up to u characters from the terminal and stores them starting at addr.
; Stops when a Carriage Return is typed or when u characters are read.
; Stores the number of characters read in user variable SPAN.
; -----------------------------------------------------------------------------
EXPECT_NFA:
    ; Name Field: Length 6, bit 7 set in first ('E') and last ('T') characters ($86)
    ; 'E' = $45 -> $C5, 'X' = $58, 'P' = $50, 'E' = $45, 'C' = $43, 'T' = $54 -> $D4
    db $86, $C5, 'X', 'P', 'E', 'C', $D4

    ; Link Field: Points to TYPE_NFA
    dw TYPE_NFA

EXPECT_CFA:
    dw EXPECT_code

EXPECT_code:
    ; 1. Check if count u (DE) is greater than 0
    ld a, d
    and $80
    jr nz, expect_zero    ; If negative, behave as zero count (exit)
    
    ld a, d
    or e
    jr z, expect_zero     ; If zero, behave as zero count (exit)

    ; 2. Load address addr from stack into HL
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a

    ; 3. Initialize character counter IY to 0
    ld iy, 0

expect_char_loop:
    ; 4. Read character from port 1
    in a, (TTY_DATA_PORT)

    ; 5. Check character read
    ; If Carriage Return ($0D) or Line Feed ($0A), finish
    cp $0d
    jr z, expect_done_cr
    cp $0a
    jr z, expect_done_cr

    ; If Backspace ($08) or Delete ($7F)
    cp $08
    jr z, expect_backspace
    cp $7f
    jr z, expect_backspace

    ; Normal character: Check if we have room to store it
    push hl
    push iy
    pop hl              ; HL = current count (IY)
    or a
    sbc hl, de          ; Compare count with limit (DE)
    pop hl
    jr z, expect_char_loop ; If we reached the limit, ignore any new characters except CR/Backspace

    ; Store character at HL
    ld (hl), a
    inc hl
    inc iy

    ; Echo character
    call EMIT_char
    jr expect_char_loop

expect_backspace:
    ; Check if we have read any characters (IY > 0)
    push hl
    push iy
    pop hl
    ld a, h
    or l
    pop hl
    jr z, expect_char_loop ; If count is 0, do nothing

    ; Decrement pointers
    dec hl
    dec iy

    ; Visual erase on terminal: Backspace ($08), Space ($20), Backspace ($08)
    ld a, $08
    call EMIT_char
    ld a, ' '
    call EMIT_char
    ld a, $08
    call EMIT_char
    jr expect_char_loop

expect_done_cr:
    ; Echo Carriage Return and Line Feed
    ld a, $0d
    call EMIT_char
    ld a, $0a
    call EMIT_char

    ; Store count in user variable SPAN
    ld (USER_AREA_START + U_SPAN), iy
    jr expect_done

expect_zero:
    ; If count u was 0, SPAN is set to 0
    ld iy, 0
    ld (USER_AREA_START + U_SPAN), iy

expect_done:
    ; Pop next value from stack (below addr) into TOS (DE)
    ld e, (ix+2)
    ld d, (ix+3)
    
    ; Clean up stack: increment IX by 4
    inc ix
    inc ix
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
    dw EXPECT_NFA

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


; -----------------------------------------------------------------------------
; FIND ( addr -- cfa 1 | addr 0 )
; -----------------------------------------------------------------------------
; Searches the dictionary for a word with the name specified by the counted string at addr.
; If found, returns the Word's CFA and 1 (true).
; If not found, returns the original string addr and 0 (false).
; -----------------------------------------------------------------------------
FIND_NFA:
    ; Name Field: Length 4, bit 7 set in first and last characters
    db $84, 'F', 'I', 'N', $C4

    ; Link Field: Points to previous word's NFA (NUMBER_NFA)
FIND_LFA:
    dw NUMBER_NFA

    ; Code Field: Points to the code execution entry
FIND_CFA:
    dw FIND_code

FIND_code:
    ; Save search string address from TOS (DE) to IY
    push de
    pop iy                      ; IY = address of string to find

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

    call FIND_internal

    ; Push cfa/addr (HL) onto Forth data stack (IX)
    dec ix
    ld (ix+0), h
    dec ix
    ld (ix+0), l

    ; Load flag (A) into TOS (DE)
    ld d, 0
    ld e, a
    jp NEXT

FIND_internal:
    ; Start dictionary search at the last word in search vocabulary (U_CONTEXT)
    ld hl, (USER_AREA_START + U_CONTEXT)
    ex de, hl

FIND_search_loop:
    ; Check if DE is 0 (end of dictionary chain)
    ld a, d
    or a
    jr z, FIND_not_found        ; If 0, word not found


    ; Save loop pointers to protect them during comparison
    push de                     ; Save dictionary NFA pointer
    push iy                     ; Save search string pointer

    ; Compare lengths
    ld a, (iy+0)
    ld b, a                     ; B = search string length
    
    ld a, (de)
    and $1f                     ; A = dictionary name length (mask out flags)
    
    cp b
    jr nz, FIND_next            ; If lengths differ, mismatch

    ; Lengths match, compare characters
    ld c, a                     ; C = character count
    inc iy                      ; Point to first character of search string
    inc de                      ; Point to first character of dictionary word

FIND_compare_loop:
    ld a, (iy+0)
    ld h, a                     ; H = character from search string
    
    ld a, (de)
    and $7f                     ; A = character from dictionary word (mask out bit 7)
    
    cp h
    jr nz, FIND_next            ; If characters differ, mismatch

    inc iy
    inc de
    dec c
    jr nz, FIND_compare_loop

    ; --- WORD FOUND ---
    ; Restore original pointers from stack
    pop iy                      ; Clear IY stack
    pop de                      ; DE = NFA of found word

    ; Calculate LFA from NFA in DE: LFA = NFA + 1 + length
    ld a, (de)
    and $1f                     ; A = length
    ld l, a
    ld h, 0
    add hl, DE
    inc hl                      ; HL = LFA address

    ; Calculate CFA from LFA: CFA = LFA + 2
    inc hl
    inc hl                      ; HL = CFA address
    ld a, 1
    ret

FIND_next:
    ; Mismatch: restore original pointers
    pop iy                      ; Restore search string pointer
    pop de                      ; Restore dictionary NFA pointer

    ; Calculate LFA from NFA: LFA = NFA + 1 + length
    ld a, (de)
    and $1f                     ; A = length
    ld l, a
    ld h, 0
    add hl, de
    inc hl                      ; HL = LFA address

    ; Read link from LFA (points to previous word's NFA) into DE
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a                     ; DE = previous word's NFA

    jr FIND_search_loop

FIND_not_found:
    ; --- WORD NOT FOUND ---
    push iy
    pop hl                      ; HL = original string address
    ld a, 0
    ret


; -----------------------------------------------------------------------------
; EXECUTE ( cfa -- )
; -----------------------------------------------------------------------------
; Executes the word whose CFA is on the top of the data stack (TOS).
; -----------------------------------------------------------------------------
EXECUTE_NFA:
    ; Name Field: Length 7, bit 7 set in first and last characters
    db $87, 'E', 'X', 'E', 'C', 'U', 'T', $C5

    ; Link Field: Points to previous word's NFA (FIND_NFA)
EXECUTE_LFA:
    dw FIND_NFA

    ; Code Field: Points to the code execution entry
EXECUTE_CFA:
    dw EXECUTE_code

EXECUTE_code:
    ; Copy the CFA from TOS (DE) into HL (Working register W)
    ld h, d
    ld l, e                     ; HL = CFA (W)

    ; Pop next value from data stack (IX) into TOS (DE) to restore stack
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix                      ; Stack is now restored, previous TOS is back in DE

    ; Dispatch target execution code: read code address from (HL) into IY
    ld a, (hl)
    ld iyl, a                   ; Lower byte of code address
    inc hl                      ; Point to CFA + 1 (High byte of code address)
    ld a, (hl)
    ld iyh, a                   ; Upper byte of code address

    ; Jump to the target code. HL is left pointing to (CFA + 1).
    jp (iy)
