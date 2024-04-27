global temperature_asm

; Los pixeles se representan en memoria/registros como : 00000000 A R G B (0) | 00000000 A R G B (1)  

section .rodata:
    sub_a: times 8 dW 255       ; Mascara p/restar 255
section .data
    constant db 3

section .text
;void temperature_asm(unsigned char *src,      ->     rdi:=src
;              unsigned char *dst,             ->     rsi:=dst
;              int width,                      ->     rdx:=width
;              int height,                     ->     rcx:=height
;              int src_row_size,               ->     r8:=src_row_size
;              int dst_row_size);              ->     r9:=dst_row_size


temperature_asm:
    ;Prologo
    push rbp
    mov rbp,rsp     ; Stack alineada 

    movdqu xmm7,[sub_a]     ; Bajo mascara de restar 255

    ;Calculamos total de iteraciones
    mov rax,rdx
    shr rax,1               ; rax:width/2 -> #iteraciones por fila
    mul rcx         
    mov rcx,rax             ; rcx: #iteraciones en total


.ciclo:
    pmovzxdq xmm0,[rsi]     ; Bajo 2px a reg extendidos con zero como dw-packed data
    movdqu xmm1,xmm0        ; Copio en xmm1 

    ; calc_t toma como parametro al xmm0 := 00000000  A B G R (0) | 00000000  A B G R (1)
    call calc_t






    add rsi,8       ; Actualizo el puntero a los proximos 2 px
    loop .ciclo

    ;Epilogo
    pop rbp
    ret



; uint_16 calc_t(pixel_t *src1 , pixel_t *src2) xmm0:= 00000000 A R G B (0) | 00000000 A R G B (1) 
calc_t:
    ;Prologo
    push rbp
    mov rbp,rsp     ; Stack alineada
    pxor xmm3,xmm3

    ; Muevo a otros registros como qword para poder hacer el horizontal add
    pmovzxdq xmm2,xmm0      ; Muevo a xmmm2 el pixel 1 zero ext / c/componente ocupa 1 word
    pextrd rax,xmm0,2       ; Extraigo a rax , la segunda dword de xmm0 -> el pixel 0
    pinsrd xmm3,rax,0       ; Inserto pixer 0 en la parte baja de xmm3
    pmovzxdq xmm3,xmm3      ; Extiendo pixel 1 zero ext / c/componente ocupa 1 word

    ; Sumamos las componentes de c/pixel , restandole las 255 de A
    phaddw xmm2,xmm2
    phaddw xmm2,xmm2
    phaddw xmm3,xmm3
    phaddw xmm3,xmm3
    psubw xmm2,xmm7         ; xmm2:= ...|...| R+G+B pixel 1
    psubw xmm3,xmm7         ; xmm3:= ...|...| R+G+B pixel 0


    ;Falta dividir por 3 -> tengo que convertir a float , dividir y luego truncar...









    ;Epilogo
    pop rbp
    ret
