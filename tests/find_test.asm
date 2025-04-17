; =============================================================================
; pForth - Z80 FIND Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find existing word "KEY" ---
    ld hl, str_key
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save results
    push hl                 ; Save CFA
    push af                 ; Save status

    ; Assert status A == 1
    pop af
    ld iy, err_key_status
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Assert HL == KEY_CFA
    pop hl
    ld iy, err_key_cfa
    ld de, KEY_CFA
    call assert_de_hl

    ; --- TEST 2: Find existing word "FIND" ---
    ld hl, str_find
    push hl
    pop iy
    call FIND_internal

    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_find_status
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Assert HL == FIND_CFA
    pop hl
    ld iy, err_find_cfa
    ld de, FIND_CFA
    call assert_de_hl

    ; --- TEST 3: Find non-existing word "UNKNOWN" ---
    ld hl, str_unknown
    push hl
    pop iy
    call FIND_internal

    push hl
    push af

    ; Assert status == 0
    pop af
    ld iy, err_unknown_status
    ld de, 0
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Assert HL == original string address (str_unknown)
    pop hl
    ld iy, err_unknown_addr
    ld de, str_unknown
    call assert_de_hl

    ; If we reach here, all tests in this file passed!
    jp pass_all

; Counted strings
str_key:
    db 3
    db "KEY"
str_find:
    db 4
    db "FIND"
str_unknown:
    db 7
    db "UNKNOWN"

; Error messages
err_key_status:     db "KEY status ne 1", 0
err_key_cfa:        db "KEY cfa mismatch", 0
err_find_status:    db "FIND status ne 1", 0
err_find_cfa:       db "FIND cfa mismatch", 0
err_unknown_status: db "UNKNOWN status nz", 0
err_unknown_addr:   db "UNKNOWN addr mismatch", 0
