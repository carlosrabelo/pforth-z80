; =============================================================================
; pForth - Z80 OVER Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "OVER" ---
    ld hl, str_over
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_over_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == OVER_CFA
    ld iy, err_over_cfa_mismatch
    ld de, OVER_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute OVER ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push $1111 (x1) onto data stack memory
    dec ix
    ld (ix+0), $11          ; high byte of $1111
    dec ix
    ld (ix+0), $11          ; low byte of $1111

    ; 3. Put value $2222 (x2) into TOS (DE)
    ld de, $2222
    
    ; 4. Set up IP to run OVER
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0

str_over:
    db 4
    db "OVER"

test_ip_list:
    dw OVER_CFA
    dw test_verify_over

test_verify_over:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) is now $1111 (x1)
    ld hl, $1111
    ld iy, err_tos_not_over
    call assert_de_hl

    ; 2. Verify that DSP (IX) is now initial_dsp - 4 (1 new word on memory stack)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the value in the middle of stack (ix+0) is $2222 (x2)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $2222
    ld iy, err_stack_middle_mismatch
    call assert_de_hl

    ; 4. Verify that the value at the bottom of stack (ix+2) is $1111 (x1)
    ld a, (ix+2)
    ld l, a
    ld a, (ix+3)
    ld h, a
    ld de, $1111
    ld iy, err_stack_bottom_mismatch
    call assert_de_hl

    jp pass_all

err_over_not_found:             db "Word 'OVER' not found", 0
err_over_cfa_mismatch:          db "OVER CFA mismatch", 0
err_tos_not_over:               db "TOS (DE) not updated with correct OVER element", 0
err_dsp_mismatch:               db "DSP (IX) not updated correctly by OVER", 0
err_stack_middle_mismatch:      db "Middle element on stack is not x2", 0
err_stack_bottom_mismatch:      db "Bottom element on stack is not x1", 0
