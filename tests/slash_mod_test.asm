; =============================================================================
; pForth - Z80 /MOD (DIVIDE/MODULO) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "/MOD" ---
    ld hl, str_slash_mod
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_slash_mod_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == SLASH_MOD_CFA
    ld iy, err_slash_mod_cfa_mismatch
    ld de, SLASH_MOD_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute /MOD with 7 /MOD 3 (both positive) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value 7 (n1) onto data stack
    dec ix
    ld (ix+0), $00          ; high byte of 7
    dec ix
    ld (ix+0), $07          ; low byte of 7

    ; 4. Put value 3 (n2) into TOS (DE)
    ld de, 3
    
    ; 5. Set up IP to run /MOD and then verify_pos_pos
    ld bc, ip_list_pos_pos
    jp NEXT

verify_pos_pos:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains quocient = 2
    ld hl, (saved_tos)
    ld de, 2
    ld iy, err_pos_pos_quot_incorrect
    call assert_de_hl

    ; 2. Verify that remainder on stack is 1
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, 1
    ld iy, err_pos_pos_rem_incorrect
    call assert_de_hl

    ; 3. Verify that DSP (IX) is initial_dsp - 4 (anchor and remainder remain)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 4. Verify that the anchor value $9999 remains on the stack (at IX + 2)
    ld a, (ix+2)
    ld l, a
    ld a, (ix+3)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 3: Execute /MOD with -7 /MOD 3 (negative dividend) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value -7 (n1 = $FFF9) onto data stack
    dec ix
    ld (ix+0), $FF          ; high byte of -7
    dec ix
    ld (ix+0), $F9          ; low byte of -7

    ; 3. Put value 3 (n2) into TOS (DE)
    ld de, 3
    
    ; 4. Set up IP to run /MOD and then verify_neg_pos
    ld bc, ip_list_neg_pos
    jp NEXT

verify_neg_pos:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains quocient = -2 ($FFFE)
    ld hl, (saved_tos)
    ld de, -2
    ld iy, err_neg_pos_quot_incorrect
    call assert_de_hl

    ; 2. Verify that remainder on stack is -1 ($FFFF)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, -1
    ld iy, err_neg_pos_rem_incorrect
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 4: Execute /MOD with 7 /MOD -3 (negative divisor) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value 7 (n1) onto data stack
    dec ix
    ld (ix+0), $00          ; high byte of 7
    dec ix
    ld (ix+0), $07          ; low byte of 7

    ; 3. Put value -3 (n2 = $FFFD) into TOS (DE)
    ld de, -3
    
    ; 4. Set up IP to run /MOD and then verify_pos_neg
    ld bc, ip_list_pos_neg
    jp NEXT

verify_pos_neg:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains quocient = -2 ($FFFE)
    ld hl, (saved_tos)
    ld de, -2
    ld iy, err_pos_neg_quot_incorrect
    call assert_de_hl

    ; 2. Verify that remainder on stack is 1 ($0001)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, 1
    ld iy, err_pos_neg_rem_incorrect
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 5: Execute /MOD with -7 /MOD -3 (both negative) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value -7 (n1 = $FFF9) onto data stack
    dec ix
    ld (ix+0), $FF          ; high byte of -7
    dec ix
    ld (ix+0), $F9          ; low byte of -7

    ; 3. Put value -3 (n2 = $FFFD) into TOS (DE)
    ld de, -3
    
    ; 4. Set up IP to run /MOD and then verify_neg_neg
    ld bc, ip_list_neg_neg
    jp NEXT

verify_neg_neg:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains quocient = 2
    ld hl, (saved_tos)
    ld de, 2
    ld iy, err_neg_neg_quot_incorrect
    call assert_de_hl

    ; 2. Verify that remainder on stack is -1 ($FFFF)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, -1
    ld iy, err_neg_neg_rem_incorrect
    call assert_de_hl

    ; Restore stack pointer for next test
    ld ix, (saved_dsp)

    ; --- TEST 6: Execute /MOD with 0 /MOD 5 ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value 0 (n1) onto data stack
    dec ix
    ld (ix+0), $00
    dec ix
    ld (ix+0), $00

    ; 3. Put value 5 (n2) into TOS (DE)
    ld de, 5
    
    ; 4. Set up IP to run /MOD and then verify_zero_dividend
    ld bc, ip_list_zero_dividend
    jp NEXT

verify_zero_dividend:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains quocient = 0
    ld hl, (saved_tos)
    ld de, 0
    ld iy, err_zero_div_quot_incorrect
    call assert_de_hl

    ; 2. Verify that remainder on stack is 0
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, 0
    ld iy, err_zero_div_rem_incorrect
    call assert_de_hl

    jp pass_all

saved_dsp:
    dw 0
saved_tos:
    dw 0

str_slash_mod:
    db 4
    db "/MOD"

ip_list_pos_pos:
    dw SLASH_MOD_CFA
    dw verify_pos_pos_stub

verify_pos_pos_stub:
    dw verify_pos_pos_code

verify_pos_pos_code:
    jp verify_pos_pos

ip_list_neg_pos:
    dw SLASH_MOD_CFA
    dw verify_neg_pos_stub

verify_neg_pos_stub:
    dw verify_neg_pos_code

verify_neg_pos_code:
    jp verify_neg_pos

ip_list_pos_neg:
    dw SLASH_MOD_CFA
    dw verify_pos_neg_stub

verify_pos_neg_stub:
    dw verify_pos_neg_code

verify_pos_neg_code:
    jp verify_pos_neg

ip_list_neg_neg:
    dw SLASH_MOD_CFA
    dw verify_neg_neg_stub

verify_neg_neg_stub:
    dw verify_neg_neg_code

verify_neg_neg_code:
    jp verify_neg_neg

ip_list_zero_dividend:
    dw SLASH_MOD_CFA
    dw verify_zero_dividend_stub

verify_zero_dividend_stub:
    dw verify_zero_dividend_code

verify_zero_dividend_code:
    jp verify_zero_dividend

err_slash_mod_not_found:                  db "Word '/MOD' not found", 0
err_slash_mod_cfa_mismatch:               db "/MOD CFA mismatch", 0
err_pos_pos_quot_incorrect:               db "Quotient for 7 /MOD 3 is incorrect (expected 2)", 0
err_pos_pos_rem_incorrect:                db "Remainder for 7 /MOD 3 is incorrect (expected 1)", 0
err_neg_pos_quot_incorrect:               db "Quotient for -7 /MOD 3 is incorrect (expected -2)", 0
err_neg_pos_rem_incorrect:                db "Remainder for -7 /MOD 3 is incorrect (expected -1)", 0
err_pos_neg_quot_incorrect:               db "Quotient for 7 /MOD -3 is incorrect (expected -2)", 0
err_pos_neg_rem_incorrect:                db "Remainder for 7 /MOD -3 is incorrect (expected 1)", 0
err_neg_neg_quot_incorrect:               db "Quotient for -7 /MOD -3 is incorrect (expected 2)", 0
err_neg_neg_rem_incorrect:                db "Remainder for -7 /MOD -3 is incorrect (expected -1)", 0
err_zero_div_quot_incorrect:              db "Quotient for 0 /MOD 5 is incorrect (expected 0)", 0
err_zero_div_rem_incorrect:               db "Remainder for 0 /MOD 5 is incorrect (expected 0)", 0
err_dsp_mismatch:                         db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:                     db "Anchor value on stack was corrupted", 0
