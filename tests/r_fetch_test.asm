; =============================================================================
; pForth - Z80 R@ Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "R@" ---
    ld hl, str_r_fetch
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_r_fetch_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == R_FETCH_CFA
    ld iy, err_r_fetch_cfa_mismatch
    ld de, R_FETCH_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute R@ ---
    ; 1. Push $2222 (x) onto the return stack (SP)
    ld hl, $2222
    push hl

    ; 2. Save current DSP (IX) and RSP (SP)
    push ix
    pop hl
    ld (saved_dsp), hl

    ld hl, 0
    add hl, sp
    ld (saved_rsp), hl      ; saved_rsp points to the top of return stack ($2222)

    ; 3. Put value $1111 (y) into TOS (DE)
    ld de, $1111
    
    ; 4. Set up IP to run R@
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_rsp:
    dw 0

str_r_fetch:
    db 2
    db "R@"

test_ip_list:
    dw R_FETCH_CFA
    dw test_verify_r_fetch

test_verify_r_fetch:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) is now $2222 (x)
    ld hl, $2222
    ld iy, err_tos_not_updated
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 2 (old TOS pushed to stack memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the value in the data stack memory is $1111 (y)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $1111
    ld iy, err_stack_value_mismatch
    call assert_de_hl

    ; 4. Verify that SP (RSP) is still saved_rsp (return stack not modified by R@)
    ld hl, 0
    add hl, sp
    ld de, (saved_rsp)
    ld iy, err_rsp_mismatch
    call assert_de_hl

    ; 5. Pop and verify the value at return stack is still $2222
    pop hl
    ld de, $2222
    ld iy, err_rsp_value_corrupted
    call assert_de_hl

    jp pass_all

err_r_fetch_not_found:      db "Word 'R@' not found", 0
err_r_fetch_cfa_mismatch:   db "R@ CFA mismatch", 0
err_tos_not_updated:        db "TOS (DE) not updated with return stack element after R@", 0
err_dsp_mismatch:           db "DSP (IX) not updated correctly by R@", 0
err_stack_value_mismatch:   db "Data stack memory does not contain the old TOS", 0
err_rsp_mismatch:           db "RSP (SP) changed after R@", 0
err_rsp_value_corrupted:    db "Value on return stack was corrupted after R@", 0
