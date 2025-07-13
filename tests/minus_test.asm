; =============================================================================
; pForth - Z80 - (Subtraction) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "-" ---
    ld hl, str_minus
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_minus_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == MINUS_CFA
    ld iy, err_minus_cfa_mismatch
    ld de, MINUS_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute - ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value $2222 (x1) onto data stack
    dec ix
    ld (ix+0), $22          ; high byte of $2222
    dec ix
    ld (ix+0), $22          ; low byte of $2222

    ; 4. Put value $1111 (x2) into TOS (DE)
    ld de, $1111
    
    ; 5. Set up IP to run -
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_tos:
    dw 0

str_minus:
    db 1
    db "-"

test_ip_list:
    dw MINUS_CFA
    dw test_verify_minus

test_verify_minus:
    dw test_verify_code

test_verify_code:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that the difference is $1111 ($2222 - $1111)
    ld hl, (saved_tos)
    ld de, $1111
    ld iy, err_diff_incorrect
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

    jp pass_all

err_minus_not_found:     db "Word '-' not found", 0
err_minus_cfa_mismatch:  db "- CFA mismatch", 0
err_diff_incorrect:      db "Difference is incorrect (expected $1111)", 0
err_dsp_mismatch:       db "DSP (IX) at incorrect offset after subtraction", 0
err_anchor_corrupted:   db "Anchor value on stack was corrupted", 0
