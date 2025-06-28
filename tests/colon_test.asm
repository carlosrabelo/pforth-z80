; =============================================================================
; pForth - Z80 : (colon) Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; Set DP to $3000 to avoid overwriting test code
    ld hl, $3000
    ld (USER_AREA_START + U_DP), hl

    ; Copy "MYNEWWORD " to TIB
    ld hl, tib_content
    ld de, TIB_START
    ld bc, 11
    ldir

    ; Reset U_IN = 0
    ld hl, 0
    ld (USER_AREA_START + U_IN), hl

    ; Reset STATE = 0
    xor a
    ld (USER_AREA_START + U_STATE), a

    ; --- TEST 1: Find word ":" ---
    ld hl, str_colon
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_colon_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == COLON_CFA
    ld iy, err_colon_cfa_mismatch
    ld de, COLON_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Execute ":" to create MYNEWWORD ---
    ; Set up IP to run COLON
    ld bc, test_ip_list
    jp NEXT

tib_content:
    db "MYNEWWORD "

str_colon:
    db 1
    db ":"

test_ip_list:
    dw COLON_CFA
    dw test_verify_colon

test_verify_colon:
    dw test_verify_code

test_verify_code:
    ; 1. Verify that length byte at $3000 is $89 (length 9)
    ld a, ($3000)
    ld l, a
    ld h, 0
    ld de, $89
    ld iy, err_len_mismatch
    call assert_de_hl

    ; 2. Verify that the CFA (at $300C) points to DOCOL
    ld hl, ($300C)
    ld de, DOCOL
    ld iy, err_cfa_not_docol
    call assert_de_hl

    ; 3. Verify that U_DP was updated to $300E (first cell of parameter field)
    ld hl, (USER_AREA_START + U_DP)
    ld de, $300E
    ld iy, err_dp_mismatch
    call assert_de_hl

    ; 4. Verify that U_STATE is 1 (compiling)
    ld a, (USER_AREA_START + U_STATE)
    ld l, a
    ld h, 0
    ld de, 1
    ld iy, err_state_not_compiling
    call assert_de_hl

    ; 5. Verify that U_CURRENT and U_CONTEXT are updated to $3000
    ld hl, (USER_AREA_START + U_CURRENT)
    ld de, $3000
    ld iy, err_current_mismatch
    call assert_de_hl

    ld hl, (USER_AREA_START + U_CONTEXT)
    ld de, $3000
    ld iy, err_context_mismatch
    call assert_de_hl

    jp pass_all

err_colon_not_found:     db "Colon word ':' not found", 0
err_colon_cfa_mismatch:  db "Colon CFA mismatch", 0
err_len_mismatch:        db "NFA length byte mismatch", 0
err_cfa_not_docol:       db "Word CFA does not point to DOCOL", 0
err_dp_mismatch:         db "U_DP not updated correctly", 0
err_state_not_compiling: db "U_STATE was not set to 1 (compiling)", 0
err_current_mismatch:   db "U_CURRENT was not set to new word address", 0
err_context_mismatch:   db "U_CONTEXT was not set to new word address", 0
