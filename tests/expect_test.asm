; =============================================================================
; pForth - Z80 EXPECT Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "EXPECT" ---
    ld hl, str_expect
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_expect_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == EXPECT_CFA
    ld iy, err_expect_cfa_mismatch
    ld de, EXPECT_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that EXPECT is NOT IMMEDIATE
    ld a, (EXPECT_NFA)
    bit 6, a
    jr z, expect_not_immediate_ok
    ld hl, msg_expect_is_immediate
    jp fail_with_msg
expect_not_immediate_ok:

    ; --- TEST 2: Execution of EXPECT with limit 5 (input is "abc\r") ---
    ld de, $5555        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_expect_test_1
    jp NEXT

verify_results_1:
    dw verify_results_1_code
verify_results_1_code:
    ld h, d
    ld l, e
    ld (saved_tos), hl
    
    ; Assert TOS is still $5555
    ld hl, (saved_tos)
    ld de, $5555
    ld iy, err_expect_tos_1
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; Assert SPAN == 3
    ld hl, (USER_AREA_START + U_SPAN)
    ld de, 3
    ld iy, err_expect_span_1
    call assert_de_hl

    ; Assert buffer content
    ld a, (test_buffer)
    cp 'a'
    jr nz, fail_buffer_1
    ld a, (test_buffer+1)
    cp 'b'
    jr nz, fail_buffer_1
    ld a, (test_buffer+2)
    cp 'c'
    jr nz, fail_buffer_1
    ld a, (test_buffer+3)
    cp 0
    jr nz, fail_buffer_1
    jr buffer_1_ok

fail_buffer_1:
    ld hl, err_expect_buf_1
    jp fail_with_msg

buffer_1_ok:

    ; --- TEST 3: Execution of EXPECT with limit 1 (input is "xy\r") ---
    ld de, $6666        ; dummy TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_expect_test_2
    jp NEXT

verify_results_2:
    dw verify_results_2_code
verify_results_2_code:
    ld h, d
    ld l, e
    ld (saved_tos), hl
    
    ; Assert TOS is still $6666
    ld hl, (saved_tos)
    ld de, $6666
    ld iy, err_expect_tos_2
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)

    ; Assert SPAN == 1
    ld hl, (USER_AREA_START + U_SPAN)
    ld de, 1
    ld iy, err_expect_span_2
    call assert_de_hl

    ; Assert buffer content (should only have 'x', 'y' was ignored)
    ld a, (test_buffer2)
    cp 'x'
    jr nz, fail_buffer_2
    ld a, (test_buffer2+1)
    cp 0
    jr nz, fail_buffer_2
    jr buffer_2_ok

fail_buffer_2:
    ld hl, err_expect_buf_2
    jp fail_with_msg

buffer_2_ok:
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables, Buffers & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0

str_expect:
    db 6
    db 'E', 'X', 'P', 'E', 'C', 'T'

test_buffer:
    ds 10, 0        ; Define 10 bytes initialized to 0

test_buffer2:
    ds 10, 0        ; Define 10 bytes initialized to 0

ip_expect_test_1:
    dw LIT_CFA
    dw test_buffer
    dw LIT_CFA
    dw 5
    dw EXPECT_CFA
    dw verify_results_1

ip_expect_test_2:
    dw LIT_CFA
    dw test_buffer2
    dw LIT_CFA
    dw 1
    dw EXPECT_CFA
    dw verify_results_2

err_expect_not_found:     db "Word 'EXPECT' not found", 0
err_expect_cfa_mismatch:  db "EXPECT CFA mismatch", 0
msg_expect_is_immediate:  db "EXPECT is IMMEDIATE", 0
err_expect_tos_1:         db "TOS corrupted after EXPECT 1", 0
err_expect_tos_2:         db "TOS corrupted after EXPECT 2", 0
err_expect_span_1:        db "SPAN value incorrect after EXPECT 1", 0
err_expect_span_2:        db "SPAN value incorrect after EXPECT 2", 0
err_expect_buf_1:         db "Buffer content mismatch after EXPECT 1", 0
err_expect_buf_2:         db "Buffer content mismatch after EXPECT 2", 0
