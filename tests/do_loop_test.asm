; =============================================================================
; pForth - Z80 DO, LOOP Primitives Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1a: Find word "DO" ---
    ld hl, str_do
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_do_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == DO_CFA
    ld iy, err_do_cfa_mismatch
    ld de, DO_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that DO is IMMEDIATE (bit 6 set in length byte)
    ld a, (DO_NFA)
    bit 6, a
    jr nz, do_immediate_ok
    ld hl, msg_do_not_immediate
    jp fail_with_msg
do_immediate_ok:

    ; --- TEST 1b: Find word "LOOP" ---
    ld hl, str_loop
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_loop_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == LOOP_CFA
    ld iy, err_loop_cfa_mismatch
    ld de, LOOP_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that LOOP is IMMEDIATE (bit 6 set in length byte)
    ld a, (LOOP_NFA)
    bit 6, a
    jr nz, loop_immediate_ok
    ld hl, msg_loop_not_immediate
    jp fail_with_msg
loop_immediate_ok:
;    jp test3_start

    ; --- TEST 2: DO & LOOP Compilation Logic ---
    ; Set STATE to 1 (compiling)
    ld a, 1
    ld (USER_AREA_START + U_STATE), a

    ; Save initial DP
    ld hl, (USER_AREA_START + U_DP)
    ld (saved_dp_val), hl

    ; Save initial DSP
    push ix
    pop hl
    ld (saved_dsp), hl

    ; Push dummy anchor $ABCD
    dec ix
    ld (ix+0), $AB
    dec ix
    ld (ix+0), $CD

    ; Initial TOS
    ld de, $1111

    ; Run compilation macro list: DO, then LOOP
    ld bc, ip_compilation
    jp NEXT

verify_compilation_results:
    dw verify_compilation_results_code
verify_compilation_results_code:
    ; Reset compilation STATE to 0
    xor a
    ld (USER_AREA_START + U_STATE), a

    ; Save final TOS
    ld (saved_tos), de

    ; 1. Verify DP has advanced by 8 bytes (2 for (DO) CFA, 2 for (LOOP) CFA, 2 for offset)
    ; Wait, let's verify exact bytes compiled:
    ; DO compiles DO_RUN_CFA (2 bytes) -> advances DP by 2.
    ; LOOP compiles LOOP_RUN_CFA (2 bytes) and dest (2 bytes) -> advances DP by 4.
    ; So DP advances by 6 bytes total!
    ; Let's verify this!
    ld hl, (USER_AREA_START + U_DP)
    ld de, (saved_dp_val)
    ld a, e
    add a, 6
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    ld iy, err_dp_comp
    call assert_de_hl

    ; 2. Verify compiled CFA at initial_dp is DO_RUN_CFA
    ld hl, (saved_dp_val)
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, DO_RUN_CFA
    ld iy, err_cfa_do_run
    call assert_de_hl

    ; 3. Verify compiled CFA at initial_dp + 2 is LOOP_RUN_CFA
    ld hl, (saved_dp_val)
    inc hl
    inc hl                      ; HL = DP0 + 2
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, LOOP_RUN_CFA
    ld iy, err_cfa_loop_run
    call assert_de_hl

    ; 4. Verify compiled target at initial_dp + 4 points to initial_dp + 2 (loop body start)
    ld hl, (saved_dp_val)
    ld a, l
    add a, 4
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, (saved_dp_val)
    ld a, l
    add a, 2
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    ld iy, err_target_loop
    call assert_de_hl

    ; 5. Verify final TOS is the original TOS ($1111)
    ld hl, (saved_tos)
    ld de, $1111
    ld iy, err_tos_comp
    call assert_de_hl

    ; 6. Verify DSP is original_dsp - 2 (anchor remains)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_comp
    call assert_ix_hl

    ; Restore DSP
    ld ix, (saved_dsp)

test3_start:
    ; Run the loop execution test list
    ld bc, ip_loop_test
    jp NEXT

verify_loop_results:
    dw verify_loop_results_code
