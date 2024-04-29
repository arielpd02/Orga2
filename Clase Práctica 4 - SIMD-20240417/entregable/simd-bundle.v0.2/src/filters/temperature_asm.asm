global temperature_asm

; Los pixeles se representan en memoria/registros como : 00000000 A R G B (1) | 00000000 A R G B (0)  

%define reconstruct 0x10100000

section .rodata:
    all_ones: times 16 db 0xff
    div_constant: times 4 dd 3
    t_32: times 8 dw 31
    t_96: times 8 dw 95
    t_160: times 8 dw 159
    t_224: times 8 dw 223

    ; Defino mascaras para aplicar sobre t1|...|t0 acumulativamente
    lt_32_mul: times 2 dw 4,0,0,0
    lt_32_sum: times 2 dw 128,0,0,0

    btw_32_&_96_dif: times 2 dw 0,32,0,0
    btw_32_&_96_mul: times 2 dw 0,4,0,0
    btw_32_&_96_sum: times 2 dw 255,0,0,0

    btw_96_&_160_dif: times 2 dw 96,0,96,0
    btw_96_&_160_mul: times 2 dw -4,0,4,0
    btw_96_&_160_sum: times 2 dw 255,255,0,0

    btw_160_&_224_dif: times 2 dw 0,160,0,0
    btw_160_&_224_mul:  times 2 dw 0,-4,0,0
    btw_160_&_224_sum:  times 2 dw 0,255,255,0

    geqt_224_dif: times 2 dw 0,0,224,0
    geqt_224_mul: times 2 dw 0,0,-4,0
    geqt_224_sum: times 2 dw 0,0,255,0


   
    ;reconstruct: db 0x10100000

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

    ;Bajo mascaras a registros
    movdqu xmm6,[div_constant]      ; Bajo a registro el valor 3 para la division
 
    movdqu xmm12,[t_32]             
    movdqu xmm13,[t_96]             
    movdqu xmm14,[t_160]            
    movdqu xmm15,[t_224]            


    ;Calculamos total de iteraciones
    mov rax,rdx
    shr rax,1               ; rax:width/2 -> #iteraciones por fila
    mul rcx         
    mov rcx,rax             ; rcx: #iteraciones en total


.ciclo:

    pmovzxbw xmm0,[rsi]     ; Bajo 2px a reg extendidos con zero como qw-packed data (C/componente ocupa 1 word)
    movdqu xmm1,xmm0        ; Copio en xmm1  

    ; calc_t toma como parametro al xmm0 := A B G R (1) | A B G R (0)
    call calc_t
    ; Devuelve xmm0:= | t1 | t1 | t1 | t1 | t0 | t0 | t0 | t0 

    call pintar



    add rsi,8       ; Actualizo el puntero a los proximos 2 px
    loop .ciclo

    ;Epilogo
    pop rbp
    ret




pintar:
    ;Prologo
    push rbp
    mov rbp,rsp

    ;Copio el valor original de t0 y t1
    movdqu xmm5,xmm0

.lessthan_32:
    movdqu xmm2,xmm0
    pcmpgtw xmm2,xmm12              ; Si habia 1s, alguno es mayor , voy a la proxima "guarda"
    pxor xmm2,[all_ones]            ; XOR me wipea 1s -> luego testeo con PTEST
    ptest xmm2,xmm2                 ; Setea el ZF en 0 si todos 0s al hacer un AND
    jz .between_96_&_32             ; IF eran 0s -> ninguno cumplia ser menor y sigo

    movdqu xmm1,[lt_32_mul]         ; X convencion de llamada
    call multiplicar





.between_96_&_32:







    ;Epilogo
    pop rbp
    ret



