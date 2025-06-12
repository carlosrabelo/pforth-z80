; =============================================================================
; pForth - Z80 Control & Compiler Words
; =============================================================================
; z80asm-compatible syntax.

; -----------------------------------------------------------------------------
; LIT ( -- n )
; -----------------------------------------------------------------------------
; Pushes the 16-bit literal value following this word in the execution token
; stream onto the data stack.
; -----------------------------------------------------------------------------
LIT_NFA:
    ; Name Field: Length 3, bit 7 set in first and last characters
    db $83, 'L', 'I', $D4

    ; Link Field: Points to previous word's NFA (EXECUTE_NFA in io.asm)
    dw EXECUTE_NFA

    ; Code Field: Points to the code execution entry
    dw LIT_CFA
LIT_CFA:
    dw LIT_code

LIT_code:
    ; Push current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    ; Read 16-bit literal from IP (BC) into TOS (DE)
    ld a, (bc)
    ld e, a
    inc bc
    ld a, (bc)
    ld d, a
    inc bc

    jp NEXT

; -----------------------------------------------------------------------------
; STATE ( -- addr )
; -----------------------------------------------------------------------------
; Returns the address of the compilation state variable in the user area.
; 0 = interpreting, non-zero = compiling.
; -----------------------------------------------------------------------------
STATE_NFA:
    ; Name Field: Length 5, bit 7 set in first and last characters
    db $85, 'S', 'T', 'A', 'T', $C5

    ; Link Field: Points to previous word's NFA (LIT_NFA)
    dw LIT_NFA

    ; Code Field: Points to the code execution entry
    dw STATE_CFA
STATE_CFA:
    dw STATE_code

STATE_code:
    ; Push current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    ; Load absolute address of STATE variable in user area into TOS (DE)
    ld de, USER_AREA_START + U_STATE

    jp NEXT

; -----------------------------------------------------------------------------
; INTERPRET ( -- )
; -----------------------------------------------------------------------------
; The main loop of the Forth interpreter. Parses tokens from the input stream
; and either executes them (if interpreting or if immediate) or compiles their
; CFAs into the dictionary (if compiling).
; -----------------------------------------------------------------------------
INTERPRET_NFA:
    ; Name Field: Length 9, bit 7 set in first and last characters
    db $89, 'I', 'N', 'T', 'E', 'R', 'P', 'R', 'E', $D4

    ; Link Field: Points to previous word's NFA (STATE_NFA)
    dw STATE_NFA

    ; Code Field: Points to the code execution entry
    dw INTERPRET_CFA
INTERPRET_CFA:
    dw INTERPRET_code

INTERPRET_code:
    call INTERPRET_internal
    jp NEXT

INTERPRET_internal:
    ; Save the caller's IP (BC)
    ld (SAVED_IP), bc

INTERPRET_loop:
    ; Save TOS (DE) to temporary variable to prevent corruption by WORD/FIND
    push hl
    ld h, d
    ld l, e
    ld (SAVED_TOS), hl
    pop hl

    ; Call WORD_internal with space delimiter ($20)
    ld b, $20
    call WORD_internal          ; Returns DE = address of parsed token string (HERE)

    ; Check if string length is 0 (end of input line)
    ld a, (de)
    or a
    jp z, INTERPRET_done

    ; Save string address to IY for FIND_internal
    push de
    pop iy                      ; IY = token address
    call FIND_internal          ; Returns HL = CFA, DE = NFA, A = 1 if found; HL = original addr, A = 0 if not
    or a
    jp z, INTERPRET_number      ; If not found, try to parse as number

    ; Word found! HL = CFA, DE = NFA
    ; Check STATE variable
    ld a, (USER_AREA_START + U_STATE)
    or a
    jp z, INTERPRET_exec_word   ; If STATE is 0 (interpreting), execute immediately

    ; We are in compilation state. Check if the word is IMMEDIATE.
    ld a, (de)                  ; Read length byte of NFA
    bit 6, a                    ; Bit 6 is the immediate flag
    jp nz, INTERPRET_exec_word   ; If immediate, execute it now

    push hl
    ld hl, (USER_AREA_START + U_DP) ; DE = HERE
    ex de, hl
    pop hl
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a
    inc de
    ld (USER_AREA_START + U_DP), de ; Update DP
    ; Restore TOS (DE) from SAVED_TOS
    push hl
    ld hl, (SAVED_TOS)
    ld d, h
    ld e, l
    pop hl
    jr INTERPRET_loop

INTERPRET_exec_word:
    ; Restore TOS (DE) before executing the word
    push hl
    ld hl, (SAVED_TOS)
    ld d, h
    ld e, l
    pop hl
    ; Save word's CFA to execution buffer
    ld (EXEC_BUF), hl
    ; Point IP (BC) to execution buffer
    ld bc, EXEC_BUF
    jp NEXT                        ; Execute! (Will return to RESUME_code -> INTERPRET_loop)

INTERPRET_number:
    ; HL = original string address. Parse as number.
    push hl
    pop iy                      ; IY = string address
    call NUMBER_internal        ; Returns HL = low, BC = high, A = status flag
    or a
    jp nz, INTERPRET_error      ; If A != 0, conversion failed (unknown word / bad number)

    ; Number parsed successfully. HL = 16-bit value.
    ; Check STATE variable
    ld a, (USER_AREA_START + U_STATE)
    or a
    jp z, INTERPRET_push_number ; If interpreting, push onto stack

    push hl
    ld hl, (USER_AREA_START + U_DP) ; DE = HERE
    ex de, hl
    pop hl
    ld a, LIT_CFA & $FF
    ld (de), a
    inc de
    ld a, LIT_CFA >> 8
    ld (de), a
    inc de
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a
    inc de
    ld (USER_AREA_START + U_DP), de ; Update DP
    ; Restore TOS (DE) from SAVED_TOS
    push hl
    ld hl, (SAVED_TOS)
    ld d, h
    ld e, l
    pop hl
    jp INTERPRET_loop

INTERPRET_push_number:
    ; Restore original TOS (DE) from SAVED_TOS to push it onto stack
    push hl
    ld hl, (SAVED_TOS)
    ld d, h
    ld e, l
    pop hl
    ; Push current TOS (DE) onto data stack
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    ; Load the parsed number into TOS (DE)
    ld d, h
    ld e, l
    jp INTERPRET_loop

INTERPRET_error:
    ; Word not found and not a valid number. Print word name followed by ' ?'
    ld hl, (USER_AREA_START + U_DP) ; HL = parsed token address (HERE)
    ld c, (hl)                      ; C = length
    ld b, 0
    inc hl                          ; HL points to first character
INTERPRET_err_loop:
    ld a, c
    or a
    jr z, INTERPRET_err_done
    ld a, (hl)
    call EMIT_char
    inc hl
    dec c
    jr INTERPRET_err_loop
INTERPRET_err_done:
    ld a, ' '
    call EMIT_char
    ld a, '?'
    call EMIT_char
    ld a, $0d
    call EMIT_char
    ld a, $0a
    call EMIT_char

    ; Restart interpretation loop on error (ABORT behavior)
    jp QUIT_restart

INTERPRET_done:
    ; Restore TOS (DE) before returning
    push hl
    ld hl, (SAVED_TOS)
    ld d, h
    ld e, l
    pop hl
    ; Restore original IP (BC)
    ld bc, (SAVED_IP)
    ret

; -----------------------------------------------------------------------------
; QUIT ( -- )
; -----------------------------------------------------------------------------
; Clears the return stack, sets interpretation state, and starts the main
; interactive console loop reading from TIB.
; -----------------------------------------------------------------------------
QUIT_NFA:
    ; Name Field: Length 4, bit 7 set in first and last characters
    db $84, 'Q', 'U', 'I', $D4

    ; Link Field: Points to previous word's NFA (INTERPRET_NFA)
    dw INTERPRET_NFA

    ; Code Field: Points to the code execution entry
    dw QUIT_CFA
