; =============================================================================
; pForth - Z80 I Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "I" ---
    ld hl, str_i
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_i_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == I_CFA
    ld iy, err_i_cfa_mismatch
    ld de, I_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Verify that I is NOT IMMEDIATE (bit 6 NOT set in length byte)
    ld a, (I_NFA)
    bit 6, a
    jr z, i_not_immediate_ok
    ld hl, msg_i_is_immediate
    jp fail_with_msg
i_not_immediate_ok:

    ; --- TEST 2: Execution of I ---
    ; We run a loop from 0 to 3, and add the loop index I to our accumulator (initially 0).
    ; Formula: accum = 0; DO index from 0 to 3: accum = accum + I; LOOP.
    ; Expected final accumulator = 0 + 1 + 2 = 3.

    ; Save initial DSP
    push ix
    pop hl
    ld (saved_dsp), hl

    ; Run the loop execution test list
    ld bc, ip_i_test
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
    ld iy, err_i_execution
    call assert_de_hl

    ; Restore DSP
    ld ix, (saved_dsp)
    jp pass_all

; -----------------------------------------------------------------------------
; Static Variables & Strings
; -----------------------------------------------------------------------------
saved_dsp:    dw 0
saved_tos:    dw 0

str_i:
    db 1
    db 'I'

ip_i_test:
    dw LIT_CFA
    dw 0                ; Initial accumulator
    dw LIT_CFA
    dw 3                ; limit
    dw LIT_CFA
    dw 0                ; start
    dw DO_RUN_CFA
label_loop_start:
    ; Body: accumulator = accumulator + I
    dw I_CFA            ; Put I onto stack. TOS becomes I, accumulator is pushed.
    dw PLUS_CFA         ; Add accumulator + I, TOS becomes sum.
    ; Loop
    dw LOOP_RUN_CFA
    dw label_loop_start
    
    dw verify_results

err_i_not_found:     db "Word 'I' not found", 0
err_i_cfa_mismatch:  db "I CFA mismatch", 0
msg_i_is_immediate:  db "I is IMMEDIATE", 0
err_i_execution:     db "I execution index sum is incorrect", 0
