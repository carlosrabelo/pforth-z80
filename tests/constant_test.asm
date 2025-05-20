; =============================================================================
; pForth - Z80 CONSTANT Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Find word "CONSTANT" ---
    ld hl, str_constant
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)
    
    ; Save found CFA
    push hl
    push af

    ; Assert status == 1
    pop af
    ld iy, err_constant_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    
    ; Assert HL == CONSTANT_CFA
    ld iy, err_constant_cfa_mismatch
    ld de, CONSTANT_CFA
    ld l, c
    ld h, b
    call assert_de_hl

    ; --- TEST 2: Create a constant 'MYCONST' with value $ABCD ---
    ; 1. Copy string "MYCONST " to TIB
    ld hl, str_myconst_raw
    ld de, TIB_START
    ld bc, 8
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

    ; 4. Put value $ABCD in TOS (DE)
    ld de, $ABCD
    
    ; 5. Set up IP to run CONSTANT and then verify_creation
    ld bc, ip_list_constant
    jp NEXT

verify_creation:
    ; Restore stack pointer after CONSTANT execution
    ld ix, (saved_dsp)

    ; --- TEST 3: Find the created word 'MYCONST' ---
    ld hl, str_myconst_counted
    push hl
    pop iy
    call FIND_internal      ; Returns HL = CFA, A = status (1 = found)

    ; Save found CFA
    push hl
    push af

    ; Assert status == 1 (found)
    pop af
    ld iy, err_myconst_not_found
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Pop found CFA into BC
    pop bc
    ld (saved_myconst_cfa), bc
    ld (ip_run_cfa), bc

    ; --- TEST 4: Execute 'MYCONST' ---
    ; 1. Push anchor $9999
    dec ix
    ld (ix+0), $99
    dec ix
    ld (ix+0), $99

    ; 2. Put dummy value in TOS (DE)
    ld de, $1234

    ; 3. Run MYCONST (via saved_myconst_cfa) and then verify_execution
    ld bc, ip_list_run_myconst
    jp NEXT

verify_execution:
    ; Save final TOS (DE) before running assertions
    ld (saved_tos), de

    ; 1. Verify that TOS contains the constant value $ABCD
    ld hl, (saved_tos)
    ld de, $ABCD
    ld iy, err_myconst_value_incorrect
    call assert_de_hl

    ; 2. Verify that DSP (IX) is initial_dsp - 4 (anchor and old TOS $1234 remain in stack memory)
    ld hl, (saved_dsp)
    dec hl
    dec hl
    dec hl
    dec hl
    ld iy, err_dsp_mismatch
    call assert_ix_hl

    ; 3. Verify that the old TOS $1234 remains on the stack (at IX + 0)
    ld a, (ix+0)
    ld l, a
    ld a, (ix+1)
    ld h, a
    ld de, $1234
    ld iy, err_old_tos_corrupted
    call assert_de_hl

    ; 4. Verify that the anchor value $9999 remains on the stack (at IX + 2)
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
saved_myconst_cfa:
    dw 0

str_constant:
    db 8
    db "CONSTANT"

str_myconst_raw:
    db "MYCONST "

str_myconst_counted:
    db 7
    db "MYCONST"

ip_list_constant:
    dw CONSTANT_CFA
    dw verify_creation_stub

verify_creation_stub:
    dw verify_creation_code

verify_creation_code:
    jp verify_creation

ip_list_run_myconst:
    ; Place the CFA of the created MYCONST here dynamically
    ; We do this by loading it in verify_creation and patching this word,
    ; or we can just patch it using memory write before NEXT.
    ; Since Z80 is in RAM, we can patch ip_list_run_myconst + 0!
    ; But wait, we can just compile it. Let's patch it:
    ; In verify_creation we write saved_myconst_cfa to ip_list_run_myconst!
    ; In step 3 we will do that.
    ; Let's reserve 2 bytes here.
ip_run_cfa:
    dw 0
    dw verify_execution_stub

verify_execution_stub:
    dw verify_execution_code

verify_execution_code:
    jp verify_execution

err_constant_not_found:           db "Word 'CONSTANT' not found", 0
err_constant_cfa_mismatch:        db "CONSTANT CFA mismatch", 0
err_myconst_not_found:            db "Created word 'MYCONST' not found", 0
err_myconst_value_incorrect:      db "Execution of 'MYCONST' returned incorrect value (expected $ABCD)", 0
err_old_tos_corrupted:            db "Old TOS pushed to stack was corrupted", 0
err_dsp_mismatch:                 db "DSP (IX) at incorrect offset", 0
err_anchor_corrupted:             db "Anchor value on stack was corrupted", 0
