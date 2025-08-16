; =============================================================================
; pForth - Z80 VARIABLE Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "VARIABLE" ---
    ld hl, str_variable
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_variable_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == VARIABLE_CFA
    ld iy, err_variable_cfa_mismatch
    ld de, VARIABLE_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Create a variable 'MYVAR' ---
    ; 1. Copy string "MYVAR " to TIB
    ld hl, str_myvar_raw
    ld de, TIB_START
    ld bc, 6
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

    ; 4. Put dummy value in TOS (DE)
    ld de, $1234
    
    ; 5. Set up IP to run VARIABLE and then verify_creation
    ld bc, ip_list_variable
    jp NEXT

verify_creation:
    ; Restore stack pointer after VARIABLE execution
    ld ix, (saved_dsp)

    ; --- TEST 3: Find the created word 'MYVAR' ---
    ld hl, str_myvar_counted
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)

    ; Save found CFA
    push hl
    push af

    ; Assert status == 1 (found)
    pop af
    ld iy, err_myvar_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    ld (saved_myvar_cfa), bc
    ld (ip_run_cfa), bc

    ; --- TEST 4: Execute 'MYVAR' ---
    ; 1. Push anchor $9999
    dec ix
    ld (ix+0), $99
    dec ix
    ld (ix+0), $99

    ; 2. Put dummy value in TOS (DE)
    ld de, $1234

    ; 3. Run MYVAR (via saved_myvar_cfa patched in ip_run_cfa) and then verify_execution
    ld bc, ip_list_run_myvar
    jp NEXT

verify_execution:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains the address of MYVAR's PFA (which is saved_myvar_cfa + 2)
    ld hl, (saved_myvar_cfa)
    inc hl
    inc hl                      ; HL = PFA address
    ld (saved_pfa_addr), hl

    ld hl, (saved_tos)
    ld de, (saved_pfa_addr)
    ld iy, err_myvar_addr_incorrect
    call assert_de_hl

    ; 2. Verify that the initial value at PFA address is 0
    ld hl, (saved_pfa_addr)
    ld a, (hl)
    ld e, a
    inc hl
    ld a, (hl)
    ld d, a                     ; DE = value at PFA
    ld hl, 0
    ld iy, err_myvar_val_incorrect
    call assert_de_hl

    ; 3. Verify that DSP (IX) is initial_dsp - 4 (anchor and old TOS $1234 remain in stack memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 4. Verify that the old TOS $1234 remains on the stack (at IX + 0)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $1234
    ld iy, err_old_tos_corrupted
    call assert_de_hl

    ; 5. Verify that the anchor value $9999 remains on the stack (at IX + 2)
    ld a, (ix+2)
    ld l, a
    ld a, (ix+3)
    ld h, a
    ld de, $9999
    ld iy, err_anchor_corrupted
    call assert_de_hl

    jp pass_all

saved_dsp:
    dw 0
saved_tos:
    dw 0
saved_myvar_cfa:
    dw 0
saved_pfa_addr:
    dw 0

str_variable:
    db 8
    db "VARIABLE"

str_myvar_raw:
    db "MYVAR "

str_myvar_counted:
    db 5
    db "MYVAR"

ip_list_variable:
    dw VARIABLE_CFA
    dw verify_creation_stub

verify_creation_stub:
    dw verify_creation_code

verify_creation_code:
    jp verify_creation

ip_list_run_myvar:
ip_run_cfa:
    dw 0
    dw verify_execution_stub

verify_execution_stub:
    dw verify_execution_code

verify_execution_code:
    jp verify_execution

err_variable_not_found:           db "Word 'VARIABLE' not found", 0
err_variable_cfa_mismatch:        db "VARIABLE CFA mismatch", 0
err_myvar_not_found:              db "Created word 'MYVAR' not found", 0
err_myvar_addr_incorrect:         db "Execution of 'MYVAR' returned incorrect address (expected PFA)", 0
err_myvar_val_incorrect:          db "Initial value of 'MYVAR' is not 0", 0
err_old_tos_corrupted:            db "Old TOS pushed to stack was corrupted", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
