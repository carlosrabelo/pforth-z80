; =============================================================================
; pForth - Z80 BEGIN, WHILE, REPEAT Primitives Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1a: Find word "WHILE" ---
    ld hl, str_while
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_while_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == WHILE_CFA
    ld iy, err_while_cfa_mismatch
    ld de, WHILE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that WHILE is IMMEDIATE (bit 6 set in length byte)
    ld a, (WHILE_NFA)
    bit 6, a
    jr nz, while_immediate_ok
    ld hl, msg_while_not_immediate
    jp fail_with_msg
while_immediate_ok:

    ; --- TEST 1b: Find word "REPEAT" ---
    ld hl, str_repeat
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_repeat_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == REPEAT_CFA
    ld iy, err_repeat_cfa_mismatch
    ld de, REPEAT_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that REPEAT is IMMEDIATE (bit 6 set in length byte)
    ld a, (REPEAT_NFA)
    bit 6, a
    jr nz, repeat_immediate_ok
    ld hl, msg_repeat_not_immediate
    jp fail_with_msg
repeat_immediate_ok:

    ; --- TEST 2: BEGIN, WHILE, REPEAT Compilation Logic ---
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

    ; Run compilation macro list: BEGIN, WHILE, REPEAT
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

    ; 1. Verify DP has advanced by 8 bytes (4 for 0BRANCH + offset, 4 for BRANCH + offset)
    ld hl, (USER_AREA_START + U_DP)
    ld de, (saved_dp_val)
    ld a, e
    add a, 8
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    ld iy, err_dp_comp
    call assert_de_hl

    ; 2. Verify compiled CFA at initial_dp is ZERO_BRANCH_CFA (compiled by WHILE)
    ld hl, (saved_dp_val)
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, ZERO_BRANCH_CFA
    ld iy, err_cfa_while
    call assert_de_hl

    ; 3. Verify compiled target at initial_dp + 2 points to initial_dp + 8 (after REPEAT branch)
    ld hl, (saved_dp_val)
    inc hl
    inc hl                      ; HL = DP0 + 2
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, (saved_dp_val)
    ld a, l
    add a, 8
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    ld iy, err_target_while
    call assert_de_hl

    ; 4. Verify compiled CFA at initial_dp + 4 is BRANCH_CFA (compiled by REPEAT)
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
    ld hl, BRANCH_CFA
    ld iy, err_cfa_repeat
    call assert_de_hl

    ; 5. Verify compiled target at initial_dp + 6 points to initial_dp (BEGIN destination)
    ld hl, (saved_dp_val)
    ld a, l
    add a, 6
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
    ld iy, err_target_repeat
    call assert_de_hl

    ; 6. Verify final TOS is the original TOS ($1111)
    ld hl, (saved_tos)
    ld de, $1111
    ld iy, err_tos_comp
    call assert_de_hl

    ; 7. Verify DSP is original_dsp - 2 (anchor remains)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_comp
    call assert_ix_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 3: Executing BEGIN WHILE REPEAT Loop in Runtime ---
    ; Save initial DSP
    push ix
    pop hl
    ld (saved_dsp), hl

    ; Push dummy anchor $1234
    dec ix
    ld (ix+0), $12
    dec ix
    ld (ix+0), $34

    ; Run the loop execution test list
    ld de, 0                    ; initial TOS
    ld bc, ip_loop_test
    jp NEXT

verify_loop_results:
    dw verify_loop_results_code
verify_loop_results_code:
    ; Save final TOS
    ld (saved_tos), de

    ; 1. Verify final TOS is 0 (remaining loop counter value)
    ld hl, 0
    ld iy, err_loop_tos
    call assert_de_hl

    ; 2. Verify DSP is saved_dsp - 4 (anchor + initial TOS remain)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    dec hl
    dec hl
    ld iy, err_loop_dsp
    call assert_ix_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; All tests passed!
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0
saved_dp_val: dw 0

str_while:
    db 5
    db "WHILE"
str_repeat:
    db 6
    db "REPEAT"

ip_compilation:
    dw BEGIN_CFA
    dw WHILE_CFA
    dw REPEAT_CFA
    dw verify_compilation_results

ip_loop_test:
    ; 1. Push loop counter 3
    dw LIT_CFA
    dw 3
    
label_begin:
    ; Check if counter > 0
    dw DUP_CFA
    dw LIT_CFA
    dw 0
    dw GREATER_CFA
    
    ; Loop condition: WHILE compiles 0BRANCH to label_after_loop
    dw ZERO_BRANCH_CFA
    dw label_after_loop
    
    ; Loop body: decrement loop counter by 1
    dw LIT_CFA
    dw 1
    dw MINUS_CFA
    
    ; Repeat loop: BRANCH back to label_begin
    dw BRANCH_CFA
    dw label_begin
    
label_after_loop:
    ; Verify execution
    dw verify_loop_results

err_while_not_found:       db "Word 'WHILE' not found", 0
err_while_cfa_mismatch:    db "WHILE CFA mismatch", 0
msg_while_not_immediate:   db "WHILE is not IMMEDIATE", 0

err_repeat_not_found:      db "Word 'REPEAT' not found", 0
err_repeat_cfa_mismatch:   db "REPEAT CFA mismatch", 0
msg_repeat_not_immediate:  db "REPEAT is not IMMEDIATE", 0

err_dp_comp:               db "DP mismatch after compilation", 0
err_cfa_while:             db "WHILE compiled incorrect CFA (expected 0BRANCH)", 0
err_target_while:          db "WHILE compiled incorrect target destination", 0
err_cfa_repeat:            db "REPEAT compiled incorrect CFA (expected BRANCH)", 0
err_target_repeat:         db "REPEAT compiled incorrect target destination", 0
err_tos_comp:              db "TOS mismatch after compilation", 0
err_dsp_comp:              db "DSP mismatch after compilation", 0

err_loop_tos:              db "Loop final TOS is incorrect", 0
err_loop_dsp:              db "Loop final DSP is incorrect", 0
