%define SYS_WRITE 1
%define SYS_EXIT 60

section .text
    global _start
_start:
    mov rdx, len
    mov rsi, msg
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
section .data
    msg db 'Ariel Pineiro',0xa,'128/22',0xa,'Como me cuesta Orga :)',0xa
    len equ $ - msg 
section .debug