; xmm0:= t1 | t1 | t1 | t1 | t0 | t0 | t0 | t0 
; xmm1:= mask_mul
multiplicar:
    ;Prologo
    push rbp
    mov rbp,rsp

    movdqu xmm8,xmm0
    pmulhw xmm8,xmm1        ; La parte alta del producto en xmm8
    pmullw xmm0,xmm1        ; La parte baja del producto en xmm0
    movdqu xmm1,xmm0        ; Copio en xmm1 para hacer el unpack

    punpcklwd xmm0,xmm8     ; xmm0:= 00000000| 00000000 | 00000000 | t0*4
    punpckhwd xmm1,xmm8     ; xmm1:= 00000000| 00000000 | 00000000 | t1*4

    pextrw rax,xmm1,0
    pinsrw xmm0,rax,4       ; xmm0:= 0000 | 0000| 0000 | t1*4 | 0000 | 0000 | 0000 | t0*4


    ;Epilogo
    pop rbp
    ret

; uint_16 calc_t(pixel_t *src1 , pixel_t *src2) xmm0:= A R G B (1) | A R G B (0) 
calc_t:     ;Funca!!
    ;Prologo
    push rbp
    mov rbp,rsp             ; Stack alineada
    pxor xmm3,xmm3
    pxor xmm7,xmm7
    pxor xmm2,xmm2
    cvtdq2ps xmm6,xmm6      ; Convierto el divisor en float

    ; Muevo a otros registros para poder hacer el horizontal add, extraigo A para restar
    pextrq rax,xmm0,0
    pinsrq xmm2,rax,0       ; xmm2:= 0000 | A R G B (0)
    pextrw r10,xmm2,3       ; r10:= A(0)
    pextrq rax,xmm0,1
    pinsrq xmm3,rax,0       ; xmm3:= 0000 | A R G B (0)
    pextrw r11,xmm3,3       ; r11:= A(1)


    ; Sumamos las componentes de c/pixel
    phaddw xmm2,xmm2
    phaddw xmm2,xmm2
    phaddw xmm3,xmm3
    phaddw xmm3,xmm3

    ;Restamos el valor de A correspondiente
    pinsrw xmm7,r10,0       ; Bajo a xmm7 pixel_0->A
    pshuflw xmm7,xmm7,0     ; xmm7:= ... |  A A A A (0)
    psubw xmm2,xmm7         ; xmm2:= ...|(R+G+B)(R+G+B)(R+G+B)(R+G+B) pixel_0 
    
    pinsrw xmm7,r11,0       ; Bajo a xmm7 pixel_1->A
    pshuflw xmm7,xmm7,0     ; xmm7:= ... |  A A A A (1)
    psubw xmm3,xmm7         ; xmm3:= ...|(R+G+B)(R+G+B)(R+G+B)(R+G+B) pixel_1

    ;Junto todo en xmm0
    pextrq rax,xmm2,0
    pinsrq xmm0,rax,0
    pextrq rax,xmm3,0
    pinsrq xmm0,rax,1       ; xmm0:= (R+G+B)(R+G+B)(R+G+B)(R+G+B) pixel_1 | (R+G+B)(R+G+B)(R+G+B)(R+G+B) pixel_0

    ;Falta dividir por 3 -> tengo que convertir a float , dividir y luego truncar... Solo puedo operar con dwords
    pslld xmm0,16           ; xmm0:= 00000000 (R+G+B)(1)| 00000000 (R+G+B) (1)| 00000000 (R+G+B)(0) | 00000000 (R+G+B)(0) 
    psrld xmm0,16            ; Borro la 'basura' acumulada por los adds y subs
    cvtdq2ps xmm0,xmm0      ; Los convierto en Sp floats
    divps xmm0,xmm6
    cvttps2dq xmm0,xmm0     ; xmm0:= 00000000 (R+G+B)/3 (1)| 00000000 (R+G+B)/3 (1)| 00000000 (R+G+B)/3 (0) | 00000000 (R+G+B)/3 (0) 

    ;Reconstruyo las words
    pshuflw xmm0,xmm0,reconstruct
    pshufhw xmm0,xmm0,reconstruct   ;xmm0:= t1 | t1 | t1 | t1 | t0 | t0 | t0 | t0 


    ;Epilogo
    pop rbp
    ret
