; =============================================================================
; pForth - Z80 COMPILE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "COMPILE" ---
    ld hl, str_compile
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_compile_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == COMPILE_CFA
    ld iy, err_compile_cfa_mismatch
    ld de, COMPILE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute COMPILE ---
    ; 1. Save current DSP (IX) to static variable
    push ix
    pop hl
    ld (saved_dsp), hl

    ; 2. Read initial DP value and save it
    ld hl, (USER_AREA_START + U_DP)
    ld (saved_dp_val), hl

    ; 3. Put dummy value in TOS (DE)
    ld de, $1234
    
    ; 4. Set up IP to run COMPILE which points to:
    ;    - COMPILE_CFA
    ;    - IMMEDIATE_CFA (the word we compile)
    ;    - verify_compilation_stub
    ld bc, ip_list_compile
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

    ; 3. Verify that BC (IP) is advanced to the cell after verify_compilation_stub
    push bc
    pop hl                      ; HL = final IP
    ld de, ip_list_verify + 2
    ld iy, err_ip_mismatch
    call assert_de_hl

    jp pass_all

saved_dsp:
    dw 0
saved_tos:
    dw 0
saved_dp_val:
    dw 0

str_compile:
    db 7
    db "COMPILE"

ip_list_compile:
    dw COMPILE_CFA
    dw IMMEDIATE_CFA            ; Target word to be compiled
ip_list_verify:
    dw verify_compilation_stub

verify_compilation_stub:
    dw verify_compilation_code

verify_compilation_code:
    jp verify_compilation

err_compile_not_found:            db "Word 'COMPILE' not found", 0
err_compile_cfa_mismatch:         db "COMPILE CFA mismatch", 0
err_dp_incorrect:                 db "New DP value after COMPILE is incorrect", 0
err_compiled_cfa_incorrect:       db "Compiled CFA value is not IMMEDIATE_CFA", 0
err_ip_mismatch:                  db "IP (BC) was not advanced past the compiled cell", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
