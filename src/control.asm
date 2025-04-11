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

