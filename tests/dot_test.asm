; =============================================================================
; pForth - Z80 DOT ( . ) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "." ---
    ld hl, str_dot
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_dot_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == DOT_CFA
    ld iy, err_dot_cfa_mismatch
    ld de, DOT_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that DOT is NOT IMMEDIATE
    ld a, (DOT_NFA)
    bit 6, a
    jr z, dot_not_immediate_ok
    ld hl, msg_dot_is_immediate
    jp fail_with_msg
dot_not_immediate_ok:

    ; --- TEST 2: Execution of DOT with positive number (123) ---
    ld de, $5555        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_dot_test_pos
    jp NEXT

verify_pos_results:
    dw verify_pos_results_code
verify_pos_results_code:
    ld h, d
    ld l, e
    ld (saved_tos), hl
    
    ; Assert TOS is still $5555
    ld hl, (saved_tos)
    ld de, $5555
    ld iy, err_dot_tos_pos
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 3: Execution of DOT with negative number (-456) ---
    ld de, $6666        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_dot_test_neg
    jp NEXT

verify_neg_results:
    dw verify_neg_results_code
verify_neg_results_code:
    ld h, d
    ld l, e
    ld (saved_tos), hl
    
    ; Assert TOS is still $6666
    ld hl, (saved_tos)
    ld de, $6666
    ld iy, err_dot_tos_neg
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 4: Execution of DOT with zero (0) ---
    ld de, $7777        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_dot_test_zero
    jp NEXT

verify_zero_results:
    dw verify_zero_results_code
verify_zero_results_code:
    ld h, d
    ld l, e
    ld (saved_tos), hl
    
    ; Assert TOS is still $7777
    ld hl, (saved_tos)
    ld de, $7777
    ld iy, err_dot_tos_zero
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0

str_dot:
    db 1
    db '.'

ip_dot_test_pos:
    dw LIT_CFA
    dw 123
    dw DOT_CFA
    dw verify_pos_results

ip_dot_test_neg:
    dw LIT_CFA
    dw -456
    dw DOT_CFA
    dw verify_neg_results

ip_dot_test_zero:
    dw LIT_CFA
    dw 0
    dw DOT_CFA
    dw verify_zero_results

err_dot_not_found:     db "Word '.' not found", 0
err_dot_cfa_mismatch:  db "DOT CFA mismatch", 0
msg_dot_is_immediate:  db "DOT is IMMEDIATE", 0
err_dot_tos_pos:       db "TOS corrupted after DOT (pos) execution", 0
err_dot_tos_neg:       db "TOS corrupted after DOT (neg) execution", 0
err_dot_tos_zero:      db "TOS corrupted after DOT (zero) execution", 0
