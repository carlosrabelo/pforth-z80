; =============================================================================
; pForth - Z80 LEAVE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "LEAVE" ---
    ld hl, str_leave
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_leave_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == LEAVE_CFA
    ld iy, err_leave_cfa_mismatch
    ld de, LEAVE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that LEAVE is NOT IMMEDIATE (bit 6 NOT set in length byte)
    ld a, (LEAVE_NFA)
    bit 6, a
    jr z, leave_not_immediate_ok
    ld hl, msg_leave_is_immediate
    jp fail_with_msg
leave_not_immediate_ok:

    ; --- TEST 2: Execution of LEAVE ---
    ; Loop from 0 to 10. Increment accumulator (starts at 0) on each iteration.
    ; If index I reaches 3, execute LEAVE.
    ; Expected final accumulator = 3.

    ; Save initial DSP
    push ix
    pop hl
    ld (saved_dsp), hl

    ; Run the loop execution test list
    ld bc, ip_leave_test
    jp NEXT

verify_results:
    dw verify_results_code
verify_results_code:
    ; Save final TOS
    ld h, d
    ld l, e
    ld (saved_tos), hl

    ; Verify final TOS is 3
    ld hl, (saved_tos)
    ld de, 3
    ld iy, err_leave_execution
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0

str_leave:
    db 5
    db 'L', 'E', 'A', 'V', 'E'

ip_leave_test:
    dw LIT_CFA
    dw 0                ; Initial accumulator
    dw LIT_CFA
    dw 10               ; limit
    dw LIT_CFA
    dw 0                ; start
    dw DO_RUN_CFA
label_loop_start:
    ; Body:
    dw I_CFA            ; Stack: accumulator, I
    dw LIT_CFA
    dw 3
    dw EQUALS_CFA       ; Stack: accumulator, (I == 3)
    dw ZERO_BRANCH_CFA
    dw label_not_three
    
    dw LEAVE_CFA
    dw BRANCH_CFA
    dw label_loop_end
    
label_not_three:
    dw LIT_CFA
    dw 1
    dw PLUS_CFA         ; Stack: accumulator + 1

label_loop_end:
    dw LOOP_RUN_CFA
    dw label_loop_start
    
    dw verify_results

err_leave_not_found:     db "Word 'LEAVE' not found", 0
err_leave_cfa_mismatch:  db "LEAVE CFA mismatch", 0
msg_leave_is_immediate:  db "LEAVE is IMMEDIATE", 0
err_leave_execution:     db "LEAVE execution failed to exit loop early", 0