QUIT_CFA:
    dw QUIT_code

QUIT_code:
    ; Reset the Return Stack Pointer (RSP)
    ld sp, RETURN_STACK_BOTTOM

    ld hl, welcome_msg
    call print_string
    jp QUIT_restart

print_string:
    ld a, (hl)
    or a
    ret z
    call EMIT_char
    inc hl
    jr print_string

welcome_msg:
    db "pForth Z80 ready", $0d, $0a, 0

QUIT_restart:
    ; Clear interpretation state (STATE = 0)
    xor a
    ld (USER_AREA_START + U_STATE), a

    ; Clear data stack (DSP = DATA_STACK_BOTTOM, TOS = 0)
    ld ix, DATA_STACK_BOTTOM
    ld de, 0

QUIT_prompt_loop:
    ; Print prompt OK if STATE is 0
    ld a, (USER_AREA_START + U_STATE)
    or a
    jr nz, QUIT_no_prompt
    
    ; Print prompt "OK" followed by newline
    ld a, 'O'
    call EMIT_char
    ld a, 'K'
    call EMIT_char
    ld a, $0d
    call EMIT_char
    ld a, $0a
    call EMIT_char

QUIT_no_prompt:
    ; Read line to TIB using inline line editor
    ld c, 0                     ; C = size of line
    ld b, 0                     ; B = cursor position (offset from TIB start)
    push de                     ; Save Forth TOS cache to native stack during line editing

QUIT_read_loop:
    ; Read character from port 1 (z88dk-ticks -iochar=1)
    in a, (TTY_DATA_PORT)
    
    ld d, a                     ; Save character in D

    ; Check if carriage return ($0D) or line feed ($0A)
    cp $0d
    jp z, QUIT_line_done
    cp $0a
    jp z, QUIT_line_done

    ; Check backspace ($08 or $7F)
    cp $08
    jp z, QUIT_handle_backspace
    cp $7f
    jp z, QUIT_handle_backspace

    ; Check escape sequence ($1B)
    cp $1b
    jp z, QUIT_handle_escape

    ; Check if character is printable (ASCII space to tilde)
    cp ' '
    jp c, QUIT_read_loop        ; Ignore non-printable
    cp $7f
    jp nc, QUIT_read_loop

    ; Store character if there is space in TIB
    ld a, c
    cp TIB_SIZE - 2
    jp nc, QUIT_read_loop       ; Buffer full, ignore

    ; Save TOS original DE and character D on stack
    push de

    ; Insert character: check if cursor B is at the end of line C
    ld a, b
    cp c
    jp z, QUIT_insert_end_from_mid

    ; Cursor is in the middle: shift characters to the right
    push hl
    push bc
    ld hl, (USER_AREA_START + U_TIB)
    ld e, c
    ld d, 0
    add hl, de                  ; DE = TIB + C (destination)
    push hl
    pop de
    dec hl                      ; HL = TIB + C - 1 (source)
    
    ld a, c
    sub b
    ld c, a
    ld b, 0                     ; BC = count
    lddr                        ; Shift right
    pop bc
    pop hl

    ; Store character at cursor B
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    ld d, 0
    add hl, de                  ; HL = TIB + B
    
    ; Restore character D (and TOS DE) temporarily to write it
    pop de
    ld (hl), d                  ; Store
    push de                     ; Push back to restore at the end of redraw

    inc b
    inc c

    ; Redraw screen from cursor B-1 to the end
    push hl
    push bc
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    dec e
    ld d, 0
    add hl, de                  ; HL = TIB + B - 1
    
    ld a, c
    sub b
    inc a
    ld c, a                     ; C = remaining chars to print
QUIT_redraw_loop_insert:
    ld a, (hl)
    call EMIT_char
    inc hl
    dec c
    jr nz, QUIT_redraw_loop_insert
    
    ; Restore cursor physical position: move back by (C - B) positions
    pop bc
    push bc
    ld a, c
    sub b
    jp z, QUIT_redraw_insert_done
    ld c, a
QUIT_restore_cursor_insert:
    ld a, $08
    call EMIT_char
    dec c
    jr nz, QUIT_restore_cursor_insert
QUIT_redraw_insert_done:
    pop bc
    pop hl
    pop de                      ; Restore TOS original DE
    jp QUIT_read_loop

QUIT_insert_end_from_mid:
    ; Store character in TIB
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    ld d, 0
    add hl, de
    
    pop de                      ; Restore character D and TOS DE
    ld (hl), d
    
    inc b
    inc c

    ; Echo character
    ld a, d
    call EMIT_char
    jp QUIT_read_loop

QUIT_handle_backspace:
    ; Check if cursor B > 0
    ld a, b
    or a
    jp z, QUIT_read_loop        ; Nothing to erase

    dec b
    dec c

    ; Check if cursor was at the end of line
    ld a, b
    cp c
    jp z, QUIT_backspace_end

    ; Cursor was in the middle: shift characters to the left
    push de                     ; Save TOS original DE
    push hl
    push bc
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    ld d, 0
    add hl, de                  ; DE = TIB + B (destination)
    push hl
    pop de
    inc hl                      ; HL = TIB + B + 1 (source)
    
    ld a, c
    sub b
    ld c, a
    ld b, 0                     ; BC = count
    ldir                        ; Shift left
    pop bc
    pop hl

    ; Echo backspace visual and redraw remaining chars
    ld a, $08
    call EMIT_char

    push hl
    push bc
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    ld d, 0
    add hl, de                  ; HL = TIB + B
    
    ld a, c
    sub b
    ld c, a                     ; C = remaining chars
QUIT_redraw_loop_bs:
    ld a, (hl)
    call EMIT_char
    inc hl
    dec c
    jr nz, QUIT_redraw_loop_bs

    ; Print space to clear trailing char
    ld a, ' '
    call EMIT_char

    ; Restore cursor position: move back by (C - B + 1)
    pop bc
    push bc
    ld a, c
    sub b
    inc a
    ld c, a
QUIT_restore_cursor_bs:
    ld a, $08
    call EMIT_char
    dec c
    jr nz, QUIT_restore_cursor_bs
    pop bc
    pop hl
    pop de                      ; Restore TOS original DE
    jp QUIT_read_loop

QUIT_backspace_end:
    ; Echo backspace visual (BS, space, BS)
    ld a, $08
    call EMIT_char
    ld a, ' '
    call EMIT_char
    ld a, $08
    call EMIT_char
    jp QUIT_read_loop

QUIT_handle_delete:
    ; Check if cursor B < size C
    ld a, b
    cp c
    jp nc, QUIT_read_loop        ; Nothing to delete

    push de                     ; Save TOS original DE
    dec c

    ; Shift characters to the left
    push hl
    push bc
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    ld d, 0
    add hl, de                  ; DE = TIB + B (destination)
    push hl
    pop de
    inc hl                      ; HL = TIB + B + 1 (source)
    
    ld a, c
    sub b
    ld c, a
    ld b, 0                     ; BC = count
    ldir                        ; Shift left
    pop bc
    pop hl

    ; Redraw remaining chars
    push hl
    push bc
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    ld d, 0
    add hl, de                  ; HL = TIB + B
    
    ld a, c
    sub b
    jr z, QUIT_del_last_char    ; If count became B, it was the last char
    ld c, a                     ; C = remaining chars
QUIT_redraw_loop_del:
    ld a, (hl)
    call EMIT_char
    inc hl
    dec c
    jr nz, QUIT_redraw_loop_del

QUIT_del_last_char:
    ; Print space to clear trailing char
    ld a, ' '
    call EMIT_char

    ; Restore cursor position: move back by (C - B + 1)
    pop bc
    push bc
    ld a, c
    sub b
    inc a
    ld c, a
