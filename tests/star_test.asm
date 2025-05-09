; =============================================================================
; pForth - Z80 * (MULTIPLY) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "*" ---
    ld hl, str_star
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_star_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == STAR_CFA
    ld iy, err_star_cfa_mismatch
    ld de, STAR_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute * with 3 * 5 ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value 3 (n1) onto data stack
    dec ix
    ld (ix+0), $00          ; high byte of 3
    dec ix
    ld (ix+0), $03          ; low byte of 3

    ; 4. Put value 5 (n2) into TOS (DE)
    ld de, 5
    
    ; 5. Set up IP to run * and then verify_mul_pos
    ld bc, ip_list_mul_pos
    jp NEXT

verify_mul_pos:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains 15
    ld hl, (saved_tos)
    ld de, 15
    ld iy, err_mul_pos_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the anchor value $9999 remains on the stack
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 3: Execute * with 5 * 0 ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value 5 (n1) onto data stack
    dec ix
    ld (ix+0), $00          ; high byte of 5
    dec ix
    ld (ix+0), $05          ; low byte of 5

    ; 3. Put value 0 (n2) into TOS (DE)
    ld de, 0
    
    ; 4. Set up IP to run * and then verify_mul_zero
    ld bc, ip_list_mul_zero
    jp NEXT

verify_mul_zero:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains 0
    ld hl, (saved_tos)
    ld de, 0
    ld iy, err_mul_zero_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the anchor value $9999 remains on the stack
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 4: Execute * with -2 * 3 (signed) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value -2 (n1 = $FFFE) onto data stack
    dec ix
    ld (ix+0), $FF          ; high byte of -2
    dec ix
    ld (ix+0), $FE          ; low byte of -2

    ; 3. Put value 3 (n2 = $0003) into TOS (DE)
    ld de, 3
    
    ; 4. Set up IP to run * and then verify_mul_neg
    ld bc, ip_list_mul_neg
    jp NEXT

verify_mul_neg:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains -6 ($FFFA)
    ld hl, (saved_tos)
    ld de, -6
    ld iy, err_mul_neg_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the anchor value $9999 remains on the stack
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 5: Execute * with 1000 * 100 (modulo 65536 check) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value 1000 (n1 = $03E8) onto data stack
    dec ix
    ld (ix+0), $03          ; high byte of 1000
    dec ix
    ld (ix+0), $E8          ; low byte of 1000

    ; 3. Put value 100 (n2 = $0064) into TOS (DE)
    ld de, 100
    
    ; 4. Set up IP to run * and then verify_mul_large
    ld bc, ip_list_mul_large
    jp NEXT

verify_mul_large:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains 34464 ($86A0) since 100000 % 65536 = 34464
    ld hl, (saved_tos)
    ld de, 34464
    ld iy, err_mul_large_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 2
    ld hl, (saved_dsp)
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the anchor value $9999 remains on the stack
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    jp pass_all

saved_dsp:
    dw 0
saved_tos:
    dw 0

str_star:
    db 1
    db "*"

ip_list_mul_pos:
    dw STAR_CFA
    dw verify_mul_pos_stub

verify_mul_pos_stub:
    dw verify_mul_pos_code

verify_mul_pos_code:
    jp verify_mul_pos

ip_list_mul_zero:
    dw STAR_CFA
    dw verify_mul_zero_stub

verify_mul_zero_stub:
    dw verify_mul_zero_code

verify_mul_zero_code:
    jp verify_mul_zero

ip_list_mul_neg:
    dw STAR_CFA
    dw verify_mul_neg_stub

verify_mul_neg_stub:
    dw verify_mul_neg_code

verify_mul_neg_code:
    jp verify_mul_neg

ip_list_mul_large:
    dw STAR_CFA
    dw verify_mul_large_stub

verify_mul_large_stub:
    dw verify_mul_large_code

verify_mul_large_code:
    jp verify_mul_large

err_star_not_found:              db "Word '*' not found", 0
err_star_cfa_mismatch:           db "* CFA mismatch", 0
err_mul_pos_incorrect:           db "Result for * (3 * 5) is incorrect (expected 15)", 0
err_mul_zero_incorrect:          db "Result for * (5 * 0) is incorrect (expected 0)", 0
err_mul_neg_incorrect:           db "Result for * (-2 * 3) is incorrect (expected -6)", 0
err_mul_large_incorrect:         db "Result for * (1000 * 100) is incorrect (expected 34464)", 0
err_dsp_mismatch:                db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:            db "Anchor value on stack was corrupted", 0
