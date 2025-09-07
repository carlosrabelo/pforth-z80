; =============================================================================
; pForth - Z80 +LOOP Primitives Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1a: Find word "+LOOP" ---
    ld hl, str_plus_loop
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_plus_loop_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == PLUS_LOOP_CFA
    ld iy, err_plus_loop_cfa_mismatch
    ld de, PLUS_LOOP_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that +LOOP is IMMEDIATE (bit 6 set in length byte)
    ld a, (PLUS_LOOP_NFA)
    bit 6, a
    jr nz, plus_loop_immediate_ok
    ld hl, msg_plus_loop_not_immediate
    jp fail_with_msg
plus_loop_immediate_ok:

    ; --- TEST 1b: Find word "(+LOOP)" ---
    ld hl, str_plus_loop_run
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_plus_loop_run_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == PLUS_LOOP_RUN_CFA
    ld iy, err_plus_loop_run_cfa_mismatch
    ld de, PLUS_LOOP_RUN_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that (+LOOP) is NOT IMMEDIATE (bit 6 NOT set in length byte)
    ld a, (PLUS_LOOP_RUN_NFA)
    bit 6, a
    jr z, plus_loop_run_not_immediate_ok
    ld hl, msg_plus_loop_run_immediate
    jp fail_with_msg
plus_loop_run_not_immediate_ok:

    ; --- TEST 2: +LOOP Compilation Logic ---

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

    ; Run compilation macro list: DO, then +LOOP
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

    ; 1. Verify DP has advanced by 6 bytes (2 for (DO) CFA, 2 for (+LOOP) CFA, 2 for offset)
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

    ; 3. Verify compiled CFA at initial_dp + 2 is PLUS_LOOP_RUN_CFA
    ld hl, (saved_dp_val)
    inc hl
    inc hl                      ; HL = DP0 + 2
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, PLUS_LOOP_RUN_CFA
    ld iy, err_cfa_plus_loop_run
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
    ld iy, err_target_plus_loop
    call assert_de_hl

    ; 5. Verify final TOS is the original TOS ($1111)
    ld hl, (saved_tos)
    ld de, $1111
    ld iy, err_tos_comp
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 3: Execution - Step +1 (0 to 3) ---
    ; Save initial DSP
    push ix
    pop hl
    ld (saved_dsp), hl
    
    ; Run loop execution test list
    ld bc, ip_loop_test_pos_1
    jp NEXT

verify_loop_results_pos_1:
    dw verify_loop_results_pos_1_code
verify_loop_results_pos_1_code:
    ; Save final TOS
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; Verify final TOS is 13 (10 + 3 iterations of 1)
    ld hl, (saved_tos)
    ld de, 13
    ld iy, err_loop_tos_pos_1
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 4: Execution - Step +2 (0 to 5) ---
    ; Run loop execution test list
    ld bc, ip_loop_test_pos_2
    jp NEXT

verify_loop_results_pos_2:
    dw verify_loop_results_pos_2_code
verify_loop_results_pos_2_code:
    ; Save final TOS
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; Verify final TOS is 13 (10 + 3 iterations [0, 2, 4] of 1)
    ld hl, (saved_tos)
    ld de, 13
    ld iy, err_loop_tos_pos_2
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 5: Execution - Step -1 (3 to 0) ---
    ; Run loop execution test list
    ld bc, ip_loop_test_neg_1
    jp NEXT

verify_loop_results_neg_1:
    dw verify_loop_results_neg_1_code
verify_loop_results_neg_1_code:
    ; Save final TOS
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; Verify final TOS is 14 (10 + 4 iterations [3, 2, 1, 0] of 1)
    ld hl, (saved_tos)
    ld de, 14
    ld iy, err_loop_tos_neg_1
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 6: Execution - Step -2 (3 to 0) ---
    ; Run loop execution test list
    ld bc, ip_loop_test_neg_2
    jp NEXT

verify_loop_results_neg_2:
    dw verify_loop_results_neg_2_code
verify_loop_results_neg_2_code:
    ; Save final TOS
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; Verify final TOS is 12 (10 + 2 iterations [3, 1] of 1)
    ld hl, (saved_tos)
    ld de, 12
    ld iy, err_loop_tos_neg_2
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    jp pass_all

    ; All tests passed!
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0
saved_dp_val: dw 0

str_plus_loop:
    db 5
    db $2B, $4C, $4F, $4F, $50
