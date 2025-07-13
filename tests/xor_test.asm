; =============================================================================
; pForth - Z80 XOR Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "XOR" ---
    ld hl, str_xor
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_xor_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == XOR_CFA
    ld iy, err_xor_cfa_mismatch
    ld de, XOR_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute XOR ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value $FF00 (x1) onto data stack
    dec ix
    ld (ix+0), $FF          ; high byte of $FF00
    dec ix
    ld (ix+0), $00          ; low byte of $FF00

    ; 4. Put value $F0F0 (x2) into TOS (DE)
    ld de, $F0F0
    
    ; 5. Set up IP to run XOR
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_tos:
    dw 0

str_xor:
    db 3
    db "XOR"

test_ip_list:
    dw XOR_CFA
    dw test_verify_xor

test_verify_xor:
    dw test_verify_code

test_verify_code:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that the result of $FF00 XOR $F0F0 is $0FF0
    ld hl, (saved_tos)
    ld de, $0FF0
    ld iy, err_xor_incorrect
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

err_xor_not_found:       db "Word 'XOR' not found", 0
err_xor_cfa_mismatch:    db "XOR CFA mismatch", 0
err_xor_incorrect:       db "Bitwise XOR result is incorrect (expected $0FF0)", 0
err_dsp_mismatch:       db "DSP (IX) at incorrect offset after XOR operation", 0
err_anchor_corrupted:   db "Anchor value on stack was corrupted", 0
