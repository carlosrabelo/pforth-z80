; =============================================================================
; pForth - Z80 SWAP Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "SWAP" ---
    ld hl, str_swap
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_swap_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == SWAP_CFA
    ld iy, err_swap_cfa_mismatch
    ld de, SWAP_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute SWAP ---
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
    
    ; 4. Set up IP to run SWAP
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0

str_swap:
    db 4
    db "SWAP"

test_ip_list:
    dw SWAP_CFA
    dw test_verify_swap

test_verify_swap:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) is now $1111 (x1)
    ld hl, $1111
    ld iy, err_tos_not_swapped
    call assert_de_hl

    ; 2. Verify that DSP (IX) is still initial_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the value in the memory stack is now $2222 (x2)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $2222
    ld iy, err_stack_value_not_swapped
    call assert_de_hl

    jp pass_all

err_swap_not_found:             db "Word 'SWAP' not found", 0
err_swap_cfa_mismatch:          db "SWAP CFA mismatch", 0
err_tos_not_swapped:            db "TOS (DE) not swapped with stack element", 0
err_dsp_mismatch:               db "DSP (IX) changed position unexpectedly by SWAP", 0
err_stack_value_not_swapped:    db "Stack memory element not swapped with TOS", 0
