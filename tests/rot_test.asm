; =============================================================================
; pForth - Z80 ROT Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "ROT" ---
    ld hl, str_rot
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_rot_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == ROT_CFA
    ld iy, err_rot_cfa_mismatch
    ld de, ROT_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute ROT ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push $1111 (x1) onto data stack memory
    dec ix
    ld (ix+0), $11          ; high byte of $1111
    dec ix
    ld (ix+0), $11          ; low byte of $1111

    ; 3. Push $2222 (x2) onto data stack memory
    dec ix
    ld (ix+0), $22          ; high byte of $2222
    dec ix
    ld (ix+0), $22          ; low byte of $2222

    ; 4. Put value $3333 (x3) into TOS (DE)
    ld de, $3333
    
    ; 5. Set up IP to run ROT
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0

str_rot:
    db 3
    db "ROT"

test_ip_list:
    dw ROT_CFA
    dw test_verify_rot

test_verify_rot:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) is now $1111 (x1)
    ld hl, $1111
    ld iy, err_tos_not_rot
    call assert_de_hl

    ; 2. Verify that DSP (IX) is still initial_dsp - 4 (2 elements in memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the value at the top of memory stack (ix+0) is $3333 (x3)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $3333
    ld iy, err_stack_middle_mismatch
    call assert_de_hl

    ; 4. Verify that the value at the bottom of memory stack (ix+2) is $2222 (x2)
    ld a, (ix+2)
    ld l, a
    ld a, (ix+3)
    ld h, a
    ld de, $2222
    ld iy, err_stack_bottom_mismatch
    call assert_de_hl

    jp pass_all

err_rot_not_found:              db "Word 'ROT' not found", 0
err_rot_cfa_mismatch:           db "ROT CFA mismatch", 0
err_tos_not_rot:                db "TOS (DE) not updated with correct ROT element (x1)", 0
err_dsp_mismatch:               db "DSP (IX) not at expected offset after ROT", 0
err_stack_middle_mismatch:      db "Middle element on stack (x3) is incorrect", 0
err_stack_bottom_mismatch:      db "Bottom element on stack (x2) is incorrect", 0
