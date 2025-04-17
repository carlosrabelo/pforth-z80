; =============================================================================
; pForth - Z80 DUP Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "DUP" ---
    ld hl, str_dup
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_dup_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == DUP_CFA
    ld iy, err_dup_cfa_mismatch
    ld de, DUP_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute DUP ---
    ; 1. Put value $1234 into TOS (DE)
    ld de, $1234
    
    ; 2. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 3. Set up IP to run DUP
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0

str_dup:
    db 3
    db "DUP"

test_ip_list:
    dw DUP_CFA
    dw test_verify_dup

test_verify_dup:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) is still $1234
    ld hl, $1234
    ld iy, err_tos_changed
    call assert_de_hl

    ; 2. Verify that the new DSP (IX) is initial_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl                  ; HL = expected new DSP
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the value written to the data stack is correct ($1234)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $1234
    ld iy, err_stack_value_mismatch
    call assert_de_hl

    jp pass_all

err_dup_not_found:          db "Word 'DUP' not found", 0
err_dup_cfa_mismatch:       db "DUP CFA mismatch", 0
err_tos_changed:            db "TOS changed after DUP", 0
err_dsp_mismatch:           db "DSP not updated correctly by DUP", 0
err_stack_value_mismatch:   db "Value on stack mismatch after DUP", 0
