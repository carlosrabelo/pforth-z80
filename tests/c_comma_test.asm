; =============================================================================
; pForth - Z80 C, Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "C," ---
    ld hl, str_c_comma
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_c_comma_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == C_COMMA_CFA
    ld iy, err_c_comma_cfa_mismatch
    ld de, C_COMMA_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute C, (store $AB) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push dummy value $5555 (to become the new TOS after C, consumes the char)
    dec ix
    ld (ix+0), $55          ; high byte of $5555
    dec ix
    ld (ix+0), $55          ; low byte of $5555

    ; 4. Read initial DP value and save it
    ld hl, (USER_AREA_START + U_DP)
    ld (saved_dp_val), hl

    ; 5. Put char value $AB in TOS (DE)
    ld de, $00AB
    
    ; 6. Set up IP to run C, and then verify_c_comma
    ld bc, ip_list_c_comma
    jp NEXT

verify_c_comma:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that the new DP value is initial_dp + 1
    ld hl, (USER_AREA_START + U_DP)
    ld de, (saved_dp_val)
    inc de                      ; DE = saved_dp_val + 1
    ld iy, err_dp_incorrect
    call assert_de_hl

    ; 2. Verify that the value stored at original DP is $AB
    ld hl, (saved_dp_val)
    ld a, (hl)
    ld l, a
    ld h, 0
    ld de, $00AB
    ld iy, err_stored_value_incorrect
    call assert_de_hl

    ; 3. Verify that TOS (DE) contains $5555 (the popped value)
    ld hl, (saved_tos)
    ld de, $5555
    ld iy, err_tos_incorrect
    call assert_de_hl

    ; 4. Verify that DSP (IX) is initial_dsp - 2 (only anchor remains in stack memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 5. Verify that the anchor value $9999 remains on the stack
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    jp pass_all

saved_dsp:
    dw 0
saved_tos:
    dw 0
saved_dp_val:
    dw 0

str_c_comma:
    db 2
    db "C,"

ip_list_c_comma:
    dw C_COMMA_CFA
    dw verify_c_comma_stub

verify_c_comma_stub:
    dw verify_c_comma_code

verify_c_comma_code:
    jp verify_c_comma

err_c_comma_not_found:            db "Word 'C,' not found", 0
err_c_comma_cfa_mismatch:         db "C, CFA mismatch", 0
err_dp_incorrect:                 db "New DP value after C, is incorrect", 0
err_stored_value_incorrect:       db "Value stored by C, is incorrect", 0
err_tos_incorrect:                db "popped TOS is incorrect (expected $5555)", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
