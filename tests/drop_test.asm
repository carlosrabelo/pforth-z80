; =============================================================================
; pForth - Z80 DROP Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "DROP" ---
    ld hl, str_drop
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_drop_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == DROP_CFA
    ld iy, err_drop_cfa_mismatch
    ld de, DROP_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute DROP ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push $1111 onto data stack memory
    dec ix
    ld (ix+0), $11          ; high byte of $1111
    dec ix
    ld (ix+0), $11          ; low byte of $1111

    ; 3. Put value $2222 into TOS (DE)
    ld de, $2222
    
    ; 4. Set up IP to run DROP
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0

str_drop:
    db 4
    db "DROP"

test_ip_list:
    dw DROP_CFA
    dw test_verify_drop

test_verify_drop:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) is now $1111
    ld hl, $1111
    ld iy, err_tos_not_updated
    call assert_de_hl

    ; 2. Verify that DSP (IX) has returned to saved_dsp
    ld hl, (saved_dsp)
    ld iy, err_dsp_not_restored
    call assert_ix_hl

    jp pass_all

err_drop_not_found:     db "Word 'DROP' not found", 0
err_drop_cfa_mismatch:  db "DROP CFA mismatch", 0
err_tos_not_updated:    db "TOS not updated with element from stack", 0
err_dsp_not_restored:   db "DSP not restored correctly by DROP", 0
