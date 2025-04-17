; =============================================================================
; pForth - Z80 ; (semicolon) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; Set DP to $3000 to avoid overwriting test code
    ld hl, $3000
    ld (USER_AREA_START + U_DP), hl

    ; --- TEST 1: Find word ";" ---
    ld hl, str_semicolon
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_semicolon_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == SEMICOLON_CFA
    ld iy, err_semicolon_cfa_mismatch
    ld de, SEMICOLON_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; Assert word is IMMEDIATE (length byte should have bit 6 set: $C1)
    ld a, (SEMICOLON_NFA)
    ld l, a
    ld h, 0
    ld de, $C1
    ld iy, err_not_immediate
    call assert_de_hl

    ; --- TEST 2: Execute ";" to end compilation ---
    ; 1. Set STATE = 1 (compiling)
    ld a, 1
    ld (USER_AREA_START + U_STATE), a

    ; 2. Set up IP to run SEMICOLON
    ld bc, test_ip_list
    jp NEXT

str_semicolon:
    db 1
    db ";"

test_ip_list:
    dw SEMICOLON_CFA
    dw test_verify_semicolon

test_verify_semicolon:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that SEMI_CFA was compiled at $3000
    ld hl, ($3000)
    ld de, SEMI_CFA
    ld iy, err_semi_not_compiled
    call assert_de_hl

    ; 2. Verify that U_DP was updated to $3002
    ld hl, (USER_AREA_START + U_DP)
    ld de, $3002
    ld iy, err_dp_mismatch
    call assert_de_hl

    ; 3. Verify that U_STATE is 0 (interpreting)
    ld a, (USER_AREA_START + U_STATE)
    ld l, a
    ld h, 0
    ld de, 0
    ld iy, err_state_not_interpreting
    call assert_de_hl

    jp pass_all

err_semicolon_not_found:     db "Semicolon word ';' not found", 0
err_semicolon_cfa_mismatch:  db "Semicolon CFA mismatch", 0
err_not_immediate:           db "Semicolon ';' length byte does not have bit 6 set", 0
err_semi_not_compiled:       db "SEMI_CFA was not compiled by semicolon", 0
err_dp_mismatch:             db "U_DP not updated correctly", 0
err_state_not_interpreting:  db "U_STATE was not reset to 0 (interpreting)", 0
