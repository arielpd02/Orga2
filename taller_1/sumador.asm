%define SYS_WRITE 1
%define SYS_EXIT 60

.text:
    global _start
_start:
    xor al,al ; Limpio el registro al de 8bits
    mov al,[n0] ; cargo n0
    add al,[n1] ;cargo n1
    mov rdi,1   ; En rdi , se escribira lo q' sale opr stdOut
    syscall     ; aviso al procesador
    mov rdi,0
    mov rax,SYS_EXIT
    syscall
.data:
    n0 db 45
    n1 db 40
.debug:    