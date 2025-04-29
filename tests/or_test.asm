; =============================================================================
; pForth - Z80 OR Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "OR" ---
    ld hl, str_or
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_or_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == OR_CFA
    ld iy, err_or_cfa_mismatch
    ld de, OR_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute OR ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Push anchor $9999 onto data stack
    dec ix
    ld (ix+0), $99          ; high byte of $9999
    dec ix
    ld (ix+0), $99          ; low byte of $9999

    ; 3. Push value $F000 (x1) onto data stack
    dec ix
    ld (ix+0), $F0          ; high byte of $F000
    dec ix
    ld (ix+0), $00          ; low byte of $F000

    ; 4. Put value $00F0 (x2) into TOS (DE)
    ld de, $00F0
    
    ; 5. Set up IP to run OR
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0
saved_tos:
    dw 0

str_or:
    db 2
    db "OR"

test_ip_list:
    dw OR_CFA
    dw test_verify_or

test_verify_or:
    dw test_verify_code

test_verify_code:
    ; Save final TOS (DE) before running assertions (which overwrite DE)
    ld (saved_tos), de

    ; 1. Verify that the result of $F000 OR $00F0 is $F0F0
    ld hl, (saved_tos)
    ld de, $F0F0
    ld iy, err_or_incorrect
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

err_or_not_found:       db "Word 'OR' not found", 0
err_or_cfa_mismatch:    db "OR CFA mismatch", 0
err_or_incorrect:       db "Bitwise OR result is incorrect (expected $F0F0)", 0
err_dsp_mismatch:       db "DSP (IX) at incorrect offset after OR operation", 0
err_anchor_corrupted:   db "Anchor value on stack was corrupted", 0
