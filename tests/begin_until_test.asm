; =============================================================================
; pForth - Z80 BEGIN, UNTIL Primitives Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1a: Find word "BEGIN" ---
    ld hl, str_begin
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_begin_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == BEGIN_CFA
    ld iy, err_begin_cfa_mismatch
    ld de, BEGIN_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that BEGIN is IMMEDIATE (bit 6 set in length byte)
    ld a, (BEGIN_NFA)
    bit 6, a
    jr nz, begin_immediate_ok
    ld hl, msg_begin_not_immediate
    jp fail_with_msg
begin_immediate_ok:

    ; --- TEST 1b: Find word "UNTIL" ---
    ld hl, str_until
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_until_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == UNTIL_CFA
    ld iy, err_until_cfa_mismatch
    ld de, UNTIL_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that UNTIL is IMMEDIATE (bit 6 set in length byte)
    ld a, (UNTIL_NFA)
    bit 6, a
    jr nz, until_immediate_ok
    ld hl, msg_until_not_immediate
    jp fail_with_msg
until_immediate_ok:

    ; --- TEST 2: BEGIN & UNTIL Compilation Logic ---
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

    ; Run compilation macro list: BEGIN, then UNTIL
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

    ; 1. Verify DP has advanced by 4 bytes (2 for 0BRANCH CFA, 2 for dest address)
    ld hl, (USER_AREA_START + U_DP)
    ld de, (saved_dp_val)
    ld a, e
    add a, 4
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
    ld iy, err_cfa_until
    call assert_de_hl

    ; 3. Verify compiled target at initial_dp + 2 points to initial_dp
    ld hl, (saved_dp_val)
    inc hl
    inc hl
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a
    ld hl, (saved_dp_val)
    ld iy, err_target_until
    call assert_de_hl

    ; 4. Verify final TOS is the original TOS ($1111)
    ld hl, (saved_tos)
    ld de, $1111
    ld iy, err_tos_comp
    call assert_de_hl

    ; 5. Verify DSP is original_dsp - 2 (anchor remains)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_comp
    call assert_ix_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 3: Executing BEGIN UNTIL Loop in Runtime ---
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

    ; 1. Verify final TOS is 0 (remaining loop counter)
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

str_begin:
    db 5
    db "BEGIN"
str_until:
    db 5
    db "UNTIL"

ip_compilation:
    dw BEGIN_CFA
    dw UNTIL_CFA
    dw verify_compilation_results

ip_loop_test:
    ; 1. Push loop counter 3
    dw LIT_CFA
    dw 3
    
label_begin:
    ; Decrement loop counter by 1
    dw LIT_CFA
    dw 1
    dw MINUS_CFA
    
    ; Duplicate and check if 0
    dw DUP_CFA
    dw ZERO_EQUALS_CFA
    
    ; Loop condition branch
    dw ZERO_BRANCH_CFA
    dw label_begin
    
    ; Verify execution
    dw verify_loop_results

err_begin_not_found:       db "Word 'BEGIN' not found", 0
err_begin_cfa_mismatch:    db "BEGIN CFA mismatch", 0
msg_begin_not_immediate:   db "BEGIN is not IMMEDIATE", 0

err_until_not_found:       db "Word 'UNTIL' not found", 0
err_until_cfa_mismatch:    db "UNTIL CFA mismatch", 0
msg_until_not_immediate:   db "UNTIL is not IMMEDIATE", 0

err_dp_comp:               db "DP mismatch after compilation", 0
err_cfa_until:             db "UNTIL compiled incorrect CFA (expected 0BRANCH)", 0
err_target_until:          db "UNTIL compiled incorrect target destination", 0
err_tos_comp:              db "TOS mismatch after compilation", 0
err_dsp_comp:              db "DSP mismatch after compilation", 0

err_loop_tos:              db "Loop final TOS is incorrect", 0
err_loop_dsp:              db "Loop final DSP is incorrect", 0
