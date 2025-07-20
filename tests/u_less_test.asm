; =============================================================================
; pForth - Z80 U< Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "U<" ---
    ld hl, str_u_less
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_u_less_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == U_LESS_CFA
    ld iy, err_u_less_cfa_mismatch
    ld de, U_LESS_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute U< with u1 < u2 ($1111 < $2222) ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value $1111 (u1) onto data stack
    dec ix
    ld (ix+0), $11          ; high byte of $1111
    dec ix
    ld (ix+0), $11          ; low byte of $1111

    ; 4. Put value $2222 (u2) into TOS (DE)
    ld de, $2222
    
    ; 5. Set up IP to run U< and then verify_less
    ld bc, ip_list_less
    jp NEXT

verify_less:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $FFFF (true)
    ld hl, (saved_tos)
    ld de, $FFFF
    ld iy, err_less_result_incorrect
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

    ; --- TEST 3: Execute U< with u1 >= u2 ($2222 >= $1111) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value $2222 (u1) onto data stack
    dec ix
    ld (ix+0), $22          ; high byte of $2222
    dec ix
    ld (ix+0), $22          ; low byte of $2222

    ; 3. Put value $1111 (u2) into TOS (DE)
    ld de, $1111
    
    ; 4. Set up IP to run U< and then verify_not_less
    ld bc, ip_list_not_less
    jp NEXT

verify_not_less:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $0000 (false)
    ld hl, (saved_tos)
    ld de, $0000
    ld iy, err_not_less_result_incorrect
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

    ; --- TEST 4: Execute U< with MSB set unsigned comparison ($7FFF < $8000) ---
    ; 1. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 2. Push value $7FFF (u1) onto data stack
    dec ix
    ld (ix+0), $7F          ; high byte of $7FFF
    dec ix
    ld (ix+0), $FF          ; low byte of $7FFF

    ; 3. Put value $8000 (u2) into TOS (DE)
    ld de, $8000
    
    ; 4. Set up IP to run U< and then verify_msb
    ld bc, ip_list_msb
    jp NEXT

verify_msb:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that TOS contains $FFFF (true) since 32767 < 32768
    ld hl, (saved_tos)
    ld de, $FFFF
    ld iy, err_msb_result_incorrect
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

str_u_less:
    db 2
    db "U<"

ip_list_less:
    dw U_LESS_CFA
    dw verify_less_stub

verify_less_stub:
    dw verify_less_code

verify_less_code:
    jp verify_less

ip_list_not_less:
    dw U_LESS_CFA
    dw verify_not_less_stub

verify_not_less_stub:
    dw verify_not_less_code

verify_not_less_code:
    jp verify_not_less

ip_list_msb:
    dw U_LESS_CFA
    dw verify_msb_stub

verify_msb_stub:
    dw verify_msb_code

verify_msb_code:
    jp verify_msb

err_u_less_not_found:          db "Word 'U<' not found", 0
err_u_less_cfa_mismatch:       db "U< CFA mismatch", 0
err_less_result_incorrect:     db "Result for U< (u1 < u2) is incorrect (expected $FFFF)", 0
err_not_less_result_incorrect: db "Result for U< (u1 >= u2) is incorrect (expected $0000)", 0
err_msb_result_incorrect:      db "Result for U< ($7FFF < $8000) is incorrect (expected $FFFF)", 0
err_dsp_mismatch:              db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:          db "Anchor value on stack was corrupted", 0
