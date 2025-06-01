; =============================================================================
; pForth - Z80 CPU Memory Layout & Constants Configuration
; =============================================================================
; This file defines the memory map and system constants for the Z80 target.
; It aligns with the classic pFORTH layout specifications.
; z80asm-compatible syntax.

; -----------------------------------------------------------------------------
; Memory Segments & Base Addresses
; -----------------------------------------------------------------------------

; Zero Page ($0000 - $00FF)
; Reserved for Z80 interrupt vectors, restart (RST) locations, and core boot entry points.
ZERO_PAGE_START: equ $0000

; User Area Base Address
; Contains the task-specific variables (STATE, BASE, DP, S0, etc.)
USER_AREA_START: equ $E000
USER_AREA_SIZE:  equ $0040   ; 64 bytes is typical for pFORTH user area

; Terminal Input Buffer (TIB) ($0100 - $01FF)
; Stores character sequences read from port 1 (z88dk-ticks -iochar=1).
TIB_START:       equ $0100
TIB_SIZE:        equ 128     ; 128 bytes buffer size (80 characters minimum)

; Forth Dictionary Area ($0400 - $7FFF)
; The dictionary grows upwards from this boundary towards high memory.
DICTIONARY_START: equ $0400

; Data Stack (Parameter Stack) ($F000 - $F7FF)
; Grows downwards. S0 points to the bottom (highest memory address of the stack area).
DATA_STACK_BOTTOM: equ $F800  ; S0 - initial stack pointer (starts at $F800, grows down)

; Return Stack (RSP) ($F800 - $FFFF)
; Uses Z80 native SP register. Grows downwards.
; R0 points to the bottom of the return stack.
RETURN_STACK_BOTTOM: equ $0000 ; R0 - native SP wraps to $FFFF on first push

; -----------------------------------------------------------------------------
; z88dk-ticks character I/O (z88dk-ticks -iochar=1)
; -----------------------------------------------------------------------------
TTY_DATA_PORT:       equ 1      ; getchar / putchar on port 1

; -----------------------------------------------------------------------------
; User Area Variable Offsets (Offsets from User Pointer - UP)
; -----------------------------------------------------------------------------
; Standard pFORTH user variables structure.
U_S0:       equ 0            ; Bottom of data stack (2 bytes)
U_R0:       equ 2            ; Bottom of return stack (2 bytes)
U_TIB:      equ 4            ; Terminal input buffer pointer (2 bytes)
U_WIDTH:    equ 6            ; Max name length stored in headers (1 byte)
U_WARNING:  equ 7            ; Warning control flag (1 byte)
U_FENCE:    equ 8            ; Memory protection boundary (2 bytes)
U_DP:       equ 10           ; Dictionary pointer (2 bytes)
U_VOC_LINK: equ 12           ; Vocabulary link pointer (2 bytes)
U_BASE:     equ 14           ; Numeric conversion base (1 byte, e.g., 10 or 16)
U_STATE:    equ 15           ; Compilation state (1 byte, 0 = interpreting, non-zero = compiling)
U_CURRENT:  equ 16           ; Vocabulary being defined into (2 bytes)
U_CONTEXT:  equ 18           ; Vocabulary searched first (2 bytes)
U_IN:       equ 20           ; Input buffer offset (2 bytes)
U_OUT:      equ 22           ; Output cursor position (2 bytes)
U_SCR:      equ 24           ; Current block screen number (2 bytes)
U_SPAN:     equ 26           ; Number of characters read by EXPECT (2 bytes)
