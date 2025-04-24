; =============================================================================
; pForth - Z80 C@ (Byte Fetch) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "C@" ---
    ld hl, str_c_fetch
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_c_fetch_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == C_FETCH_CFA
    ld iy, err_c_fetch_cfa_mismatch
    ld de, C_FETCH_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute C@ on low byte ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Put address of test_data (low byte) into TOS (DE)
    ld de, test_data
    
    ; 3. Set up IP to run C@
    ld bc, ip_list_low
    jp NEXT

verify_low:
    ; 1. Verify that TOS (DE) contains $00AB
    ld hl, $00AB
    ld iy, err_low_tos_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) remained unchanged
    ld hl, (saved_dsp)
    ld iy, err_dsp_changed
    call assert_ix_hl

    ; --- TEST 3: Execute C@ on high byte ---
    ; 1. Put address of test_data + 1 (high byte) into TOS (DE)
    ld de, test_data + 1
    
    ; 2. Set up IP to run C@
    ld bc, ip_list_high
    jp NEXT

verify_high:
    ; 1. Verify that TOS (DE) contains $0012
    ld hl, $0012
    ld iy, err_high_tos_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) remained unchanged
    ld hl, (saved_dsp)
    ld iy, err_dsp_changed
    call assert_ix_hl

    jp pass_all

saved_dsp:
    dw 0

test_data:
    dw $12AB

str_c_fetch:
    db 2
    db "C@"

ip_list_low:
    dw C_FETCH_CFA
    dw verify_low_stub

verify_low_stub:
    dw verify_low_code

verify_low_code:
    jp verify_low

ip_list_high:
    dw C_FETCH_CFA
    dw verify_high_stub

verify_high_stub:
    dw verify_high_code

verify_high_code:
    jp verify_high

err_c_fetch_not_found:    db "Word 'C@' not found", 0
err_c_fetch_cfa_mismatch: db "C@ CFA mismatch", 0
err_low_tos_incorrect:    db "TOS (DE) does not contain the low byte value $00AB", 0
err_high_tos_incorrect:   db "TOS (DE) does not contain the high byte value $0012", 0
err_dsp_changed:          db "DSP (IX) was incorrectly modified by C@", 0