QUIT_restore_cursor_del:
    ld a, $08
    call EMIT_char
    dec c
    jr nz, QUIT_restore_cursor_del
    pop bc
    pop hl
    pop de                      ; Restore TOS original DE
    jp QUIT_read_loop

QUIT_handle_escape:
    ; Wait for '['
    in a, (TTY_DATA_PORT)
    
    cp '['
    jp nz, QUIT_read_loop       ; Not escape sequence we handle

    ; Wait for third char ('A', 'B', 'C', 'D' or '3')
    in a, (TTY_DATA_PORT)

    cp 'D'                      ; Left arrow
    jp z, QUIT_esc_left
    cp 'C'                      ; Right arrow
    jp z, QUIT_esc_right
    cp '3'                      ; DEL (may send ESC [ 3 ~)
    jp z, QUIT_esc_del
    jp QUIT_read_loop

QUIT_esc_left:
    ld a, b
    or a
    jp z, QUIT_read_loop        ; Already at the beginning
    
    dec b
    ld a, $08
    call EMIT_char
    jp QUIT_read_loop

QUIT_esc_right:
    ld a, b
    cp c
    jp nc, QUIT_read_loop       ; Already at the end

    push de                     ; Save TOS original DE
    ; Read character from buffer at B and print it to move cursor right
    push hl
    push bc
    ld hl, (USER_AREA_START + U_TIB)
    ld e, b
    ld d, 0
    add hl, de
    ld a, (hl)
    call EMIT_char
    pop bc
    pop hl
    pop de                      ; Restore TOS original DE
    inc b
    jp QUIT_read_loop

QUIT_esc_del:
    ; Wait for '~'
    in a, (TTY_DATA_PORT)
    
    jp QUIT_handle_delete

QUIT_line_done:
    ; Terminate line with Carriage Return ($0D) in TIB
    ld hl, (USER_AREA_START + U_TIB)
    ld e, c
    ld d, 0
    add hl, de
    ld (hl), $0d

    ; Echo newline
    ld a, $0d
    call EMIT_char
    ld a, $0a
    call EMIT_char

    ; Reset input offset (U_IN = 0)
    ld hl, 0
    ld (USER_AREA_START + U_IN), hl

    pop de                      ; Restore Forth TOS cache before running interpreter

    ; Call interpreter
    call INTERPRET_internal

    ; Back to loop
    jp QUIT_prompt_loop

; Helper to write a character to port 1 (z88dk-ticks -iochar=1)
EMIT_char:
    out (TTY_DATA_PORT), a
    ret

; -----------------------------------------------------------------------------
; Static buffers for INTERPRET execution dispatch
; -----------------------------------------------------------------------------
SAVED_IP:    dw 0
SAVED_TOS:   dw 0
EXEC_BUF:    dw 0
EXEC_RESUME: dw RESUME_CFA

RESUME_CFA:  dw RESUME_code

RESUME_code:
    jp INTERPRET_loop

; -----------------------------------------------------------------------------
; [ ( -- )
; Sets interpretation state (STATE = 0). This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
LBRACKET_NFA:
    ; Name Field: Length 1, immediate flag set, bit 7 set in first and last characters
    db $C1, $DB

    ; Link Field: Points to previous word's NFA (QUIT_NFA)
    dw QUIT_NFA

    ; Code Field: Points to the code execution entry
LBRACKET_CFA:
    dw LBRACKET_code

LBRACKET_code:
    xor a
    ld (USER_AREA_START + U_STATE), a
    jp NEXT

; -----------------------------------------------------------------------------
; ] ( -- )
; Sets compilation state (STATE = 1).
; -----------------------------------------------------------------------------
RBRACKET_NFA:
    ; Name Field: Length 1, bit 7 set in first and last characters
    db $81, $DD

    ; Link Field: Points to previous word's NFA (LBRACKET_NFA)
    dw LBRACKET_NFA

    ; Code Field: Points to the code execution entry
RBRACKET_CFA:
    dw RBRACKET_code

RBRACKET_code:
    ld a, 1
    ld (USER_AREA_START + U_STATE), a
    jp NEXT

; -----------------------------------------------------------------------------
; CREATE ( -- )
; Parses the next word name from the input stream and creates a new dictionary
; entry for it. When the created word is later executed, it will push the
; address of its parameter field (PFA) onto the data stack.
; -----------------------------------------------------------------------------
CREATE_NFA:
    ; Name Field: Length 6, bit 7 set in first and last characters
    db $86, 'C', 'R', 'E', 'A', 'T', $C5

    ; Link Field: Points to previous word's NFA (RBRACKET_NFA)
    dw RBRACKET_NFA

    ; Code Field: Points to the code execution entry
    dw CREATE_CFA
CREATE_CFA:
    dw CREATE_code

CREATE_code:
    push bc                     ; Save Forth IP (BC)
    call HEADER_internal
    
    ; Write CFA (pointing to CREATE_execution)
    ld a, CREATE_execution & $FF
    ld (hl), a
    inc hl
    ld a, (CREATE_execution >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL now points to PFA (DP + L + 5)
    
    ; Update U_DP to point to PFA (HL)
    ld (USER_AREA_START + U_DP), hl
    
    ; Update U_CURRENT and U_CONTEXT with the NEW_WORD_ADDR (saved on stack)
    pop hl                      ; HL = NEW_WORD_ADDR
    ld (USER_AREA_START + U_CURRENT), hl
    ld (USER_AREA_START + U_CONTEXT), hl
    
    pop bc                      ; Restore Forth IP (BC)
    jp NEXT

; Internal helper to build a new word header in the dictionary
; Returns HL pointing to CFA, and pushes NEW_WORD_ADDR onto the stack.
HEADER_internal:
    ; 1. Parse word name from TIB using space delimiter (ASCII 32)
    ld b, 32                    ; space delimiter
    call WORD_internal          ; WORD_internal parses name into DP (HERE)
    
    ; DP now contains the counted string. Let's load NEW_WORD_ADDR (DP) to HL
    ld hl, (USER_AREA_START + U_DP)
    ex (sp), hl                 ; Swap return address with HL (HL = return address, stack has NEW_WORD_ADDR)
    push hl                     ; Re-push return address (stack now has [NEW_WORD_ADDR, return address])
    
    ; Load original DP back to HL to work on it
    ld hl, (USER_AREA_START + U_DP)
    
    ; Read length L from (HL)
    ld a, (hl)
    ld b, a                     ; B = length L
    
    ; Set bit 7 of the length byte to build NFA
    or $80
    ld (hl), a
    
    ; Calculate address of the last character: HL = DP + L
    ld c, b
    ld b, 0                     ; BC = length L
    add hl, bc                  ; HL points to the last character of the name
    
    ; Set bit 7 of the last character
    ld a, (hl)
    or $80
    ld (hl), a
    inc hl                      ; HL now points to LFA (DP + L + 1)
    
    ; 2. Write LFA (pointing to previous word's NFA from U_CURRENT)
    ld a, (USER_AREA_START + U_CURRENT)
    ld (hl), a
    inc hl
    ld a, (USER_AREA_START + U_CURRENT + 1)
    ld (hl), a
    inc hl                      ; HL now points to CFA (DP + L + 3)
    ret

; Default execution behavior for words defined by CREATE
CREATE_execution:
    ; Push current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    
    ; HL points to CFA + 1. Increment HL to point to PFA (CFA + 2)
    inc hl
    
    ; Load PFA (HL) into TOS (DE)
    ld d, h
    ld e, l
    jp NEXT

; -----------------------------------------------------------------------------
; , (comma) ( x -- )
; Allocates two bytes in the dictionary and stores x there, advancing U_DP.
; -----------------------------------------------------------------------------
COMMA_NFA:
    ; Name Field: Length 1, bit 7 set in first and last character (which is the same)
    ; Length 1 with bit 7 set = $81
    ; Character ',' (ASCII $2C) with bit 7 set = $AC
    db $81, $AC

    ; Link Field: Points to previous word's NFA (CREATE_NFA)
    dw CREATE_NFA

COMMA_CFA:
    dw COMMA_code

COMMA_code:
    ; 1. Load U_DP (Dictionary Pointer) into HL
    ld hl, (USER_AREA_START + U_DP)

    ; 2. Write the 16-bit value in TOS (DE) to memory at (HL)
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl                      ; HL now points to DP + 2

    ; 3. Update U_DP with the new address
    ld (USER_AREA_START + U_DP), hl

    ; 4. Pop the next value from the data stack (IX) into TOS (DE)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix

    jp NEXT

; -----------------------------------------------------------------------------
; IMMEDIATE ( -- )
; Marks the most recently defined word as immediate (executed during compile time).
; -----------------------------------------------------------------------------
IMMEDIATE_NFA:
    ; Name Field: Length 9, bit 7 set in first ('I') and last ('E') characters
    ; Length 9 with bit 7 set = $89
    ; First char 'I' ($49) with bit 7 set = $C9
    ; Last char 'E' ($45) with bit 7 set = $C5
    db $89, $C9, 'M', 'M', 'E', 'D', 'I', 'A', 'T', $C5

    ; Link Field: Points to previous word's NFA (COMMA_NFA)
    dw COMMA_NFA

IMMEDIATE_CFA:
    dw IMMEDIATE_code

IMMEDIATE_code:
    ; 1. Load U_CURRENT NFA address into HL
    ld hl, (USER_AREA_START + U_CURRENT)

    ; 2. Set bit 6 in the length byte at (HL)
    ld a, (hl)
    or $40
    ld (hl), a

    jp NEXT

; -----------------------------------------------------------------------------
; : (colon) ( -- )
; Starts compilation of a new colon definition.
; -----------------------------------------------------------------------------
COLON_NFA:
    ; Name Field: Length 1, bit 7 set in first and last character
    ; Length 1 with bit 7 set = $81
    ; Character ':' (ASCII $3A) with bit 7 set = $BA
    db $81, $BA

    ; Link Field: Points to previous word's NFA (IMMEDIATE_NFA)
    dw IMMEDIATE_NFA

COLON_CFA:
    dw COLON_code

COLON_code:
    push bc                     ; Save Forth IP (BC)
    call HEADER_internal
    
    ; Write CFA (pointing to DOCOL)
    ld a, DOCOL & $FF
    ld (hl), a
    inc hl
    ld a, (DOCOL >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to PFA
    
    ; Update U_DP to point to PFA (HL)
    ld (USER_AREA_START + U_DP), hl
    
    ; Update U_CURRENT and U_CONTEXT with the NEW_WORD_ADDR (saved on stack)
    pop hl                      ; HL = NEW_WORD_ADDR
    ld (USER_AREA_START + U_CURRENT), hl
    ld (USER_AREA_START + U_CONTEXT), hl
    
    ; Enter compilation mode: STATE = 1
    ld a, 1
    ld (USER_AREA_START + U_STATE), a
    
    pop bc                      ; Restore Forth IP (BC)
    jp NEXT

; -----------------------------------------------------------------------------
; ; (semicolon) ( -- )
; Ends compilation of a colon definition. Compiles SEMI_CFA and exits compiling mode.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
SEMICOLON_NFA:
    ; Name Field: Length 1, bit 7 set (and bit 6 set for IMMEDIATE) = $C1
    ; Character ';' (ASCII $3B) with bit 7 set = $3B | $80 = $BB
    db $C1, $BB

    ; Link Field: Points to previous word's NFA (COLON_NFA)
    dw COLON_NFA

SEMICOLON_CFA:
    dw SEMICOLON_code

SEMICOLON_code:
    ; 1. Compile the CFA of SEMI into the dictionary (pointed by U_DP)
    ld hl, (USER_AREA_START + U_DP)
    ld a, SEMI_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (SEMI_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to DP + 2
    ld (USER_AREA_START + U_DP), hl

    ; 2. Exit compilation mode: STATE = 0
    xor a
    ld (USER_AREA_START + U_STATE), a

    jp NEXT

; Global Semicolon CFA pointing to the SEMI execution code
SEMI_CFA:
    dw SEMI

; -----------------------------------------------------------------------------
; HERE ( -- addr )
; Leaves the address of the next free location in the dictionary on the stack.
; -----------------------------------------------------------------------------
HERE_NFA:
    ; Name Field: Length 4, bit 7 set in length ($84), first ('H') and last ('E') characters
    ; H = $48 -> $C8, E = $45 -> $C5
    db $84, $C8, 'E', 'R', $C5

    ; Link Field: Points to SEMICOLON_NFA
    dw SEMICOLON_NFA

HERE_CFA:
    dw HERE_code

HERE_code:
    ; Push current TOS (DE) to data stack memory (IX)
    dec ix
    ld a, d
    ld (ix+0), a
    dec ix
    ld a, e
    ld (ix+0), a
    
    ; Load DP into TOS (DE)
    ld hl, (USER_AREA_START + U_DP)
    ld d, h
    ld e, l
    
    jp NEXT

; -----------------------------------------------------------------------------
; PAD ( -- addr )
; Leaves the address of the scratchpad buffer (HERE + 68) on the stack.
; -----------------------------------------------------------------------------
PAD_NFA:
    ; Name Field: Length 3, bit 7 set in length ($83), first ('P') and last ('D') characters
    ; P = $50 -> $D0, D = $44 -> $C4
    db $83, $D0, 'A', $C4

    ; Link Field: Points to HERE_NFA
    dw HERE_NFA

PAD_CFA:
    dw PAD_code

PAD_code:
    ; Push current TOS (DE) to data stack memory (IX)
    dec ix
    ld a, d
    ld (ix+0), a
    dec ix
    ld a, e
    ld (ix+0), a
    
    ; Load DP into HL
    ld hl, (USER_AREA_START + U_DP)
    
    ; Add PAD offset (68 bytes)
    ld de, 68
    add hl, de
    
    ; Place PAD address in TOS (DE)
    ld d, h
    ld e, l
    
    jp NEXT

; -----------------------------------------------------------------------------
; ALLOT ( n -- )
; Allocates n bytes in the dictionary by advancing DP by n.
; -----------------------------------------------------------------------------
ALLOT_NFA:
    ; Name Field: Length 5, bit 7 set in length ($85), first ('A') and last ('T') characters
    ; A = $41 -> $C1, T = $54 -> $D4
    db $85, $C1, 'L', 'L', 'O', $D4

    ; Link Field: Points to PAD_NFA
    dw PAD_NFA

ALLOT_CFA:
    dw ALLOT_code

ALLOT_code:
    ; Load current DP into HL
    ld hl, (USER_AREA_START + U_DP)
    
    ; Add n (TOS DE) to DP (HL)
    add hl, de
    
    ; Store updated DP
    ld (USER_AREA_START + U_DP), hl
    
    ; Pop new TOS (DE) from data stack memory (IX)
    ld a, (ix+0)
    ld e, a
    ld a, (ix+1)
    ld d, a
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; C, ( char -- )
; Allocates one byte in the dictionary and stores char there, advancing DP by 1.
; -----------------------------------------------------------------------------
C_COMMA_NFA:
    ; Name Field: Length 2, bit 7 set in length ($82), first ('C') and last (',') characters
    ; C = $43 -> $C3, , = $2C -> $AC
    db $82, $C3, $AC

    ; Link Field: Points to ALLOT_NFA
    dw ALLOT_NFA

C_COMMA_CFA:
    dw C_COMMA_code

C_COMMA_code:
    ; Load current DP into HL
    ld hl, (USER_AREA_START + U_DP)
    
    ; Write low byte of TOS (E) to DP (HL)
    ld (hl), e
    
    ; Advance DP by 1
    inc hl
    ld (USER_AREA_START + U_DP), hl
    
    ; Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; CONSTANT ( x -- )
; Creates a constant with the given name, storing x.
; -----------------------------------------------------------------------------
CONSTANT_NFA:
    ; Name Field: Length 8, bit 7 set in length ($88), first ('C') and last ('T') characters
    ; C = $43 -> $C3, T = $54 -> $D4
    db $88, $C3, 'O', 'N', 'S', 'T', 'A', 'N', $D4

    ; Link Field: Points to C_COMMA_NFA
    dw C_COMMA_NFA

CONSTANT_CFA:
    dw CONSTANT_code

CONSTANT_code:
    push bc                     ; Save Forth IP (BC)
    push de                     ; Save constant value (TOS DE)
    call HEADER_internal
    
    ; Native stack contains: [BC_IP], [constant_value], [NEW_WORD_ADDR]
    pop iy                      ; IY = NEW_WORD_ADDR
    pop de                      ; DE = constant_value
    
    ; Write CFA (pointing to DOCON behavior)
    ld a, DOCON & $FF
    ld (hl), a
    inc hl
    ld a, (DOCON >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL now points to PFA (DP + L + 5)
    
    ; Write constant value (TOS DE) to PFA
    ld a, e
    ld (hl), a
    inc hl
    ld a, d
    ld (hl), a
    inc hl                      ; HL now points to DP + L + 7 (next free location)
    
    ; Update U_DP to point to next free location
    ld (USER_AREA_START + U_DP), hl
    
    ; Update U_CURRENT and U_CONTEXT with NEW_WORD_ADDR (saved in IY)
    ld (USER_AREA_START + U_CURRENT), iy
    ld (USER_AREA_START + U_CONTEXT), iy
    
    ; Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    pop bc                      ; Restore Forth IP
    jp NEXT

; Execution behavior for words defined by CONSTANT
DOCON:
    ; Push current TOS (DE) to data stack memory (IX)
    dec ix
    ld a, d
    ld (ix+0), a
    dec ix
    ld a, e
    ld (ix+0), a
    
    ; HL points to CFA + 1. Advance HL to point to PFA (CFA + 2)
    inc hl
    
    ; Load constant value from PFA (HL) into DE (TOS)
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    
    jp NEXT

; -----------------------------------------------------------------------------
; VARIABLE ( -- )
; Creates a variable with the given name, allocating 2 bytes initialized to 0.
; -----------------------------------------------------------------------------
VARIABLE_NFA:
    ; Name Field: Length 8, bit 7 set in length ($88), first ('V') and last ('E') characters
    ; V = $56 -> $D6, E = $45 -> $C5
    db $88, $D6, 'A', 'R', 'I', 'A', 'B', 'L', $C5

    ; Link Field: Points to CONSTANT_NFA
    dw CONSTANT_NFA

VARIABLE_CFA:
    dw VARIABLE_code

VARIABLE_code:
    push bc                     ; Save Forth IP (BC)
    call HEADER_internal
    
    ; Write CFA (pointing to DOVAR / CREATE_execution behavior)
    ld a, CREATE_execution & $FF
    ld (hl), a
    inc hl
    ld a, (CREATE_execution >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL now points to PFA (DP + L + 5)
    
    ; Initialize variable PFA value with 0 (2 bytes)
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl                      ; HL now points to DP + L + 7 (next free location)
    
    ; Update U_DP to point to next free location
    ld (USER_AREA_START + U_DP), hl
    
    ; Update U_CURRENT and U_CONTEXT with NEW_WORD_ADDR (saved on stack by helper)
    pop hl                      ; HL = NEW_WORD_ADDR
    ld (USER_AREA_START + U_CURRENT), hl
    ld (USER_AREA_START + U_CONTEXT), hl
    
    pop bc                      ; Restore Forth IP
    jp NEXT

; Define DOVAR alias for CREATE_execution
DOVAR: equ CREATE_execution

; -----------------------------------------------------------------------------
; [COMPILE] ( -- )
; Forces compilation of an immediate word.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
BRACKET_COMPILE_NFA:
    ; Name Field: Length 9, bit 7 set (and bit 6 set for IMMEDIATE) = $C9
    ; '[' = $5B -> $DB, ']' = $5D -> $DD
    db $C9, $DB, 'C', 'O', 'M', 'P', 'I', 'L', 'E', $DD

    ; Link Field: Points to VARIABLE_NFA
    dw VARIABLE_NFA

BRACKET_COMPILE_CFA:
    dw BRACKET_COMPILE_code

BRACKET_COMPILE_code:
    push bc                     ; Save Forth IP (BC)
    
    ; Parse next word name from TIB
    ld b, 32                    ; space delimiter
    call WORD_internal          ; Returns DE = parsed token string (HERE)
    
    ; Setup IY for FIND_internal
    push de
    pop iy
    call FIND_internal          ; Returns HL = CFA, DE = NFA, A = 1 if found
    
    or a
    jr z, bracket_compile_err
    
    ; Word found, HL = CFA. Compile it!
    ld de, (USER_AREA_START + U_DP)
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a
    inc de
    ld (USER_AREA_START + U_DP), de
    
    pop bc                      ; Restore Forth IP
    jp NEXT

bracket_compile_err:
    pop bc                      ; Clear Forth IP from stack
    jp INTERPRET_error          ; Print error message and abort

; -----------------------------------------------------------------------------
; COMPILE ( -- )
; Compiles the next CFA in the instruction stream into the current definition.
; -----------------------------------------------------------------------------
COMPILE_NFA:
    ; Name Field: Length 7, bit 7 set in length ($87), first ('C') and last ('E') characters
    ; C = $43 -> $C3, E = $45 -> $C5
    db $87, $C3, 'O', 'M', 'P', 'I', 'L', $C5

    ; Link Field: Points to BRACKET_COMPILE_NFA
    dw BRACKET_COMPILE_NFA

COMPILE_CFA:
    dw COMPILE_code

COMPILE_code:
    ; 1. Load the CFA of the target word from current IP (BC) into HL
    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a
    inc bc                      ; BC (IP) is advanced past the compiled CFA
    
    ; Now HL contains the CFA of the word to be compiled.
    ; 2. Write HL to the dictionary at U_DP
    ld de, (USER_AREA_START + U_DP)
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a
    inc de
    
    ; 3. Update U_DP to the new address
    ld (USER_AREA_START + U_DP), de
    
    jp NEXT

; -----------------------------------------------------------------------------
; LITERAL ( x -- )
; Compiles x into the current definition as a literal value.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
LITERAL_NFA:
    ; Name Field: Length 7, bit 7 set in length and bit 6 set (IMMEDIATE) = $C7
    ; L = $4C -> $CC
    db $C7, $CC, 'I', 'T', 'E', 'R', 'A', $CC

    ; Link Field: Points to COMPILE_NFA
    dw COMPILE_NFA

LITERAL_CFA:
    dw LITERAL_code

LITERAL_code:
    ; 1. Load current DP into HL
    ld hl, (USER_AREA_START + U_DP)
    
    ; 2. Compile LIT_CFA
    ld a, LIT_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (LIT_CFA >> 8) & $FF
    ld (hl), a
    inc hl
    
    ; 3. Compile the literal value x (TOS DE)
    ld a, e
    ld (hl), a
    inc hl
    ld a, d
    ld (hl), a
    inc hl
    
    ; 4. Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    ; 5. Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    jp NEXT

; =============================================================================
; Control Flow - Run-time Branching Helpers (Internal Primitives)
; =============================================================================

; -----------------------------------------------------------------------------
; BRANCH ( -- )
; Unconditional branch. Reads the next absolute target address from the
; instruction stream and sets the IP (BC) to it.
; -----------------------------------------------------------------------------
BRANCH_NFA:
    ; Name Field: Length 6, bit 7 set in length ($86), first ('B') and last ('H') characters
    ; B = $42 -> $C2, H = $48 -> $C8
    db $86, $C2, 'R', 'A', 'N', 'C', $C8

    ; Link Field: Points to LITERAL_NFA
    dw LITERAL_NFA

BRANCH_CFA:
    dw BRANCH_code

BRANCH_code:
    ; Read absolute address from current IP (BC) into HL
    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a
    
    ; Set IP (BC) to new target address (HL)
    ld b, h
    ld c, l
    
    jp NEXT

; -----------------------------------------------------------------------------
; 0BRANCH ( flag -- )
; Conditional branch. If flag is 0, branches to the absolute address in the
; instruction stream. Otherwise, skips the target address.
; -----------------------------------------------------------------------------
ZERO_BRANCH_NFA:
    ; Name Field: Length 7, bit 7 set in length ($87), first ('0') and last ('H') characters
    ; 0 = $30 -> $B0, H = $48 -> $C8
    db $87, $B0, 'B', 'R', 'A', 'N', 'C', $C8

    ; Link Field: Points to BRANCH_NFA
    dw BRANCH_NFA

ZERO_BRANCH_CFA:
    dw ZERO_BRANCH_code

ZERO_BRANCH_code:
    ; Check if TOS (DE) is zero
    ld a, d
    or e
    jr z, zero_branch_take
    
    ; TOS is not zero: skip branch address (advance BC by 2)
    inc bc
    inc bc
    jr zero_branch_done
    
zero_branch_take:
    ; TOS is zero: branch! Read absolute address from (BC) into BC
    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a
    ld b, h
    ld c, l
    
zero_branch_done:
    ; Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    jp NEXT

; =============================================================================
; Control Flow - Compile-time Words (IMMEDIATE)
; =============================================================================

; -----------------------------------------------------------------------------
; IF ( -- orig )
; Compiles 0BRANCH and leaves HERE on stack to resolve branch target.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
IF_NFA:
    ; Name Field: Length 2, bit 7 and bit 6 set (IMMEDIATE) = $C2.
    ; I = $49 -> $C9, F = $46 -> $C6
    db $C2, $C9, $C6

    ; Link Field: Points to ZERO_BRANCH_NFA
    dw ZERO_BRANCH_NFA

IF_CFA:
    dw IF_code

IF_code:
    ; 1. Compile ZERO_BRANCH_CFA
    ld hl, (USER_AREA_START + U_DP)
    ld a, ZERO_BRANCH_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (ZERO_BRANCH_CFA >> 8) & $FF
    ld (hl), a
    inc hl
    
    ; 2. Push current DP (HL) onto the data stack (IX)
    dec ix
    ld a, d
    ld (ix+0), a
    dec ix
    ld a, e
    ld (ix+0), a
    
    ; Load HL (current DP) into DE (TOS)
    ld d, h
    ld e, l
    
    ; 3. Compile dummy target address 0 (2 bytes)
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl
    
    ; 4. Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    jp NEXT

; -----------------------------------------------------------------------------
; ELSE ( orig1 -- orig2 )
; Compiles BRANCH, resolves orig1 to current HERE, and leaves new target on stack.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
ELSE_NFA:
    ; Name Field: Length 4, bit 7 and bit 6 set (IMMEDIATE) = $C4.
    ; E = $45 -> $C5
    db $C4, $C5, 'L', 'S', $C5

    ; Link Field: Points to IF_NFA
    dw IF_NFA

ELSE_CFA:
    dw ELSE_code

ELSE_code:
    ; 1. Compile BRANCH_CFA
    ld hl, (USER_AREA_START + U_DP)
    ld a, BRANCH_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (BRANCH_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to the dummy target cell of ELSE
    
    ; 2. Push orig1 (DE) onto data stack (IX)
    dec ix
    ld a, d
    ld (ix+0), a
    dec ix
    ld (ix+0), e
    
    ; 3. Set new TOS (DE) to addr_ELSE_target (HL)
    ld d, h
    ld e, l
    
    ; 4. Compile dummy target address 0 (2 bytes) at HL
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl                      ; HL now points to addr_after_ELSE
    
    ; Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    ; 5. Resolve orig1 (which is at the top of IX stack) with addr_after_ELSE (HL)
    ld a, (ix+0)
    ld iyl, a
    ld a, (ix+1)
    ld iyh, a
    
    ; Write HL (addr_after_ELSE) to address in IY
    ld a, l
    ld (iy+0), a
    ld a, h
    ld (iy+1), a
    
    ; 6. Pop orig1 from IX stack
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; THEN ( orig -- )
; Resolves the branch target at orig to the current HERE.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
THEN_NFA:
    ; Name Field: Length 4, bit 7 and bit 6 set (IMMEDIATE) = $C4.
    ; T = $54 -> $D4, N = $4E -> $CE
    db $C4, $D4, 'H', 'E', $CE

    ; Link Field: Points to ELSE_NFA
    dw ELSE_NFA

THEN_CFA:
    dw THEN_code

THEN_code:
    ; Load current DP (HERE) into HL
    ld hl, (USER_AREA_START + U_DP)
    
    ; TOS DE contains the offset target address.
    ; Write HL (HERE) to the address in DE
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a
    
    ; Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; BEGIN ( -- dest )
; Leaves the current dictionary pointer (HERE) on the stack as a loop destination.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
BEGIN_NFA:
    ; Name Field: Length 5, bit 7 and bit 6 set (IMMEDIATE) = $C5.
    ; B = $42 -> $C2, N = $4E -> $CE
    db $C5, $C2, 'E', 'G', 'I', $CE

    ; Link Field: Points to THEN_NFA
    dw THEN_NFA

BEGIN_CFA:
    dw BEGIN_code

BEGIN_code:
    ; Load current DP (HERE) into HL
    ld hl, (USER_AREA_START + U_DP)
    
    ; Push current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e
    
    ; Set new TOS (DE) to HERE (HL)
    ld d, h
    ld e, l
    
    jp NEXT

; -----------------------------------------------------------------------------
; UNTIL ( dest -- )
; Compiles a ZERO_BRANCH followed by the absolute destination address.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
UNTIL_NFA:
    ; Name Field: Length 5, bit 7 and bit 6 set (IMMEDIATE) = $C5.
    ; U = $55 -> $D5, L = $4C -> $CC
    db $C5, $D5, 'N', 'T', 'I', $CC

    ; Link Field: Points to BEGIN_NFA
    dw BEGIN_NFA

UNTIL_CFA:
    dw UNTIL_code

UNTIL_code:
    ; Load current DP into HL
    ld hl, (USER_AREA_START + U_DP)
    
    ; 1. Compile ZERO_BRANCH_CFA
    ld a, ZERO_BRANCH_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (ZERO_BRANCH_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to the target cell in compilation
    
    ; 2. Compile dest (TOS DE) into the target cell
    ld a, e
    ld (hl), a
    inc hl
    ld a, d
    ld (hl), a
    inc hl                      ; HL now points to next free cell
    
    ; 3. Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    ; 4. Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; WHILE ( dest -- dest orig )
; Compiles a ZERO_BRANCH with a dummy target cell, leaving the target address cell
; on the stack above the BEGIN destination.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
WHILE_NFA:
    ; Name Field: Length 5, bit 7 and bit 6 set (IMMEDIATE) = $C5.
    ; W = $57 -> $D7, E = $45 -> $C5
    db $C5, $D7, 'H', 'I', 'L', $C5

    ; Link Field: Points to UNTIL_NFA
    dw UNTIL_NFA

WHILE_CFA:
    dw WHILE_code

WHILE_code:
    ; 1. Compile ZERO_BRANCH_CFA
    ld hl, (USER_AREA_START + U_DP)
    ld a, ZERO_BRANCH_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (ZERO_BRANCH_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to dummy target cell (orig)
    
    ; 2. Push dest (TOS DE) onto data stack (IX)
    dec ix
    ld a, d
    ld (ix+0), a
    dec ix
    ld (ix+0), e
    
    ; 3. Set new TOS (DE) to orig (HL)
    ld d, h
    ld e, l
    
    ; 4. Compile dummy target address 0 (2 bytes)
    xor a
    ld (hl), a
    inc hl
    ld (hl), a
    inc hl                      ; HL points to next free cell
    
    ; 5. Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    jp NEXT

; -----------------------------------------------------------------------------
; REPEAT ( dest orig -- )
; Compiles an unconditional BRANCH back to dest, resolves orig to the current HERE,
; and cleans the stack.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
REPEAT_NFA:
    ; Name Field: Length 6, bit 7 and bit 6 set (IMMEDIATE) = $C6.
    ; R = $52 -> $D2, T = $54 -> $D4
    db $C6, $D2, 'E', 'P', 'E', 'A', $D4

    ; Link Field: Points to WHILE_NFA
    dw WHILE_NFA

REPEAT_CFA:
    dw REPEAT_code

REPEAT_code:
    ; 1. Compile BRANCH_CFA
    ld hl, (USER_AREA_START + U_DP)
    ld a, BRANCH_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (BRANCH_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to target cell of BRANCH
    
    ; 2. Compile dest (which is at the top of IX stack)
    ld a, (ix+0)                ; low byte of dest
    ld (hl), a
    inc hl
    ld a, (ix+1)                ; high byte of dest
    ld (hl), a
    inc hl                      ; HL now points to addr_after_REPEAT
    
    ; Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    ; 3. Resolve orig (TOS DE) with addr_after_REPEAT (HL)
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a
    
    ; 4. Pop dest and the new TOS from data stack memory (IX)
    ld e, (ix+2)
    ld d, (ix+3)
    inc ix
    inc ix
    inc ix
    inc ix                      ; remove 4 bytes (dest and old TOS)
    
    jp NEXT

; -----------------------------------------------------------------------------
; (DO) ( limit start -- )
; Runtime routine for DO. Pops limit and start from data stack, and pushes them
; onto the return stack (SP).
; -----------------------------------------------------------------------------
DO_RUN_NFA:
    ; Name Field: Length 4, bit 7 set in first and last characters ($84)
    ; '(' = $28 -> $A8, ')' = $29 -> $A9
    db $84, $A8, 'D', 'O', $A9

    ; Link Field: Points to REPEAT_NFA
    dw REPEAT_NFA

DO_RUN_CFA:
    dw DO_code

DO_code:
    ; Copy IX (DSP) to HL
    push ix
    pop hl
    
    ; Save start/index (TOS DE) to IY
    push de
    pop iy
    
    ; Read limit (2 bytes) from (HL) into DE
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    
    ; Copy limit (DE) to HL
    ld h, d
    ld l, e
    
    ; Restore start/index (IY) to DE
    push iy
    pop de
    
    ; Increment data stack pointer IX by 2 (limit consumed)
    inc ix
    inc ix
    
    ; Push limit (HL) to Return Stack (SP)
    push hl
    
    ; Push index (DE) to Return Stack (SP)
    push de
    
    ; Pop new TOS (DE) from data stack memory (IX) using standard 8-bit loads
    ld a, (ix+0)
    ld e, a
    ld a, (ix+1)
    ld d, a
    inc ix
    inc ix
    
    jp NEXT

; -----------------------------------------------------------------------------
; (LOOP) ( -- )
; Runtime routine for LOOP. Increments index, compares with limit, and branches
; back if index != limit. Otherwise, discards loop parameters and exits loop.
; -----------------------------------------------------------------------------
LOOP_RUN_NFA:
    ; Name Field: Length 6, bit 7 set in first and last characters ($86)
    ; '(' = $28 -> $A8, ')' = $29 -> $A9
    db $86, $A8, 'L', 'O', 'O', 'P', $A9

    ; Link Field: Points to DO_RUN_NFA
    dw DO_RUN_NFA

LOOP_RUN_CFA:
    dw LOOP_code

LOOP_SAVED_TOS: dw 0

LOOP_code:
    ; Save TOS (DE) to exclusive RAM variable using standard HL instructions
    ld h, d
    ld l, e
    ld (LOOP_SAVED_TOS), hl
    
    ; Pop current index from return stack (SP) into HL
    pop hl
    
    ; Pop limit from return stack (SP) into DE
    pop de
    
    ; Increment index
    inc hl
    
    ; Push limit and index back to the return stack (in case loop continues)
    push de
    push hl
    
    ; Compare index (HL) with limit (DE)
    or a
    sbc hl, de
    
    jr z, loop_terminate_static
    
    ; Loop continues: return stack is already updated with limit and index
    ; Restore TOS (DE) using standard HL instructions
    ld hl, (LOOP_SAVED_TOS)
    ld d, h
    ld e, l
    
    ; Branch back: read target address from BC into BC
    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a
    ld b, h
    ld c, l
    
    jp NEXT

loop_terminate_static:
    ; Loop terminates: clean up the return stack (remove limit and index pushed earlier)
    pop hl
    pop hl
    
    ; Restore TOS (DE) using standard HL instructions
    ld hl, (LOOP_SAVED_TOS)
    ld d, h
    ld e, l
    
    ; Skip branch target address (2 bytes)
    inc bc
    inc bc
    
    jp NEXT

; -----------------------------------------------------------------------------
; DO ( limit start -- )
; Compiles (DO) and leaves loop destination address on stack.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
DO_NFA:
    ; Name Field: Length 2, bit 7 and bit 6 set (IMMEDIATE) = $C2.
    ; D = $44 -> $C4, O = $4F -> $CF
    db $C2, $C4, $CF

    ; Link Field: Points to LOOP_RUN_NFA
    dw LOOP_RUN_NFA

DO_CFA:
    dw DO_compiler_code

DO_compiler_code:
    ; 1. Compile DO_RUN_CFA
    ld hl, (USER_AREA_START + U_DP)
    ld a, DO_RUN_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (DO_RUN_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to next free cell (loop body start)
    
    ; 2. Push HERE (HL) onto data stack (IX)
    dec ix
    ld a, d
    ld (ix+0), a
    dec ix
    ld (ix+0), e
    
    ; 3. Set new TOS (DE) to HERE (HL)
    ld d, h
    ld e, l
    
    ; 4. Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    jp NEXT

; -----------------------------------------------------------------------------
; LOOP ( -- )
; Compiles (LOOP) and destination address.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
LOOP_NFA:
    ; Name Field: Length 4, bit 7 and bit 6 set (IMMEDIATE) = $C4.
    ; L = $4C -> $CC, P = $50 -> $D0
    db $C4, $CC, 'O', 'O', $D0

    ; Link Field: Points to DO_NFA
    dw DO_NFA

LOOP_CFA:
    dw LOOP_compiler_code

LOOP_compiler_code:
    ; 1. Compile LOOP_RUN_CFA
    ld hl, (USER_AREA_START + U_DP)
    ld a, LOOP_RUN_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (LOOP_RUN_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to target cell
    
    ; 2. Compile dest (TOS DE) into target cell
    ld a, e
    ld (hl), a
    inc hl
    ld a, d
    ld (hl), a
    inc hl                      ; HL points to next free cell
    
    ; Update U_DP
    ld (USER_AREA_START + U_DP), hl
    
    ; 3. Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    
    jp NEXT


; -----------------------------------------------------------------------------
; (+LOOP) ( -- )
; Runtime routine for +LOOP. Consumes increment from stack, adds to index,
; compares index with limit using boundary crossing logic, and branches
; back if the loop should continue.
; -----------------------------------------------------------------------------
PLUS_LOOP_RUN_NFA:
    ; Name Field: Length 7, bit 7 set in first and last characters ($87)
    ; '(' = $28 -> $A8, ')' = $29 -> $A9
    db $87, $A8, $2B, $4C, $4F, $4F, $50, $A9

    ; Link Field: Points to LOOP_NFA
    dw LOOP_NFA

PLUS_LOOP_RUN_CFA:
    dw PLUS_LOOP_code

PLUS_LOOP_INDEX_OLD: dw 0
PLUS_LOOP_INDEX_NEW: dw 0
PLUS_LOOP_LIMIT:     dw 0
PLUS_LOOP_STEP:      dw 0
PLUS_LOOP_SAVED_TOS: dw 0
PLUS_LOOP_TEMP:      db 0

PLUS_LOOP_code:

    ; 1. Save step 'n' (DE) to PLUS_LOOP_STEP
    ld h, d
    ld l, e
    ld (PLUS_LOOP_STEP), hl

    ; 2. Pop new TOS (DE) from data stack memory (IX) safely using standard 8-bit loads
    ld a, (ix+0)
    ld e, a
    ld a, (ix+1)
    ld d, a
    inc ix
    inc ix

    ; Save new TOS (DE) to PLUS_LOOP_SAVED_TOS
    ld h, d
    ld l, e
    ld (PLUS_LOOP_SAVED_TOS), hl

    ; 3. Pop index_old and limit from return stack (SP)
    pop hl
    ld (PLUS_LOOP_INDEX_OLD), hl
    pop hl
    ld (PLUS_LOOP_LIMIT), hl

    ; 4. Calculate index_new = index_old + n
    ld hl, (PLUS_LOOP_STEP)
    ld d, h
    ld e, l                   ; DE = n
    ld hl, (PLUS_LOOP_INDEX_OLD)
    add hl, de                ; HL = index_new
    ld (PLUS_LOOP_INDEX_NEW), hl

    ; 5. Calculate D_old = index_old - limit - $8000
    ld hl, (PLUS_LOOP_LIMIT)
    ld d, h
    ld e, l                   ; DE = limit
    ld hl, (PLUS_LOOP_INDEX_OLD)
    or a
    sbc hl, de                ; HL = index_old - limit
    ld a, h
    xor $80
    ld (PLUS_LOOP_TEMP), a    ; Save D_old_high in PLUS_LOOP_TEMP

    ; 6. Calculate D_new = index_new - limit - $8000
    ld hl, (PLUS_LOOP_LIMIT)
    ld d, h
    ld e, l                   ; DE = limit
    ld hl, (PLUS_LOOP_INDEX_NEW)
    or a
    sbc hl, de                ; HL = index_new - limit
    ld a, h
    xor $80
    ld h, a                   ; H = D_new_high

    ; 7. Apply boundary crossing formula (overflow check)
    ; Overflow = ((D_old_high ^ D_new_high) & (n_high ^ D_new_high) & $80) != 0
    ld a, (PLUS_LOOP_STEP + 1)
    ld d, a                   ; D = n_high
    
    ld a, (PLUS_LOOP_TEMP)    ; A = D_old_high
    xor h                     ; A = D_old_high ^ D_new_high
    ld (PLUS_LOOP_TEMP), a    ; Save (D_old_high ^ D_new_high) in PLUS_LOOP_TEMP
    
    ld a, d                   ; A = n_high
    xor h                     ; A = n_high ^ D_new_high
    
    ld hl, PLUS_LOOP_TEMP
    and (hl)                  ; A = (n_high ^ D_new_high) & (D_old_high ^ D_new_high)
    and $80
    
    jp nz, plus_loop_terminate

plus_loop_continue:

    ; Recalcular/empilhar limit e index_new na pilha de retorno
    ld hl, (PLUS_LOOP_LIMIT)
    push hl
    ld hl, (PLUS_LOOP_INDEX_NEW)
    push hl

    ; Restore TOS (DE)
    ld hl, (PLUS_LOOP_SAVED_TOS)
    ld d, h
    ld e, l

    ; Branch back: read target address from BC into BC
    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a
    ld b, h
    ld c, l

    jp NEXT

plus_loop_terminate:

    ; Restore TOS (DE)
    ld hl, (PLUS_LOOP_SAVED_TOS)
    ld d, h
    ld e, l

    ; Terminate: skip branch target address (2 bytes)
    inc bc
    inc bc

    jp NEXT

; -----------------------------------------------------------------------------
; +LOOP ( -- )
; Compiles (+LOOP) and destination address.
; This is an IMMEDIATE word.
; -----------------------------------------------------------------------------
PLUS_LOOP_NFA:
    ; Name Field: Length 5, bit 7 and bit 6 set (IMMEDIATE) = $C5
    ; '+' = $2B -> $AB
    db $C5, $AB, $4C, $4F, $4F, $D0

    ; Link Field: Points to PLUS_LOOP_RUN_NFA
    dw PLUS_LOOP_RUN_NFA

PLUS_LOOP_CFA:
    dw PLUS_LOOP_compiler_code

PLUS_LOOP_compiler_code:
    ; 1. Compile PLUS_LOOP_RUN_CFA
    ld hl, (USER_AREA_START + U_DP)
    ld a, PLUS_LOOP_RUN_CFA & $FF
    ld (hl), a
    inc hl
    ld a, (PLUS_LOOP_RUN_CFA >> 8) & $FF
    ld (hl), a
    inc hl                      ; HL points to target cell

    ; 2. Compile dest (TOS DE) into target cell
    ld a, e
    ld (hl), a
    inc hl
    ld a, d
    ld (hl), a
    inc hl                      ; HL points to next free cell

    ; Update U_DP
    ld (USER_AREA_START + U_DP), hl

    ; 3. Pop new TOS (DE) from data stack memory (IX)
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix

    jp NEXT

; -----------------------------------------------------------------------------
; I ( -- n )
; Copies the index of the innermost loop onto the data stack.
; -----------------------------------------------------------------------------
I_NFA:
    ; Name Field: Length 1, bit 7 set in first and last characters ($81)
    ; 'I' = $49 -> $C9
    db $81, $C9

    ; Link Field: Points to PLUS_LOOP_NFA
    dw PLUS_LOOP_NFA

I_CFA:
    dw I_code

I_code:
    ; 1. Pop current index from Return Stack (SP) into HL
    pop hl
    ; 2. Push it back immediately to preserve Return Stack
    push hl

    ; 3. Push current TOS (DE) onto the data stack (IX)
    dec ix
    ld (ix+0), d
    dec ix
    ld (ix+0), e

    ; 4. Load index (HL) into TOS (DE)
    ld d, h
    ld e, l

    jp NEXT

; -----------------------------------------------------------------------------
; LEAVE ( -- )
; Forces the termination of the innermost DO LOOP by setting the index to limit.
; -----------------------------------------------------------------------------
LEAVE_NFA:
    ; Name Field: Length 5, bit 7 set in first and last characters ($85)
    ; 'L' = $4C -> $CC, 'E' = $45 -> $C5
    db $85, $CC, 'E', 'A', 'V', $C5

    ; Link Field: Points to I_NFA
    dw I_NFA

LEAVE_CFA:
    dw LEAVE_code

LEAVE_code:
    ; 1. Load limit address from Return Stack (SP + 2) into HL
    ld hl, 2
    add hl, sp
    
    ; 2. Read limit (16-bit) into HL
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    
    ; Decrement limit to get limit - 1
    dec hl
    
    ; 3. Overwrite loop index on top of Return Stack (SP) with limit - 1 (HL)
    ex (sp), hl

    jp NEXT
