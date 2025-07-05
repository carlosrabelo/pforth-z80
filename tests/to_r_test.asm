; =============================================================================
; pForth - Z80 >R Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word ">R" ---
    ld hl, str_to_r
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_to_r_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == TO_R_CFA
    ld iy, err_to_r_cfa_mismatch
    ld de, TO_R_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute >R ---
    ; 1. Save current DSP (IX) and RSP (SP) to static variables
    push ix
    pop hl
    ld (saved_dsp), hl

    ld hl, 0
    add hl, sp
    ld (saved_rsp), hl

    ; 2. Push $1111 (x1) onto data stack memory
    dec ix
    ld (ix+0), $11          ; high byte of $1111
    dec ix
    ld (ix+0), $11          ; low byte of $1111

    ; 3. Put value $2222 (x2) into TOS (DE)
    ld de, $2222
    
    ; 4. Set up IP to run >R
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_rsp:
    dw 0

str_to_r:
    db 2
    db ">R"

test_ip_list:
    dw TO_R_CFA
    dw test_verify_to_r

test_verify_to_r:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) is now $1111 (x1)
    ld hl, $1111
    ld iy, err_tos_not_updated
    call assert_de_hl

    ; 2. Verify that DSP (IX) returned to saved_dsp
    ld hl, (saved_dsp)
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Pop the value from return stack (SP) into HL and assert it is $2222 (x2)
    pop hl
    ld de, $2222
    ld iy, err_rsp_value_mismatch
    call assert_de_hl

    ; 4. Verify that SP (RSP) returned to saved_rsp (after the POP)
    ld hl, 0
    add hl, sp
    ld de, (saved_rsp)
    ld iy, err_rsp_not_restored
    call assert_de_hl

    jp pass_all

err_to_r_not_found:     db "Word '>R' not found", 0
err_to_r_cfa_mismatch:  db ">R CFA mismatch", 0
err_tos_not_updated:    db "TOS (DE) not updated with data stack element after >R", 0
err_dsp_mismatch:       db "DSP (IX) not updated correctly by >R", 0
err_rsp_value_mismatch: db "Value on return stack (RSP) is incorrect", 0
err_rsp_not_restored:   db "RSP (SP) not restored correctly after pop", 0