str_plus_loop_run:
    db 7
    db $28, $2B, $4C, $4F, $4F, $50, $29

ip_compilation:
    dw DO_CFA
    dw PLUS_LOOP_CFA
    dw verify_compilation_results

ip_loop_test_pos_1:
    dw LIT_CFA
    dw 10               ; Initial accumulator
    dw LIT_CFA
    dw 3                ; limit
    dw LIT_CFA
    dw 0                ; start
    dw DO_RUN_CFA
label_pos_1:
    ; Body: increment accumulator by 1
    dw LIT_CFA
    dw 1
    dw PLUS_CFA
    ; Step
    dw LIT_CFA
    dw 1
    ; +LOOP
    dw PLUS_LOOP_RUN_CFA
    dw label_pos_1
    
    dw verify_loop_results_pos_1

ip_loop_test_pos_2:
    dw LIT_CFA
    dw 10               ; Initial accumulator
    dw LIT_CFA
    dw 5                ; limit
    dw LIT_CFA
    dw 0                ; start
    dw DO_RUN_CFA
label_pos_2:
    ; Body: increment accumulator by 1
    dw LIT_CFA
    dw 1
    dw PLUS_CFA
    ; Step
    dw LIT_CFA
    dw 2
    ; +LOOP
    dw PLUS_LOOP_RUN_CFA
    dw label_pos_2
    
    dw verify_loop_results_pos_2

ip_loop_test_neg_1:
    dw LIT_CFA
    dw 10               ; Initial accumulator
    dw LIT_CFA
    dw 0                ; limit
    dw LIT_CFA
    dw 3                ; start
    dw DO_RUN_CFA
label_neg_1:
    ; Body: increment accumulator by 1
    dw LIT_CFA
    dw 1
    dw PLUS_CFA
    ; Step
    dw LIT_CFA
    dw -1
    ; +LOOP
    dw PLUS_LOOP_RUN_CFA
    dw label_neg_1
    
    dw verify_loop_results_neg_1

ip_loop_test_neg_2:
    dw LIT_CFA
    dw 10               ; Initial accumulator
    dw LIT_CFA
    dw 0                ; limit
    dw LIT_CFA
    dw 3                ; start
    dw DO_RUN_CFA
label_neg_2:
    ; Body: increment accumulator by 1
    dw LIT_CFA
    dw 1
    dw PLUS_CFA
    ; Step
    dw LIT_CFA
    dw -2
    ; +LOOP
    dw PLUS_LOOP_RUN_CFA
    dw label_neg_2
    
    dw verify_loop_results_neg_2

err_plus_loop_not_found:        db "Word '+LOOP' not found", 0
err_dup_not_found_debug:        db "Word 'DUP' not found (debug)", 0
str_dup:                        db 3, 'D', 'U', 'P'
err_plus_loop_cfa_mismatch:     db "+LOOP CFA mismatch", 0
msg_plus_loop_not_immediate:    db "+LOOP is not IMMEDIATE", 0

err_plus_loop_run_not_found:    db "Word '(+LOOP)' not found", 0
err_plus_loop_run_cfa_mismatch: db "(+LOOP) CFA mismatch", 0
msg_plus_loop_run_immediate:    db "(+LOOP) is IMMEDIATE", 0

err_dp_comp:                   db "DP mismatch after +LOOP compilation", 0
err_cfa_do_run:                db "DO compiled incorrect runtime CFA (expected (DO))", 0
err_cfa_plus_loop_run:          db "+LOOP compiled incorrect runtime CFA (expected (+LOOP))", 0
err_target_plus_loop:          db "+LOOP compiled incorrect target destination", 0
err_tos_comp:                  db "TOS mismatch after +LOOP compilation", 0

err_loop_tos_pos_1:            db "Pos 1 loop final TOS is incorrect", 0
err_loop_tos_pos_2:            db "Pos 2 loop final TOS is incorrect", 0
err_loop_tos_neg_1:            db "Neg 1 loop final TOS is incorrect", 0
err_loop_tos_neg_2:            db "Neg 2 loop type final TOS is incorrect", 0

err_len_mismatch:     db "Length mismatch", 0
err_char1_mismatch:   db "Char 1 mismatch", 0
err_char2_mismatch:   db "Char 2 mismatch", 0
err_char3_mismatch:   db "Char 3 mismatch", 0
err_char4_mismatch:   db "Char 4 mismatch", 0
err_char5_mismatch:   db "Char 5 mismatch", 0


