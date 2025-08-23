; =============================================================================
; pForth - Z80 LITERAL Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "LITERAL" ---
    ld hl, str_literal
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_literal_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == LITERAL_CFA
    ld iy, err_literal_cfa_mismatch
    ld de, LITERAL_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Verify that LITERAL is IMMEDIATE (bit 6 set in length byte) ---
    ld a, (LITERAL_NFA)
    bit 6, a
    jr nz, immediate_flag_ok

    ; Bit 6 is not set
    ld hl, msg_immediate_failed
    jp fail_with_msg

immediate_flag_ok:

    ; --- TEST 3: Execute LITERAL with value $5A5A ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push dummy value $5555 (to become the new TOS after LITERAL consumes $5A5A)
    dec ix
    ld (ix+0), $55          ; high byte of $5555
    dec ix
    ld (ix+0), $55          ; low byte of $5555

    ; 4. Read initial DP value and save it
    ld hl, (USER_AREA_START + U_DP)
    ld (saved_dp_val), hl

    ; 5. Put literal value $5A5A in TOS (DE)
    ld de, $5A5A
    
    ; 6. Set up IP to run LITERAL and then verify_compilation
    ld bc, ip_list_literal
    jp NEXT

verify_compilation:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that the new DP value is initial_dp + 4
    ld hl, (USER_AREA_START + U_DP)
    ld de, (saved_dp_val)
    inc de
    inc de
    inc de
    inc de                      ; DE = saved_dp_val + 4
    ld iy, err_dp_incorrect
    call assert_de_hl

    ; 2. Verify that the value compiled at original DP is LIT_CFA
    ld hl, (saved_dp_val)
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a                     ; DE = compiled CFA value
    ld hl, LIT_CFA
    ld iy, err_compiled_cfa_incorrect
    call assert_de_hl

    ; 3. Verify that the value compiled at original DP + 2 is $5A5A
    ld hl, (saved_dp_val)
    inc hl
    inc hl                      ; HL = original DP + 2
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a                     ; DE = compiled literal value
    ld hl, $5A5A
    ld iy, err_compiled_val_incorrect
    call assert_de_hl

    ; 4. Verify that TOS (DE) contains $5555 (the popped value)
    ld hl, (saved_tos)
    ld de, $5555
    ld iy, err_tos_incorrect
    call assert_de_hl

    ; 5. Verify that DSP (IX) is initial_dsp - 2 (only anchor remains in stack memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 6. Verify that the anchor value $9999 remains on the stack
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

str_literal:
    db 7
    db "LITERAL"

ip_list_literal:
    dw LITERAL_CFA
    dw verify_compilation_stub

verify_compilation_stub:
    dw verify_compilation_code

verify_compilation_code:
    jp verify_compilation

err_literal_not_found:            db "Word 'LITERAL' not found", 0
err_literal_cfa_mismatch:         db "LITERAL CFA mismatch", 0
msg_immediate_failed:             db "LITERAL is not marked as IMMEDIATE", 0
err_dp_incorrect:                 db "New DP value after LITERAL is incorrect", 0
err_compiled_cfa_incorrect:       db "Compiled CFA value is not LIT_CFA", 0
err_compiled_val_incorrect:       db "Compiled literal value is not $5A5A", 0
err_tos_incorrect:                db "popped TOS is incorrect (expected $5555)", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
