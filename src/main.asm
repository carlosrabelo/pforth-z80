; =============================================================================
; pForth - Z80 Main Entry Point & Bootstrap
; =============================================================================

    org $0000
    jp start                    ; Address $0000 (RST 00)

start:
    di                          ; Disable interrupts during setup
    halt
