; =============================================================================
; pForth - Z80 , (comma) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; Set DP to $3000 to avoid overwriting test code
    ld hl, $3000
    ld (USER_AREA_START + U_DP), hl

    ; --- TEST 1: Find word "," ---
    ld hl, str_comma
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_comma_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == COMMA_CFA
    ld iy, err_comma_cfa_mismatch
    ld de, COMMA_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute "," to compile $ABCD ---
    ; 1. Put value $ABCD into TOS (DE)
    ld de, $ABCD

    ; 2. Set up IP to run COMMA
    ld bc, test_ip_list
    jp NEXT

str_comma:
    db 1
    db ","

test_ip_list:
    dw COMMA_CFA
    dw test_verify_comma

test_verify_comma:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that $ABCD was written to $3000 (the original DP)
    ld hl, ($3000)
    ld de, $ABCD
    ld iy, err_write_mismatch
    call assert_de_hl

    ; 2. Verify that U_DP was updated to $3002
    ld hl, (USER_AREA_START + U_DP)
    ld de, $3002
    ld iy, err_dp_mismatch
    call assert_de_hl

    jp pass_all

err_comma_not_found:    db "Comma word ',' not found", 0
err_comma_cfa_mismatch: db "Comma CFA mismatch", 0
err_write_mismatch:     db "Value not written correctly by comma", 0
err_dp_mismatch:        db "U_DP not updated correctly by comma", 0
