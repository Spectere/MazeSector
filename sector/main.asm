[bits 16]
[org 0x7C00]

; =============================================================================
;  Code
; =============================================================================

    xor ax, ax  ; Clear any required segments.
    mov ds, ax

    cli
    mov si, sHelloWorld
    mov ah, 0x0E  ; Print character
    mov bh, 0x00  ; Page number
    mov bl, 0x07  ; Color

print_loop:
    mov al, [si]
    inc si
    or al, al
    jz done
    int 0x10      ; Video interrupt
    jmp print_loop

done:
    hlt


; =============================================================================
;  Data
; =============================================================================

sHelloWorld:    db "Hello world!", 0


; =============================================================================
;  Boot Signature
; =============================================================================

    times 510-($-$$) db 0  ; Padding
    dw 0xAA55
