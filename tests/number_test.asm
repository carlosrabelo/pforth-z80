; =============================================================================
; pForth - Z80 NUMBER Primitive Test
; =============================================================================
    include "tests/test_helper.asm"

test_entry:
    ; --- TEST 1: Convert positive decimal "123" ---
    ld hl, str_123
    push hl
    pop iy                  ; IY = address of "123"
    call NUMBER_internal    ; Returns BC:HL = 32-bit val, A = unconverted count
    
    ; Save results
    push hl                 ; Save low word
    push bc                 ; Save high word
    push af                 ; Save status count

    ; Assert A == 0 (unconverted character count)
    pop af
    ld iy, err_123_count
    ld de, 0
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Assert BC == 0 (high word of 123)
    pop bc
    ld iy, err_123_high
    ld de, 0
    ld l, c
    ld h, b
    call assert_de_hl

    ; Assert low word == 123
    pop hl
    ld iy, err_123_low
    ld de, 123
    call assert_de_hl

    ; --- TEST 2: Convert negative decimal "-456" ---
    ld hl, str_neg_456
    push hl
    pop iy
    call NUMBER_internal

    ; Save results
    push hl                 ; Save low word
    push bc                 ; Save high word
    push af                 ; Save status count

    ; Assert A == 0
    pop af
    ld iy, err_neg_456_count
    ld de, 0
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Assert BC == $FFFF (high word of -456 in 32-bit)
    pop bc
    ld iy, err_neg_456_high
    ld de, $FFFF
    ld l, c
    ld h, b
    call assert_de_hl

    ; Assert low word == $FE38 (lower 16 bits of -456)
    pop hl
    ld iy, err_neg_456_low
    ld de, $FE38
    call assert_de_hl

    ; --- TEST 3: Convert "1A" in decimal (base 10) ---
    ld a, 10
    ld (USER_AREA_START + U_BASE), a

    ld hl, str_1A
    push hl
    pop iy
    call NUMBER_internal

    ; Save results
    push hl                 ; Save low word
    push bc                 ; Save high word (ignore BC actually, but keeps stack clean)
    push af                 ; Save status count

    ; Assert A == 1 (since 'A' cannot be converted in base 10)
    pop af
    ld iy, err_1A_base10_count
    ld de, 1
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Clean BC from stack
    pop bc

    ; Assert low word == 1 (only "1" is converted)
    pop hl
    ld iy, err_1A_base10_low
    ld de, 1
    call assert_de_hl

    ; --- TEST 4: Convert "1A" in hex (base 16) ---
    ld a, 16
    ld (USER_AREA_START + U_BASE), a

    ld hl, str_1A
    push hl
    pop iy
    call NUMBER_internal

    ; Save results
    push hl                 ; Save low word
    push bc                 ; Save high word
    push af                 ; Save status count

    ; Assert A == 0
    pop af
    ld iy, err_1A_base16_count
    ld de, 0
    ld l, a
    ld h, 0
    call assert_de_hl

    ; Clean BC
    pop bc

    ; Assert low word == 26 ($1A)
    pop hl
    ld iy, err_1A_base16_low
    ld de, 26
    call assert_de_hl

    ; Restore BASE = 10
    ld a, 10
    ld (USER_AREA_START + U_BASE), a

    ; If we reach here, all tests in this file passed!
    jp pass_all

str_123:
    db 3
    db "123"
str_neg_456:
    db 4
    db "-456"
str_1A:
    db 2
    db "1A"


; Error messages
err_123_count:       db "123 count nz", 0
err_123_high:        db "123 high nz", 0
err_123_low:         db "123 low ne", 0
err_neg_456_count:   db "-456 count nz", 0
err_neg_456_high:    db "-456 high ne", 0
err_neg_456_low:     db "-456 low ne", 0
err_1A_base10_count: db "1A base 10 count ne 1", 0
err_1A_base10_low:   db "1A base 10 low ne 1", 0
err_1A_base16_count: db "1A base 16 count nz", 0
err_1A_base16_low:   db "1A base 16 low ne 26", 0
