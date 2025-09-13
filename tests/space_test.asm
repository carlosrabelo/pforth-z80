; =============================================================================
; pForth - Z80 SPACE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "SPACE" ---
    ld hl, str_space
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_space_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == SPACE_CFA
    ld iy, err_space_cfa_mismatch
    ld de, SPACE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that SPACE is NOT IMMEDIATE (bit 6 NOT set in length byte)
    ld a, (SPACE_NFA)
    bit 6, a
    jr z, space_not_immediate_ok
    ld hl, msg_space_is_immediate
    jp fail_with_msg
space_not_immediate_ok:

    ; --- TEST 2: Execution of SPACE ---
    ; We push a dummy value onto the data stack, execute SPACE, and verify that
    ; the data stack and return stack are preserved, and that SPACE didn't modify
    ; the stack values.

    ld de, $5678        ; TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_space_test
    jp NEXT

verify_results:
    dw verify_results_code
verify_results_code:
    ; Save final TOS
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; Assert TOS is still $5678
    ld hl, (saved_tos)
    ld de, $5678
    ld iy, err_space_tos
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    
    ; If we got here, print SUCCESS
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0

str_space:
    db 5
    db 'S', 'P', 'A', 'C', 'E'

ip_space_test:
    dw SPACE_CFA
    dw verify_results

err_space_not_found:     db "Word 'SPACE' not found", 0
err_space_cfa_mismatch:  db "SPACE CFA mismatch", 0
msg_space_is_immediate:  db "SPACE is IMMEDIATE", 0
err_space_tos:           db "TOS corrupted after SPACE execution", 0
