; =============================================================================
; pForth - Z80 = (EQUALS) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "=" ---
    ld hl, str_equals
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_equals_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == EQUALS_CFA
    ld iy, err_equals_cfa_mismatch
    ld de, EQUALS_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute = with x1 == x2 ($1234 == $1234) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value $1234 (x1) onto data stack
    dec ix
    ld (ix+0), $12          ; high byte of $1234
    dec ix
    ld (ix+0), $34          ; low byte of $1234

    ; 4. Put value $1234 (x2) into TOS (DE)
    ld de, $1234
    
    ; 5. Set up IP to run = and then verify_equals
    ld bc, ip_list_equals
    jp NEXT

verify_equals:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $FFFF (true)
    ld hl, (saved_tos)
    ld de, $FFFF
    ld iy, err_equals_result_incorrect
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

    ; --- TEST 3: Execute = with x1 != x2 ($1234 == $5678) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value $1234 (x1) onto data stack
    dec ix
    ld (ix+0), $12          ; high byte of $1234
    dec ix
    ld (ix+0), $34          ; low byte of $1234

    ; 3. Put value $5678 (x2) into TOS (DE)
    ld de, $5678
    
    ; 4. Set up IP to run = and then verify_not_equals
    ld bc, ip_list_not_equals
    jp NEXT

verify_not_equals:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $0000 (false)
    ld hl, (saved_tos)
    ld de, $0000
    ld iy, err_not_equals_result_incorrect
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

    ; --- TEST 4: Execute = with x1 != x2 ($1234 == $1235) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value $1234 (x1) onto data stack
    dec ix
    ld (ix+0), $12          ; high byte of $1234
    dec ix
    ld (ix+0), $34          ; low byte of $1234

    ; 3. Put value $1235 (x2) into TOS (DE)
    ld de, $1235
    
    ; 4. Set up IP to run = and then verify_close_not_equals
    ld bc, ip_list_close_not_equals
    jp NEXT

verify_close_not_equals:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $0000 (false)
    ld hl, (saved_tos)
    ld de, $0000
    ld iy, err_close_not_equals_result_incorrect
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

str_equals:
    db 1
    db "="

ip_list_equals:
    dw EQUALS_CFA
    dw verify_equals_stub

verify_equals_stub:
    dw verify_equals_code

verify_equals_code:
    jp verify_equals

ip_list_not_equals:
    dw EQUALS_CFA
    dw verify_not_equals_stub

verify_not_equals_stub:
    dw verify_not_equals_code

verify_not_equals_code:
    jp verify_not_equals

ip_list_close_not_equals:
    dw EQUALS_CFA
    dw verify_close_not_equals_stub

verify_close_not_equals_stub:
    dw verify_close_not_equals_code

verify_close_not_equals_code:
    jp verify_close_not_equals

err_equals_not_found:                 db "Word '=' not found", 0
err_equals_cfa_mismatch:              db "= CFA mismatch", 0
err_equals_result_incorrect:          db "Result for = (x1 == x2) is incorrect (expected $FFFF)", 0
err_not_equals_result_incorrect:      db "Result for = (x1 != x2) is incorrect (expected $0000)", 0
err_close_not_equals_result_incorrect:db "Result for = (x1 close but != x2) is incorrect (expected $0000)", 0
err_dsp_mismatch:                     db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:                 db "Anchor value on stack was corrupted", 0
