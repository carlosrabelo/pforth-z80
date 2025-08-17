; =============================================================================
; pForth - Z80 [COMPILE] Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "[COMPILE]" ---
    ld hl, str_bracket_compile
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_bracket_compile_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == BRACKET_COMPILE_CFA
    ld iy, err_bracket_compile_cfa_mismatch
    ld de, BRACKET_COMPILE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Verify that [COMPILE] is IMMEDIATE (bit 6 set in length byte) ---
    ; To do this, we find the NFA of [COMPILE]
    ; FIND_internal returns CFA in HL. The NFA of [COMPILE] is at BRACKET_COMPILE_NFA.
    ld a, (BRACKET_COMPILE_NFA)
    bit 6, a
    jr nz, immediate_flag_ok

    ; Bit 6 is not set
    ld hl, msg_immediate_failed
    jp fail_with_msg

immediate_flag_ok:

    ; --- TEST 3: Execute [COMPILE] IMMEDIATE (compiles IMMEDIATE_CFA) ---
    ; 1. Copy string "IMMEDIATE " to TIB
    ld hl, str_immediate_raw
    ld de, TIB_START
    ld bc, 10
    ldir

    ; 2. Initialize >IN to 0
    xor a
    ld hl, USER_AREA_START + U_IN
    ld (hl), a
    inc hl
    ld (hl), a

    ; 3. Save current DSP (IX)
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 4. Read initial DP value and save it
    ld hl, (USER_AREA_START + U_DP)
    ld (saved_dp_val), hl

    ; 5. Put dummy value in TOS (DE)
    ld de, $1234
    
    ; 6. Set up IP to run [COMPILE] and then verify_compilation
    ld bc, ip_list_bracket_compile
    jp NEXT

verify_compilation:
    ; Restore stack pointer
    ld ix, (saved_dsp)

    ; 1. Verify that the new DP value is initial_dp + 2
    ld hl, (USER_AREA_START + U_DP)
    ld de, (saved_dp_val)
    inc de
    inc de                      ; DE = saved_dp_val + 2
    ld iy, err_dp_incorrect
    call assert_de_hl

    ; 2. Verify that the value compiled at original DP is IMMEDIATE_CFA
    ld hl, (saved_dp_val)
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a                     ; DE = compiled CFA value
    ld hl, IMMEDIATE_CFA
    ld iy, err_compiled_cfa_incorrect
    call assert_de_hl

    jp pass_all

saved_dsp:
    dw 0
saved_tos:
    dw 0
saved_dp_val:
    dw 0

str_bracket_compile:
    db 9
    db "[COMPILE]"

str_immediate_raw:
    db "IMMEDIATE "

ip_list_bracket_compile:
    dw BRACKET_COMPILE_CFA
    dw verify_compilation_stub

verify_compilation_stub:
    dw verify_compilation_code

verify_compilation_code:
    jp verify_compilation

err_bracket_compile_not_found:    db "Word '[COMPILE]' not found", 0
err_bracket_compile_cfa_mismatch: db "[COMPILE] CFA mismatch", 0
msg_immediate_failed:             db "[COMPILE] is not marked as IMMEDIATE", 0
err_dp_incorrect:                 db "New DP value after [COMPILE] is incorrect", 0
err_compiled_cfa_incorrect:       db "Compiled CFA value is not IMMEDIATE_CFA", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
