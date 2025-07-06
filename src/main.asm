; =============================================================================
; pForth - Z80 Main Entry Point & Bootstrap
; =============================================================================

    org $0000
    jp start                    ; Address $0000 (RST 00)
    defs 5                      ; Pad to $0008

    jp QUIT_restart             ; Address $0008 (RST 08)
    defs 5                      ; Pad to $0010

    jp QUIT_restart             ; Address $0010 (RST 10)
    defs 5                      ; Pad to $0018

    jp QUIT_restart             ; Address $0018 (RST 18)
    defs 5                      ; Pad to $0020

    jp QUIT_restart             ; Address $0020 (RST 20)
    defs 5                      ; Pad to $0028

    jp QUIT_restart             ; Address $0028 (RST 28)
    defs 5                      ; Pad to $0030

    jp QUIT_restart             ; Address $0030 (RST 30)
    defs 5                      ; Pad to $0038

    jp QUIT_restart             ; Address $0038 (RST 38)
    defs 5                      ; Pad to $0040 (starts bootloader)

    ; Include configuration constants (does not emit code bytes)
    include "src/config.asm"

    ; -------------------------------------------------------------------------
    ; Bootstrap Entry Points (Zero Page Free Space starting at $0040)
    ; -------------------------------------------------------------------------
start:
    di                          ; Disable interrupts during setup
    ld sp, RETURN_STACK_BOTTOM  ; Initialize Return Stack (RSP)
    ld ix, DATA_STACK_BOTTOM    ; Initialize Data Stack (DSP)
    ld de, 0                    ; Initialize Top of Stack cache (TOS)
    jp cold_start

cold_start:
    ; Initialize User Area variables in RAM
    ld hl, DATA_STACK_BOTTOM
    ld (USER_AREA_START + U_S0), hl
    
    ld hl, RETURN_STACK_BOTTOM
    ld (USER_AREA_START + U_R0), hl
    
    ld hl, TIB_START
    ld (USER_AREA_START + U_TIB), hl
    
    ; DP (Dictionary Pointer) starts at the first free memory location after dictionaries
    ld hl, FORTH_FREE_MEM
    ld (USER_AREA_START + U_DP), hl
    
    ld a, 10                    ; Base 10 (decimal) by default
    ld (USER_AREA_START + U_BASE), a
    
    xor a
    ld (USER_AREA_START + U_STATE), a
    
    ld hl, 0
    ld (USER_AREA_START + U_IN), hl
    ld (USER_AREA_START + U_OUT), hl

    ld hl, LAST_NFA
    ld (USER_AREA_START + U_CURRENT), hl
    ld (USER_AREA_START + U_CONTEXT), hl

    ; Jump to QUIT console loop
    jp QUIT_code
cold_start_end:

    ; Padding to align Forth Dictionary exactly at $0400
    defs $0400 - cold_start_end

; -----------------------------------------------------------------------------
; Forth Dictionary Segment
; -----------------------------------------------------------------------------
    include "src/inner.asm"
    include "src/io.asm"
    include "src/control.asm"
    include "src/stack.asm"
    include "src/memory.asm"

; -----------------------------------------------------------------------------
; Dictionary Entry Point configuration
; -----------------------------------------------------------------------------
LAST_NFA: equ STORE_NFA

; -----------------------------------------------------------------------------
; End of Assembly-compiled Forth. Next memory is dynamically allocated.
; -----------------------------------------------------------------------------
FORTH_FREE_MEM:
