; =============================================================================
; pForth - Z80 CREATE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; Set DP to $3000 to avoid overwriting test code
    ld hl, $3000
    ld (USER_AREA_START + U_DP), hl

    ; Copy "MYVAR " to TIB
    ld hl, tib_content
    ld de, TIB_START
    ld bc, 6
    ldir

    ; Reset U_IN = 0
    ld hl, 0
    ld (USER_AREA_START + U_IN), hl

    ; Set up IP to run CREATE
    ld bc, test_ip_list
    jp NEXT

tib_content:
    db "MYVAR "

test_ip_list:
    dw CREATE_CFA
    dw test_verify_word

test_verify_word:
    dw test_verify_code

test_verify_code:
    ; 1. Search for "MYVAR" using FIND_internal
    ld hl, str_myvar
    push hl
    pop iy
    call FIND_internal
    
    ; Save results
    push hl                 ; Save found CFA
    push af                 ; Save status

    ; Assert status == 1
    pop af
    ld iy, err_myvar_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Set up execution: EXECUTE expects CFA in TOS (DE)
    ld d, b
    ld e, c
    
    ; Save CFA to stack to compare later
    push bc
    
    ; EXECUTE_code ends with NEXT, so set IP (BC) to next step
    ld bc, test_ip_list_execute
    jp EXECUTE_code

test_ip_list_execute:
    dw test_verify_execute_word

test_verify_execute_word:
    dw test_verify_execute_code

test_verify_execute_code:
    ; The executed word (MYVAR) should have pushed its PFA to TOS (DE).
    ; Pop original CFA from stack into HL.
    pop hl
    
    ; Expected PFA is CFA + 2
    inc hl
    inc hl                  ; HL = expected PFA
    
    ; Assert DE == HL (TOS has PFA)
    ld iy, err_pfa_mismatch
    call assert_de_hl
    
    jp pass_all

str_myvar:
    db 5
    db "MYVAR"

err_myvar_not_found: db "MYVAR not found after CREATE", 0
err_pfa_mismatch:    db "Executed word did not return correct PFA", 0
