; =============================================================================
; pForth - Z80 @ (Fetch) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "@" ---
    ld hl, str_fetch
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_fetch_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == FETCH_CFA
    ld iy, err_fetch_cfa_mismatch
    ld de, FETCH_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute @ ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Put address of test_data into TOS (DE)
    ld de, test_data
    
    ; 3. Set up IP to run @
    ld bc, test_ip_list
    jp NEXT

saved_dsp:
    dw 0

test_data:
    dw $ABCD

str_fetch:
    db 1
    db "@"

test_ip_list:
    dw FETCH_CFA
    dw test_verify_fetch

test_verify_fetch:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that TOS (DE) now contains the value at test_data ($ABCD)
    ld hl, $ABCD
    ld iy, err_tos_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) remained unchanged
    ld hl, (saved_dsp)
    ld iy, err_dsp_changed
    call assert_ix_hl

    jp pass_all

err_fetch_not_found:    db "Word '@' not found", 0
err_fetch_cfa_mismatch: db "@ CFA mismatch", 0
err_tos_incorrect:      db "TOS (DE) does not contain the fetched value $ABCD", 0
err_dsp_changed:        db "DSP (IX) was incorrectly modified by @", 0
