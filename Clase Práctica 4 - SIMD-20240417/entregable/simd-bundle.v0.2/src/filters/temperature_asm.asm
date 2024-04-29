global temperature_asm

; Los pixeles se representan en memoria/registros como : 00000000 A R G B (1) | 00000000 A R G B (0)  

section .rodata:
    div_constant: times 4 dd 3
    t_32: times 4 dd 32
    t_96: times 4 dd 96
    t_160:times 4 dd 160
    t_224: times 4 dd 224
    both_true: times 2 dd 0xffffffff , 0x00000000
    both_false: times 4 dd 0x00000000
    true_0: dd 0xffffffff,0x00000000
    times 2 dd 0x00000000

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
    pmovzxdq xmm0,[rsi]     ; Bajo 2px a reg extendidos con zero como dw-packed data
    movdqu xmm1,xmm0        ; Copio en xmm1 

    ; calc_t toma como parametro al xmm0 := 00000000 | A B G R (1) | 00000000 | A B G R (0)
    call calc_t
    ; Devuelve xmm0:= 0000000 | t(pixel_1) | 00000000 | t(pixel_0)

    ; Marco un seed para las T calculadas
    movdqu xmm2,xmm0







    add rsi,8       ; Actualizo el puntero a los proximos 2 px
    loop .ciclo

    ;Epilogo
    pop rbp
    ret



; uint_16 calc_t(pixel_t *src1 , pixel_t *src2) xmm0:= 00000000 A R G B (1) | 00000000 A R G B (0) 
calc_t:
    ;Prologo
    push rbp
    mov rbp,rsp             ; Stack alineada
    pxor xmm3,xmm3
    pxor xmm7,xmm7

    ; Muevo a otros registros como qword para poder hacer el horizontal add
    pmovzxbd xmm2,xmm0      ; Muevo a xmmm2 el pixel 0 zero ext / c/componente ocupa 1 dword
    pextrd r10d,xmm2,3       ; Extraigo a r10 el valor de la componente A  de pixel 0

    pextrd eax,xmm0,2       ; Extraigo a rax , la segunda dword de xmm0 -> el pixel 1
    pinsrd xmm3,eax,0       ; Inserto pixel 1 en la parte baja de xmm3
    pmovzxbd xmm3,xmm3      ; Extiendo pixel 1 zero ext / c/componente ocupa 1 dword
    pextrd r11d,xmm3,3       ; Extraigo a r11 el valor de la componente A de pixel 1

    ; Sumamos las componentes de c/pixel
    phaddd xmm2,xmm2
    phaddd xmm2,xmm2
    phaddd xmm3,xmm3
    phaddd xmm3,xmm3

    ;Restamos el valor de A correspondiente
    pinsrd xmm7,r10d,0       ; Bajo a xmm7 pixel_0->A
    psubd xmm2,xmm7          ; xmm2:= ...|...| R+G+B pixel_0
    pinsrd xmm7,r11d,0       ; Bajo a xmm7 pixel_1->A
    psubd xmm3,xmm7          ; xmm3:= ...|...| R+G+B pixel_1

    ;Junto todo en xmm0
    pextrd eax,xmm2,0
    pinsrd xmm0,eax,0
    pextrd eax,xmm3,0
    pinsrd xmm0,eax,1       ; xmm0:= 00000000 | 00000000 | R+G+B pixel_1 | R+G+B pixel_0

    ;Falta dividir por 3 -> tengo que convertir a float , dividir y luego truncar...
    cvtpi2ps xmm6,mm6     ; Convierto la constante 3 a float
    cvtpi2ps xmm0,mm0     ; Convierto a float las sumas

    divps xmm0,xmm6       ; xmm0:= 00000000 | 00000000 | R+G+B pixel_1 / 3 | R+G+B pixel_0 / 3
    cvttps2pi mm0,xmm0    ; xmm0:= 00000000 | 00000000 | ~ R+G+B pixel_1 / 3 | ~ R+G+B pixel_0 / 3  (truncado)

    ;Devuelvo el res de pixel_0 a la 2 posicion de xmm0
    pextrd eax,xmm0,1
    pinsrd xmm0,eax,2     ; xmm0:= 00000000 | ~R+G+B pixel_1 / 3 | 00000000 | ~R+G+B pixel_0 / 3


    ;Epilogo
    pop rbp
    ret
