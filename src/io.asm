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


; Scaffold: character output helper (moves to control.asm with QUIT)
EMIT_char:
    out (TTY_DATA_PORT), a
    ret
