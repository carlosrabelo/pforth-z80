; =============================================================================
; pForth - Z80 < (LESS THAN) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "<" ---
    ld hl, str_less
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_less_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == LESS_CFA
    ld iy, err_less_cfa_mismatch
    ld de, LESS_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute < with positive n1 < n2 (5 < 10) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value 5 (n1) onto data stack
    dec ix
    ld (ix+0), $00          ; high byte of 5
    dec ix
    ld (ix+0), $05          ; low byte of 5

    ; 4. Put value 10 (n2) into TOS (DE)
    ld de, 10
    
    ; 5. Set up IP to run < and then verify_pos_less
    ld bc, ip_list_pos_less
    jp NEXT

verify_pos_less:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains $FFFF (true)
    ld hl, (saved_tos)
    ld de, $FFFF
    ld iy, err_pos_less_result_incorrect
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

    ; --- TEST 3: Execute < with positive n1 >= n2 (10 < 5) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value 10 (n1) onto data stack
    dec ix
    ld (ix+0), $00          ; high byte of 10
    dec ix
    ld (ix+0), $0A          ; low byte of 10

    ; 3. Put value 5 (n2) into TOS (DE)
    ld de, 5
    
    ; 4. Set up IP to run < and then verify_pos_not_less
    ld bc, ip_list_pos_not_less
    jp NEXT

verify_pos_not_less:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains $0000 (false)
    ld hl, (saved_tos)
    ld de, $0000
    ld iy, err_pos_not_less_result_incorrect
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

    ; --- TEST 4: Execute < with negative n1 < n2 (-10 < -5) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value -10 (n1 = $FFF6) onto data stack
    dec ix
    ld (ix+0), $FF          ; high byte of -10
    dec ix
    ld (ix+0), $F6          ; low byte of -10

    ; 3. Put value -5 (n2 = $FFFB) into TOS (DE)
    ld de, -5
    
    ; 4. Set up IP to run < and then verify_neg_less
    ld bc, ip_list_neg_less
    jp NEXT

verify_neg_less:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains $FFFF (true)
    ld hl, (saved_tos)
    ld de, $FFFF
    ld iy, err_neg_less_result_incorrect
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

    ; --- TEST 5: Execute < with overflow n1 < n2 (-32768 < 32767) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value -32768 (n1 = $8000) onto data stack
    dec ix
    ld (ix+0), $80          ; high byte of -32768
    dec ix
    ld (ix+0), $00          ; low byte of -32768

    ; 3. Put value 32767 (n2 = $7FFF) into TOS (DE)
    ld de, $7FFF
    
    ; 4. Set up IP to run < and then verify_overflow_less
    ld bc, ip_list_overflow_less
    jp NEXT

verify_overflow_less:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains $FFFF (true)
    ld hl, (saved_tos)
    ld de, $FFFF
    ld iy, err_overflow_less_result_incorrect
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

    ; --- TEST 6: Execute < with overflow n1 >= n2 (32767 < -32768) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value 32767 (n1 = $7FFF) onto data stack
    dec ix
    ld (ix+0), $7F          ; high byte of 32767
    dec ix
    ld (ix+0), $FF          ; low byte of 32767

    ; 3. Put value -32768 (n2 = $8000) into TOS (DE)
    ld de, $8000
    
    ; 4. Set up IP to run < and then verify_overflow_not_less
    ld bc, ip_list_overflow_not_less
    jp NEXT

verify_overflow_not_less:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains $0000 (false)
    ld hl, (saved_tos)
    ld de, $0000
    ld iy, err_overflow_not_less_result_incorrect
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

str_less:
    db 1
    db "<"

ip_list_pos_less:
    dw LESS_CFA
    dw verify_pos_less_stub

verify_pos_less_stub:
    dw verify_pos_less_code

verify_pos_less_code:
    jp verify_pos_less

ip_list_pos_not_less:
    dw LESS_CFA
    dw verify_pos_not_less_stub

verify_pos_not_less_stub:
    dw verify_pos_not_less_code

verify_pos_not_less_code:
    jp verify_pos_not_less

ip_list_neg_less:
    dw LESS_CFA
    dw verify_neg_less_stub

verify_neg_less_stub:
    dw verify_neg_less_code

verify_neg_less_code:
    jp verify_neg_less

ip_list_overflow_less:
    dw LESS_CFA
    dw verify_overflow_less_stub

verify_overflow_less_stub:
    dw verify_overflow_less_code

verify_overflow_less_code:
    jp verify_overflow_less

ip_list_overflow_not_less:
    dw LESS_CFA
    dw verify_overflow_not_less_stub

verify_overflow_not_less_stub:
    dw verify_overflow_not_less_code

verify_overflow_not_less_code:
    jp verify_overflow_not_less

err_less_not_found:                      db "Word '<' not found", 0
err_less_cfa_mismatch:                   db "< CFA mismatch", 0
err_pos_less_result_incorrect:           db "Result for < (5 < 10) is incorrect (expected $FFFF)", 0
err_pos_not_less_result_incorrect:       db "Result for < (10 < 5) is incorrect (expected $0000)", 0
err_neg_less_result_incorrect:           db "Result for < (-10 < -5) is incorrect (expected $FFFF)", 0
err_overflow_less_result_incorrect:      db "Result for < (-32768 < 32767) is incorrect (expected $FFFF)", 0
err_overflow_not_less_result_incorrect:  db "Result for < (32767 < -32768) is incorrect (expected $0000)", 0
err_dsp_mismatch:                        db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:                    db "Anchor value on stack was corrupted", 0
