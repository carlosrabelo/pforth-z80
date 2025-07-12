; =============================================================================
; pForth - Z80 C! (Byte Store) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "C!" ---
    ld hl, str_c_store
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_c_store_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == C_STORE_CFA
    ld iy, err_c_store_cfa_mismatch
    ld de, C_STORE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute C! ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push byte value $55 (c) onto data stack (as 16-bit $0055)
    dec ix
    ld (ix+0), $00          ; high byte of $0055
    dec ix
    ld (ix+0), $55          ; low byte of $0055

    ; 4. Put address of test_dest into TOS (DE)
    ld de, test_dest
    
    ; 5. Set up IP to run C!
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_tos:
    dw 0

test_dest:
    dw $FFFF

str_c_store:
    db 2
    db "C!"

test_ip_list:
    dw C_STORE_CFA
    dw test_verify_c_store

test_verify_c_store:
    dw test_verify_code

test_verify_code:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that the byte $55 was correctly stored in test_dest (low byte)
    ; Since test_dest was initialized to $FFFF, it should now contain $FF55
    ld hl, (test_dest)
    ld de, $FF55
    ld iy, err_value_not_stored
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

err_c_store_not_found:    db "Word 'C!' not found", 0
err_c_store_cfa_mismatch: db "C! CFA mismatch", 0
err_value_not_stored:   db "Byte $55 was not correctly stored at test_dest (or overwrote high byte)", 0
err_tos_incorrect:      db "TOS (DE) does not contain the anchor value $9999", 0
err_dsp_mismatch:        db "DSP (IX) not restored to saved_dsp after C_STORE", 0
