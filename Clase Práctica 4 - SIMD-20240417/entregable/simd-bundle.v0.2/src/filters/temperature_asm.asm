global temperature_asm

; Los pixeles se representan en memoria/registros como : 00000000 A B G R (1) | 00000000 A B G R (0)  

section .data

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

    ;Calculamos total de iteraciones
    mov rax,rdx
    shr rax,1       ; rax:width/2 -> #iteraciones por fila
    mul rcx         
    mov rcx,rax     ; rcx: #iteraciones en total


.ciclo:
    pmovzxdq xmm0,[rsi]     ; Bajo 2px a reg extendidos con zero como dw-packed data
    movdqu xmm1,xmm0        ; Copio en xmm1 

    ; calc_t toma como parametro al xmm0 := 00000000  A B G R (1) | 00000000  A B G R (0)
    call calc_t






    add rsi,8       ; Actualizo el puntero a los proximos 2 px
    loop .ciclo

    ;Epilogo
    pop rbp
    ret



; uint_16 calc_t(pixel_t *src1 , pixel_t *src2) xmm0
calc_t:
    ;Prologo
    push rbp
    mov rbp,rsp     ; Stack alineada








    ;Epilogo
    pop rbp
    ret
