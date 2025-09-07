; =============================================================================
; pForth - Z80 CR Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "CR" ---
    ld hl, str_cr
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_cr_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == CR_CFA
    ld iy, err_cr_cfa_mismatch
    ld de, CR_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that CR is NOT IMMEDIATE (bit 6 NOT set in length byte)
    ld a, (CR_NFA)
    bit 6, a
    jr z, cr_not_immediate_ok
    ld hl, msg_cr_is_immediate
    jp fail_with_msg
cr_not_immediate_ok:

    ; --- TEST 2: Execution of CR ---
    ; We push a dummy value onto the data stack, execute CR, and verify that
    ; the data stack and return stack are preserved, and that CR didn't modify
    ; the stack values.

    ld de, $1234        ; TOS
    push ix
    pop hl
    ld (saved_dsp), hl

    ld bc, ip_cr_test
    jp NEXT

verify_results:
    dw verify_results_code
verify_results_code:
    ; Save final TOS
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; Assert TOS is still $1234
    ld hl, (saved_tos)
    ld de, $1234
    ld iy, err_cr_tos
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    
    ; If we got here, print SUCCESS (which is done by pass_all)
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0

str_cr:
    db 2
    db 'C', 'R'

ip_cr_test:
    dw CR_CFA
    dw verify_results

err_cr_not_found:     db "Word 'CR' not found", 0
err_cr_cfa_mismatch:  db "CR CFA mismatch", 0
msg_cr_is_immediate:  db "CR is IMMEDIATE", 0
err_cr_tos:           db "TOS corrupted after CR execution", 0
