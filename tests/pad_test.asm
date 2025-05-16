; =============================================================================
; pForth - Z80 PAD Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "PAD" ---
    ld hl, str_pad
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_pad_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == PAD_CFA
    ld iy, err_pad_cfa_mismatch
    ld de, PAD_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute PAD ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Read DP value and calculate expected PAD value (DP + 68)
    ld hl, (USER_AREA_START + U_DP)
    ld de, 68
    add hl, de
    ld (saved_pad_val), hl

    ; 4. Put dummy value in TOS (DE)
    ld de, $1234
    
    ; 5. Set up IP to run PAD and then verify_pad
    ld bc, ip_list_pad
    jp NEXT

verify_pad:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains the expected PAD value
    ld hl, (saved_tos)
    ld de, (saved_pad_val)
    ld iy, err_pad_result_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 4 (anchor and the old TOS $1234 remain in stack memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the old TOS $1234 remains on the stack (at IX + 0)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $1234
    ld iy, err_old_tos_corrupted
    call assert_de_hl

    ; 4. Verify that the anchor value $9999 remains on the stack (at IX + 2)
    ld a, (ix+2)
    ld l, a
    ld a, (ix+3)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    jp pass_all

saved_dsp:
    dw 0
saved_tos:
    dw 0
saved_pad_val:
    dw 0

str_pad:
    db 3
    db "PAD"

ip_list_pad:
    dw PAD_CFA
    dw verify_pad_stub

verify_pad_stub:
    dw verify_pad_code

verify_pad_code:
    jp verify_pad

err_pad_not_found:                db "Word 'PAD' not found", 0
err_pad_cfa_mismatch:             db "PAD CFA mismatch", 0
err_pad_result_incorrect:         db "Result for PAD (DP + 68) is incorrect", 0
err_old_tos_corrupted:            db "Old TOS pushed to stack was corrupted", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
