; =============================================================================
; pForth - Z80 ALLOT Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "ALLOT" ---
    ld hl, str_allot
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_allot_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == ALLOT_CFA
    ld iy, err_allot_cfa_mismatch
    ld de, ALLOT_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute ALLOT (allocate 100 bytes) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push dummy value $5555 (to become the new TOS after ALLOT consumes 100)
    dec ix
    ld (ix+0), $55          ; high byte of $5555
    dec ix
    ld (ix+0), $55          ; low byte of $5555

    ; 4. Read initial DP value and save it
    ld hl, (USER_AREA_START + U_DP)
    ld (saved_dp_val), hl

    ; 5. Put allocation size 100 in TOS (DE)
    ld de, 100
    
    ; 6. Set up IP to run ALLOT and then verify_allot
    ld bc, ip_list_allot
    jp NEXT

verify_allot:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that the new DP value is initial_dp + 100
    ld hl, (USER_AREA_START + U_DP)
    ld de, (saved_dp_val)
    ld a, 100
    add a, e
    ld e, a
    ld a, 0
    adc a, d
    ld d, a                     ; DE = saved_dp_val + 100
    ld iy, err_dp_incorrect
    call assert_de_hl

    ; 2. Verify that TOS (DE) contains $5555 (the popped value)
    ld hl, (saved_tos)
    ld de, $5555
    ld iy, err_tos_incorrect
    call assert_de_hl

    ; 3. Verify that DSP (IX) is initial_dsp - 2 (only anchor remains in stack memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 4. Verify that the anchor value $9999 remains on the stack
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

str_allot:
    db 5
    db "ALLOT"

ip_list_allot:
    dw ALLOT_CFA
    dw verify_allot_stub

verify_allot_stub:
    dw verify_allot_code

verify_allot_code:
    jp verify_allot

err_allot_not_found:              db "Word 'ALLOT' not found", 0
err_allot_cfa_mismatch:             db "ALLOT CFA mismatch", 0
err_dp_incorrect:                 db "New DP value after ALLOT is incorrect", 0
err_tos_incorrect:                db "popped TOS is incorrect (expected $5555)", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
