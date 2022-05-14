global start
extern long_mode_start

section .text
bits 32
start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    ; set up paging

    call setup_page_tables
    call enable_paging

    lgdt [gdt64.pointer]
    jmp gdt64.code_segment:long_mode_start  ; jump to 64 bit code

    hlt

check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret

check_cpuid:    ; invert the 21 bit of the flags to check if cpu supports cpuid
    pushfd      ; push the flags into stack to get unmodified flags back later
    pop eax
    mov ecx, eax
    xor eax, 1 << 21        ; set 21 bit
    push eax
    pushfd
    pop eax
    push ecx
    popfd        ; return flags as it was from the stack
    cmp eax, ecx ; if the bit was not inverted, cpuid is not supported
    je .no_cpuid
    ret

check_long_mode:
    ; checkif cpuid supports extended proc info
    mov eax, 0x80000000
    cpuid               ; if yes cpuid stores a larger no in eax than the one we just moved into eax here
    cmp eax, 0x80000001
    jb .no_long_mode

    mov eax, 0x80000001
    cpuid               ; cpuid stores a value in edx
    test edx, 1 << 29   ;  if lm bit is set (1) long mode is available
    jz .no_long_mode
    ret

setup_page_tables:
    ; identity map physical add to virtual add
    mov eax, page_table_l3
    or eax, 0b11    ; present, writable
    mov [page_table_l4], eax

    mov eax, page_table_l2
    or eax, 0b11    ; present, writable
    mov [page_table_l3], eax

    ; for loop essentially
    mov ecx, 0      ; counter
.loop:
    mov eax, 0x200000 ; 2MiB
    mul ecx
    or eax, 0b10000011 ; present, writable, huge page
    mov [page_table_l2 + ecx * 8], eax

    inc ecx         ; increment counter
    cmp ecx, 512    ; checks if the whole table is mapped
    jne .loop       ; if not loop again

    ret

enable_paging:
    ; pass page table loc to cpu
    mov eax, page_table_l4
    mov cr3, eax

    ; enable physical address extension flag
    mov eax, cr4
    or eax, 1 << 5  ; Enable PAE flag, the fifth 5th bit
    mov cr4, eax

    ; finally enable long mode
    mov ecx, 0xC0000000
    rdmsr   ; read from model specific register
    or eax, 1 << 8  ; set the long mode bit
    wrmsr   ; write into model specific register (EFER register)

    ; enable paging
    mov eax, cr0
    or eax, 1<<31   ; set the paging bit
    mov cr0, eax

    ret

.no_multiboot:
    mov al, "M"
    jmp error


.no_cpuid:
    mov al, "C"
    jmp error

.no_long_mode:
    mov al, "C"
    jmp error

error:
    ; subroutine to print "ERR: X" where X is the error code
    mov dword [0xb8000], 0x4f524f45  ; first 4 bytes
    mov dword [0xb8004], 0x4f3a4f52  ; second 4 bytes
    mov dword [0xb8004], 0x4f204f20  ; second 4 bytes
    mov byte [0xb800a], al
    hlt



section .bss   ;contains static mem allocation
align 4096
page_table_l4:
    resb 4096
page_table_l3:
    resb 4096
page_table_l2:
    resb 4096

stack_bottom:
    resb 4096 * 4

stack_top:

section .rodata
gdt64:
    dq 0 ; zero entry
.code_segment: equ  $ - gdt64                         ; code segment offset
    dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)  ; set executable flag, desc type, present flag and 64bit flag
.pointer:
    dw $ - gdt64 -1 ; length of table -1 = end  - start label - 1
    dq gdt64    ; store the pointer to the table start with the label