verify_loop_results_code:
    ; Save final TOS using standard HL instructions
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; 1. Verify final TOS (accumulator) is 13
    ld hl, (saved_tos)
    ld de, 13
    or a
    push hl
    sbc hl, de
    pop hl
    jp z, tos_ok

    ; Print "TOS was: " followed by the hex value of HL (saved_tos)
    ld hl, msg_tos_was
    call print_str
    ld hl, (saved_tos)
    call print_hex_word
    ld hl, msg_newline
    call print_str

    ; Print "DSP was: " followed by saved_dsp
    ld hl, msg_dsp_was
    call print_str
    ld hl, (saved_dsp)
    call print_hex_word
    ld hl, msg_newline
    call print_str

    ; Print "STACK: "
    ld hl, msg_stack
    call print_str
    ld hl, (saved_dsp)
    ld de, -16
    add hl, de
    ld b, 8
print_stack_loop:
    push bc
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    inc hl
    push hl
    ld l, e
    ld h, d
    call print_hex_word
    ld hl, msg_space
    call print_str
    pop hl
    pop bc
    djnz print_stack_loop
    ld hl, msg_newline
    call print_str

    ld hl, err_loop_tos
    jp fail_with_msg

tos_ok:
    ; 2. Verify DSP is saved_dsp - 2 (anchor remains)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_loop_dsp
    call assert_ix_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; All tests passed!
    jp pass_all

print_hex_word:
    push hl
    ld a, h
    call print_hex_byte
    pop hl
    ld a, l
    call print_hex_byte
    ret

print_hex_byte:
    push af
    rrca
    rrca
    rrca
    rrca
    call print_nibble
    pop af
    call print_nibble
    ret

print_nibble:
    and $0F
    cp 10
    jr c, print_digit
    add a, 'A' - 10
    jp EMIT_char
print_digit:
    add a, '0'
    jp EMIT_char

msg_tos_was: db "TOS was: ", 0
msg_stack: db "STACK: ", 0
msg_space: db " ", 0
msg_dsp_was: db "DSP was: ", 0

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0
saved_dp_val: dw 0

str_do:
    db 2
    db "DO"
str_loop:
    db 4
    db "LOOP"

ip_compilation:
    dw DO_CFA
    dw LOOP_CFA
    dw verify_compilation_results

ip_loop_test:
    dw LIT_CFA
    dw 10
    dw LIT_CFA
    dw 5
    dw LIT_CFA
    dw 2
    dw DO_RUN_CFA
    
label_begin:
    ; Body: increment accumulator by 1
    dw LIT_CFA
    dw 1
    dw PLUS_CFA
    
    ; LOOP
    dw LOOP_RUN_CFA
    dw label_begin
    
    ; Verify execution
    dw verify_loop_results

err_do_not_found:          db "Word 'DO' not found", 0
err_do_cfa_mismatch:       db "DO CFA mismatch", 0
msg_do_not_immediate:      db "DO is not IMMEDIATE", 0

err_loop_not_found:        db "Word 'LOOP' not found", 0
err_loop_cfa_mismatch:     db "LOOP CFA mismatch", 0
msg_loop_not_immediate:    db "LOOP is not IMMEDIATE", 0

err_dp_comp:               db "DP mismatch after compilation", 0
err_cfa_do_run:            db "DO compiled incorrect runtime CFA (expected (DO))", 0
err_cfa_loop_run:          db "LOOP compiled incorrect runtime CFA (expected (LOOP))", 0
err_target_loop:           db "LOOP compiled incorrect target destination", 0
err_tos_comp:              db "TOS mismatch after compilation", 0
err_dsp_comp:              db "DSP mismatch after compilation", 0

err_loop_tos:              db "Loop final TOS is incorrect", 0
err_loop_dsp:              db "Loop final DSP is incorrect", 0

msg_count_0:            db "LOOP_COUNT is 0", 0
msg_count_2:            db "LOOP_COUNT is 2", 0
msg_count_other:        db "LOOP_COUNT is other", 0
msg_iter1_idx_not_0:    db "ITER1_INDEX is not 0", 0
msg_iter1_limit_3:      db "ITER1_INDEX is 0, LIMIT is 3", 0
msg_iter1_limit_0:      db "ITER1_INDEX is 0, LIMIT is 0", 0
msg_iter1_limit_other:  db "ITER1_INDEX is 0, LIMIT is other", 0
