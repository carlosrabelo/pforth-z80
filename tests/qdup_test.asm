; =============================================================================
; pForth - Z80 ?DUP Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "?DUP" ---
    ld hl, str_qdup
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_qdup_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == QDUP_CFA
    ld iy, err_qdup_cfa_mismatch
    ld de, QDUP_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute ?DUP with non-zero ($1234) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Put value $1234 into TOS (DE)
    ld de, $1234
    
    ; 3. Set up IP to run ?DUP and then verify_nonzero
    ld bc, ip_list_nonzero
    jp NEXT

verify_nonzero:
    ; 1. Verify that TOS (DE) is still $1234
    ld hl, $1234
    ld iy, err_nonzero_tos_changed
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_nonzero_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the value in the memory stack is $1234
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $1234
    ld iy, err_nonzero_stack_mismatch
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 3: Execute ?DUP with zero ($0000) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Put value $0000 into TOS (DE)
    ld de, $0000
    
    ; 3. Set up IP to run ?DUP and then verify_zero
    ld bc, ip_list_zero
    jp NEXT

verify_zero:
    ; 1. Verify that TOS (DE) is still $0000
    ld hl, $0000
    ld iy, err_zero_tos_changed
    call assert_de_hl

    ; 2. Verify that DSP (IX) is still initial_dsp
    ld hl, (saved_dsp)
    ld iy, err_zero_dsp_mismatch
    call assert_ix_hl

    jp pass_all

saved_dsp:
    dw 0

str_qdup:
    db 4
    db "?DUP"

ip_list_nonzero:
    dw QDUP_CFA
    dw verify_nonzero_stub

verify_nonzero_stub:
    dw verify_nonzero_code

verify_nonzero_code:
    jp verify_nonzero

ip_list_zero:
    dw QDUP_CFA
    dw verify_zero_stub

verify_zero_stub:
    dw verify_zero_code

verify_zero_code:
    jp verify_zero

err_qdup_not_found:             db "Word '?DUP' not found", 0
err_qdup_cfa_mismatch:          db "?DUP CFA mismatch", 0
err_nonzero_tos_changed:        db "TOS changed after ?DUP (nonzero)", 0
err_nonzero_dsp_mismatch:       db "DSP not updated correctly by ?DUP (nonzero)", 0
err_nonzero_stack_mismatch:     db "Value on stack mismatch after ?DUP (nonzero)", 0
err_zero_tos_changed:           db "TOS changed after ?DUP (zero)", 0
err_zero_dsp_mismatch:          db "DSP changed after ?DUP (zero)", 0
