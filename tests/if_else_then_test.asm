; =============================================================================
; pForth - Z80 IF, ELSE, THEN Primitives Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1a: Find word "IF" ---
    ld hl, str_if
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_if_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == IF_CFA
    ld iy, err_if_cfa_mismatch
    ld de, IF_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that IF is IMMEDIATE (bit 6 set in length byte)
    ld a, (IF_NFA)
    bit 6, a
    jr nz, if_immediate_ok
    ld hl, msg_if_not_immediate
    jp fail_with_msg
if_immediate_ok:

    ; --- TEST 1b: Find word "ELSE" ---
    ld hl, str_else
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_else_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == ELSE_CFA
    ld iy, err_else_cfa_mismatch
    ld de, ELSE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that ELSE is IMMEDIATE (bit 6 set in length byte)
    ld a, (ELSE_NFA)
    bit 6, a
    jr nz, else_immediate_ok
    ld hl, msg_else_not_immediate
    jp fail_with_msg
else_immediate_ok:

    ; --- TEST 1c: Find word "THEN" ---
    ld hl, str_then
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_then_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == THEN_CFA
    ld iy, err_then_cfa_mismatch
    ld de, THEN_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that THEN is IMMEDIATE (bit 6 set in length byte)
    ld a, (THEN_NFA)
    bit 6, a
    jr nz, then_immediate_ok
    ld hl, msg_then_not_immediate
    jp fail_with_msg
then_immediate_ok:

    ; --- TEST 2a: ZERO_BRANCH Not Taken (TOS != 0) ---
    ; Save initial DSP (IX)
    push ix
    pop hl
    ld (saved_dsp), hl

    ; Push anchor value $1234
    dec ix
    ld (ix+0), $12
    dec ix
    ld (ix+0), $34

    ; Push dummy value $5555 (new TOS after pop)
    dec ix
    ld (ix+0), $55
    dec ix
    ld (ix+0), $55

    ; TOS (DE) = 1 (true, branch NOT taken)
    ld de, 1

    ; Set up IP to run
    ld bc, ip_0branch_not_taken
    jp NEXT

test_0branch_taken:
    ; --- TEST 2b: ZERO_BRANCH Taken (TOS == 0) ---
    push ix
    pop hl
    ld (saved_dsp), hl

    ; Push anchor $1234
    dec ix
    ld (ix+0), $12
    dec ix
    ld (ix+0), $34

    ; Push dummy value $5555
    dec ix
    ld (ix+0), $55
    dec ix
    ld (ix+0), $55

    ; TOS (DE) = 0 (false, branch taken)
    ld de, 0

    ; Run
    ld bc, ip_0branch_taken
    jp NEXT

test_branch:
    ; --- TEST 3: BRANCH Unconditional ---
    ld bc, ip_branch
    jp NEXT

test_compilation:
    ; --- TEST 4: IF, ELSE, THEN Compilation Logic ---
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

    ; Run compilation macro list
    ld bc, ip_compilation
    jp NEXT

; -----------------------------------------------------------------------------
; Execution Stubs and Target Routines
; -----------------------------------------------------------------------------

target_taken_err:
    dw target_taken_err_code
target_taken_err_code:
    ld hl, err_msg_taken_err
    jp fail_with_msg

check_not_taken_stub:
    dw check_not_taken_code
check_not_taken_code:
    ; Check if TOS (DE) is $5555
    ld iy, err_tos_not_taken
    ld hl, $5555
    call assert_de_hl

    ; Check if DSP is saved_dsp - 2 (anchor remaining)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_not_taken
    call assert_ix_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    jp test_0branch_taken

target_taken_ok:
    dw target_taken_ok_code
target_taken_ok_code:
    ; Check if TOS (DE) is $5555
    ld iy, err_tos_taken
    ld hl, $5555
    call assert_de_hl

    ; Check if DSP is saved_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_taken
    call assert_ix_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    jp test_branch

check_taken_err:
    dw check_taken_err_code
check_taken_err_code:
    ld hl, err_msg_not_taken_err
    jp fail_with_msg

