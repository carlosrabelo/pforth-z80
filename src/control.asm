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


; Scaffold: INTERPRET dispatch buffers and QUIT restart (replaced by QUIT)
SAVED_IP:    dw 0
SAVED_TOS:   dw 0
EXEC_BUF:    dw 0
EXEC_RESUME: dw RESUME_CFA

RESUME_CFA:  dw RESUME_code

RESUME_code:
    jp INTERPRET_loop

QUIT_restart:
    jp start
