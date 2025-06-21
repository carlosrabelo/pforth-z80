; =============================================================================
; pForth - Z80 Inner Interpreter (NEXT, DOCOL, SEMI) Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; Initialize our execution counter
    ld hl, 0
    ld (test_counter), hl

    ; Set up the IP (BC) to point to our test thread list
    ld bc, test_ip_list

    ; Start the inner interpreter
    jp NEXT

test_counter:
    dw 0

; The IP list contains the thread to execute, followed by the halt/verify word.
test_ip_list:
    dw test_thread
    dw test_halt_word

; The test thread is a colon definition that calls a sub-word and returns.
test_thread:
    dw DOCOL
    dw test_sub_word
    dw test_semi_cfa

test_semi_cfa:
    dw SEMI

; The sub-word points to its code field.
test_sub_word:
    dw test_sub_code

test_sub_code:
    ; Increment our execution counter
    ld hl, (test_counter)
    inc hl
    ld (test_counter), hl
    jp NEXT

; The halt/verify word stops execution and asserts correctness.
test_halt_word:
    dw test_halt_code

test_halt_code:
    ; Verify that test_counter was incremented exactly once (indicating DOCOL/SEMI worked)
    ld hl, (test_counter)
    ld de, 1
    ld iy, err_inner_fail
    call assert_de_hl

    ; Verify that the native SP (Return Stack Pointer) is empty/back to bottom
    ld hl, RETURN_STACK_BOTTOM
    ; We can't easily read SP into HL directly in Z80, but we can do:
    ld hl, 0
    add hl, sp                  ; HL = SP
    ld de, RETURN_STACK_BOTTOM
    ld iy, err_rsp_not_empty
    call assert_de_hl

    jp pass_all

err_inner_fail:    db "Inner interpreter execution failed", 0
err_rsp_not_empty: db "RSP not empty after SEMI", 0
