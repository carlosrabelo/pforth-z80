; =============================================================================
; pForth - Z80 Inner Interpreter (NEXT, DOCOL, SEMI)
; =============================================================================
; This file implements the core execution engine (Inner Interpreter) for Z80.
; It uses Indirect Threaded Code (ITC) representation.
; z80asm-compatible syntax.
;
; Register Usage:
;   BC - IP (Instruction Pointer)
;   SP - RSP (Return Stack Pointer, native stack)
;   IX - DSP (Data Stack Pointer)
;   DE - TOS (Top of Stack cache)
;   HL - W (Working register)
;   IY - Temporary address register for execution dispatch
;   A  - Scratch register

; -----------------------------------------------------------------------------
; NEXT
; -----------------------------------------------------------------------------
; Fetches the next word address (CFA) pointed to by IP (BC), advances IP,
; loads the target code address into IY, and dispatches to it.
;
; Optimization Note:
;   On dispatch, HL (W) is left pointing to (CFA + 1) to save cycles.
;   Consequently, routines that need the Parameter Field Address (PFA, which is
;   at CFA + 2) only need to increment HL once (INC HL) instead of twice.
; -----------------------------------------------------------------------------
NEXT:
    ; Fetch CFA (Code Field Address) from compilation list at IP (BC)
    ld a, (bc)
    ld l, a
    inc bc
    ld a, (bc)
    ld h, a
    inc bc          ; BC (IP) now points to the next cell in the list

    ; Read the actual machine code address from (HL) into IY
    ld a, (hl)
    ld iyl, a       ; Lower byte of code address
    inc hl          ; Move HL to point to CFA + 1 (High byte of code address)
    ld a, (hl)
    ld iyh, a       ; Upper byte of code address

    ; Jump to the code address. HL is left pointing to (CFA + 1).
    jp (iy)

; -----------------------------------------------------------------------------
; Inner Interpreter Core Routines
; -----------------------------------------------------------------------------

; DOCOL - Enter Colon Definition
; Called when executing a word defined by ':' (colon).
; Saves the current IP on the return stack and sets IP to the word's PFA.
DOCOL:
    push bc         ; Push current IP (BC) onto the return stack (RSP)
    inc hl          ; Advance HL from (CFA + 1) to (CFA + 2) which is the PFA
    ld b, h         ; Move PFA (HL) to IP (BC)
    ld c, l
    jp NEXT         ; Dispatch the first word in this colon definition

; SEMI (often named EXIT or ;S)
; Called at the end of a colon definition to return to the caller.
; Restores the previous IP from the return stack.
SEMI:
    pop bc          ; Pop previous IP (BC) from the return stack (RSP)
    jp NEXT            ; Continue execution of the calling word
