; =============================================================================
; pForth - Z80 +! (Plus Store) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "+!" ---
    ld hl, str_plus_store
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_plus_store_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == PLUS_STORE_CFA
    ld iy, err_plus_store_cfa_mismatch
    ld de, PLUS_STORE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute +! ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push operand $0123 (n) onto data stack
    dec ix
    ld (ix+0), $01          ; high byte of $0123
    dec ix
    ld (ix+0), $23          ; low byte of $0123

    ; 4. Put address of test_dest into TOS (DE)
    ld de, test_dest
    
    ; 5. Set up IP to run +!
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_tos:
    dw 0

test_dest:
    dw $1000

str_plus_store:
    db 2
    db "+!"

test_ip_list:
    dw PLUS_STORE_CFA
    dw test_verify_plus_store

test_verify_plus_store:
    dw test_verify_code

test_verify_code:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that the sum $1123 ($1000 + $0123) is stored in test_dest
    ld hl, (test_dest)
    ld de, $1123
    ld iy, err_value_not_summed
    call assert_de_hl

    ; 2. Verify that the saved TOS contains the anchor value $9999
    ld hl, (saved_tos)
    ld de, $9999
    ld iy, err_tos_incorrect
    call assert_de_hl

    ; 3. Verify that DSP (IX) returned to saved_dsp
    ld hl, (saved_dsp)
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    jp pass_all

err_plus_store_not_found:    db "Word '+!' not found", 0
err_plus_store_cfa_mismatch: db "+! CFA mismatch", 0
err_value_not_summed:        db "Value in test_dest was not correctly summed ($1123 expected)", 0
err_tos_incorrect:           db "TOS (DE) does not contain the anchor value $9999", 0
err_dsp_mismatch:            db "DSP (IX) not restored to saved_dsp after PLUS_STORE", 0
