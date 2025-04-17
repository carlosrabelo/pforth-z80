; =============================================================================
; pForth - Z80 IMMEDIATE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "IMMEDIATE" ---
    ld hl, str_immediate
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_immediate_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == IMMEDIATE_CFA
    ld iy, err_immediate_cfa_mismatch
    ld de, IMMEDIATE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute "IMMEDIATE" ---
    ; 1. Create a mock word header in RAM at $3000
    ; NFA: length 7 ("MYIMMED"), bit 7 set on first and last character.
    ; Byte 0: length byte = $87
    ld hl, $3000
    ld (hl), $87
    
    ; 2. Set U_CURRENT to point to this mock word ($3000)
    ld (USER_AREA_START + U_CURRENT), hl

    ; 3. Set up IP to run IMMEDIATE
    ld bc, test_ip_list
    jp NEXT

str_immediate:
    db 9
    db "IMMEDIATE"

test_ip_list:
    dw IMMEDIATE_CFA
    dw test_verify_immediate

test_verify_immediate:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that the length byte at $3000 was updated with bit 6 set ($87 | $40 = $C7)
    ld a, ($3000)
    ld l, a
    ld h, 0
    ld de, $C7
    ld iy, err_immediate_flag_not_set
    call assert_de_hl

    jp pass_all

err_immediate_not_found:    db "Word 'IMMEDIATE' not found", 0
err_immediate_cfa_mismatch: db "IMMEDIATE CFA mismatch", 0
err_immediate_flag_not_set: db "IMMEDIATE flag bit 6 was not set on U_CURRENT word", 0