target_branch_ok:
    dw target_branch_ok_code
target_branch_ok_code:
    jp test_compilation

check_branch_err:
    dw check_branch_err_code
check_branch_err_code:
    ld hl, err_msg_branch_failed
    jp fail_with_msg

verify_compilation_results:
    dw verify_compilation_results_code
verify_compilation_results_code:
    ; Reset compilation STATE to 0
    xor a
    ld (USER_AREA_START + U_STATE), a

    ; Save final TOS
    ld (saved_tos), de

    ; 1. Verify DP has advanced by 8 bytes (2 for 0BRANCH CFA, 2 for offset, 2 for BRANCH CFA, 2 for offset)
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

    ; 2. Verify compiled CFA at initial_dp is ZERO_BRANCH_CFA
    ld hl, (saved_dp_val)
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, ZERO_BRANCH_CFA
    ld iy, err_cfa_if
    call assert_de_hl

    ; 3. Verify compiled target at initial_dp + 2 points to DP + 8 (after ELSE branch cell)
    ld hl, (saved_dp_val)
    inc hl
    inc hl
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
    ld iy, err_target_if
    call assert_de_hl

    ; 4. Verify compiled CFA at initial_dp + 4 is BRANCH_CFA
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
    ld iy, err_cfa_else
    call assert_de_hl

    ; 5. Verify compiled target at initial_dp + 6 points to DP + 8 (THEN target)
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
    ld a, l
    add a, 8
    ld l, a
    ld a, h
    adc a, 0
    ld h, a
    ld iy, err_target_else
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

    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0
saved_dp_val: dw 0

str_if:
    db 2
    db "IF"
str_else:
    db 4
    db "ELSE"
str_then:
    db 4
    db "THEN"

ip_0branch_not_taken:
    dw ZERO_BRANCH_CFA
    dw label_taken_err
    dw check_not_taken_stub

label_taken_err:
    dw target_taken_err

ip_0branch_taken:
    dw ZERO_BRANCH_CFA
    dw label_taken_ok
    dw check_taken_err

label_taken_ok:
    dw target_taken_ok

ip_branch:
    dw BRANCH_CFA
    dw label_branch_ok
    dw check_branch_err

label_branch_ok:
    dw target_branch_ok

ip_compilation:
    dw IF_CFA
    dw ELSE_CFA
    dw THEN_CFA
    dw verify_compilation_results

err_if_not_found:          db "Word 'IF' not found", 0
err_if_cfa_mismatch:       db "IF CFA mismatch", 0
msg_if_not_immediate:      db "IF is not IMMEDIATE", 0

err_else_not_found:        db "Word 'ELSE' not found", 0
err_else_cfa_mismatch:     db "ELSE CFA mismatch", 0
msg_else_not_immediate:    db "ELSE is not IMMEDIATE", 0

err_then_not_found:        db "Word 'THEN' not found", 0
err_then_cfa_mismatch:     db "THEN CFA mismatch", 0
msg_then_not_immediate:    db "THEN is not IMMEDIATE", 0

err_tos_not_taken:         db "TOS is incorrect after non-taken branch", 0
err_dsp_not_taken:         db "DSP is incorrect after non-taken branch", 0
err_tos_taken:             db "TOS is incorrect after taken branch", 0
err_dsp_taken:             db "DSP is incorrect after taken branch", 0

err_msg_taken_err:         db "ZERO_BRANCH was incorrectly taken", 0
err_msg_not_taken_err:     db "ZERO_BRANCH was not taken", 0
err_msg_branch_failed:     db "BRANCH was not taken", 0

err_dp_comp:               db "DP mismatch after compilation", 0
err_cfa_if:                db "IF compiled incorrect CFA (expected 0BRANCH)", 0
err_target_if:             db "IF compiled incorrect target", 0
err_cfa_else:              db "ELSE compiled incorrect CFA (expected BRANCH)", 0
err_target_else:           db "ELSE compiled incorrect target", 0
err_tos_comp:              db "TOS mismatch after compilation", 0
err_dsp_comp:              db "DSP mismatch after compilation", 0
