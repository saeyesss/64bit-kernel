global long_mode_start
extern kernel_main

section  .text
bits 64

long_mode_start: ; set data segment registers to 0
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ;; print 'OK'
    ; mov dword [0xb8000], 0x2f4b2f4f

    ; C funciton
    call kernel_main
    hlt