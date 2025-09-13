; =============================================================================
; pForth - Z80 TYPE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "TYPE" ---
    ld hl, str_type
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_type_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == TYPE_CFA
    ld iy, err_type_cfa_mismatch
    ld de, TYPE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that TYPE is NOT IMMEDIATE (bit 6 NOT set in length byte)
    ld a, (TYPE_NFA)
    bit 6, a
    jr z, type_not_immediate_ok
    ld hl, msg_type_is_immediate
    jp fail_with_msg
type_not_immediate_ok:

    ; --- TEST 2: Execution of TYPE with positive count (5) ---
    ld de, $5555        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_type_test_pos
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
    ld iy, err_type_tos_pos
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 3: Execution of TYPE with zero count ---
    ld de, $6666        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_type_test_zero
    jp NEXT

verify_zero_results:
    dw verify_zero_results_code
verify_zero_results_code:
    ld h, d
    ld l, e
    ld (saved_tos), hl
    
    ; Assert TOS is still $6666
    ld hl, (saved_tos)
    ld de, $6666
    ld iy, err_type_tos_zero
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; --- TEST 4: Execution of TYPE with negative count (-5) ---
    ld de, $7777        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_type_test_neg
    jp NEXT

verify_neg_results:
    dw verify_neg_results_code
verify_neg_results_code:
    ld h, d
    ld l, e
    ld (saved_tos), hl
    
    ; Assert TOS is still $7777
    ld hl, (saved_tos)
    ld de, $7777
    ld iy, err_type_tos_neg
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0

str_type:
    db 4
    db 'T', 'Y', 'P', 'E'

test_string:
    db 'H', 'e', 'l', 'l', 'o'

ip_type_test_pos:
    dw LIT_CFA
    dw test_string
    dw LIT_CFA
    dw 5
    dw TYPE_CFA
    dw verify_pos_results

ip_type_test_zero:
    dw LIT_CFA
    dw test_string
    dw LIT_CFA
    dw 0
    dw TYPE_CFA
    dw verify_zero_results

ip_type_test_neg:
    dw LIT_CFA
    dw test_string
    dw LIT_CFA
    dw -5
    dw TYPE_CFA
    dw verify_neg_results

err_type_not_found:     db "Word 'TYPE' not found", 0
err_type_cfa_mismatch:  db "TYPE CFA mismatch", 0
msg_type_is_immediate:  db "TYPE is IMMEDIATE", 0
err_type_tos_pos:       db "TOS corrupted after TYPE (pos) execution", 0
err_type_tos_zero:      db "TOS corrupted after TYPE (zero) execution", 0
err_type_tos_neg:       db "TOS corrupted after TYPE (neg) execution", 0
