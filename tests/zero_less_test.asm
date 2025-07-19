; =============================================================================
; pForth - Z80 0< Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "0<" ---
    ld hl, str_zero_less
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_zero_less_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == ZERO_LESS_CFA
    ld iy, err_zero_less_cfa_mismatch
    ld de, ZERO_LESS_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute 0< with negative ($FFFF) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Put value $FFFF (-1) into TOS (DE)
    ld de, $FFFF
    
    ; 4. Set up IP to run 0< and then verify_negative
    ld bc, ip_list_negative
    jp NEXT

verify_negative:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $FFFF (true)
    ld hl, (saved_tos)
    ld de, $FFFF
    ld iy, err_neg_result_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 2 (anchor remains in stack memory)
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

    ; --- TEST 3: Execute 0< with positive ($1234) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Put value $1234 into TOS (DE)
    ld de, $1234
    
    ; 3. Set up IP to run 0< and then verify_positive
    ld bc, ip_list_positive
    jp NEXT

verify_positive:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $0000 (false)
    ld hl, (saved_tos)
    ld de, $0000
    ld iy, err_pos_result_incorrect
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

str_zero_less:
    db 2
    db "0<"

ip_list_negative:
    dw ZERO_LESS_CFA
    dw verify_negative_stub

verify_negative_stub:
    dw verify_negative_code

verify_negative_code:
    jp verify_negative

ip_list_positive:
    dw ZERO_LESS_CFA
    dw verify_positive_stub

verify_positive_stub:
    dw verify_positive_code

verify_positive_code:
    jp verify_positive

err_zero_less_not_found:     db "Word '0<' not found", 0
err_zero_less_cfa_mismatch:  db "0< CFA mismatch", 0
err_neg_result_incorrect:    db "Result for 0< with negative is incorrect (expected $FFFF)", 0
err_pos_result_incorrect:    db "Result for 0< with positive is incorrect (expected $0000)", 0
err_dsp_mismatch:              db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:          db "Anchor value on stack was corrupted", 0
