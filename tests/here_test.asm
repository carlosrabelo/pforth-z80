; =============================================================================
; pForth - Z80 HERE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "HERE" ---
    ld hl, str_here
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_here_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == HERE_CFA
    ld iy, err_here_cfa_mismatch
    ld de, HERE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute HERE ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Put dummy value in TOS (DE)
    ld de, $1234

    ; 4. Read the current DP value from User Area
    ld hl, (USER_AREA_START + U_DP)
    ld (saved_dp_val), hl
    
    ; 5. Set up IP to run HERE and then verify_here
    ld bc, ip_list_here
    jp NEXT

verify_here:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains the saved DP value
    ld hl, (saved_tos)
    ld de, (saved_dp_val)
    ld iy, err_here_result_incorrect
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
saved_dp_val:
    dw 0

str_here:
    db 4
    db "HERE"

ip_list_here:
    dw HERE_CFA
    dw verify_here_stub

verify_here_stub:
    dw verify_here_code

verify_here_code:
    jp verify_here

err_here_not_found:               db "Word 'HERE' not found", 0
err_here_cfa_mismatch:            db "HERE CFA mismatch", 0
err_here_result_incorrect:        db "Result for HERE (DP value) is incorrect", 0
err_old_tos_corrupted:            db "Old TOS pushed to stack was corrupted", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
