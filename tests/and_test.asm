; =============================================================================
; pForth - Z80 AND Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "AND" ---
    ld hl, str_and
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_and_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == AND_CFA
    ld iy, err_and_cfa_mismatch
    ld de, AND_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute AND ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value $F0F0 (x1) onto data stack
    dec ix
    ld (ix+0), $F0          ; high byte of $F0F0
    dec ix
    ld (ix+0), $F0          ; low byte of $F0F0

    ; 4. Put value $0FF0 (x2) into TOS (DE)
    ld de, $0FF0
    
    ; 5. Set up IP to run AND
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_tos:
    dw 0

str_and:
    db 3
    db "AND"

test_ip_list:
    dw AND_CFA
    dw test_verify_and

test_verify_and:
    dw test_verify_code

test_verify_code:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that the result of $F0F0 AND $0FF0 is $00F0
    ld hl, (saved_tos)
    ld de, $00F0
    ld iy, err_and_incorrect
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

err_and_not_found:      db "Word 'AND' not found", 0
err_and_cfa_mismatch:   db "AND CFA mismatch", 0
err_and_incorrect:      db "Bitwise AND result is incorrect (expected $00F0)", 0
err_dsp_mismatch:       db "DSP (IX) at incorrect offset after AND operation", 0
err_anchor_corrupted:   db "Anchor value on stack was corrupted", 0
