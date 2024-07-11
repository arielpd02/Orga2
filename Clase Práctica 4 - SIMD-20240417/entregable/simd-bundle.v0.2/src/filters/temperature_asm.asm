global temperature_asm

;Ya varie el orden de los factores , probe con double/single y es indiferente.
;   -La logica de casos tendría que ser el error , no lo encuentro.

section .rodata:
    a_mask: dw 0xffff, 0xffff, 0xffff, 0x0000, 0xffff, 0xffff, 0xffff, 0x0000
    c_mask: dw 0xffff, 0x0000, 0xffff, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    divisor: dd 3, 3


    all_ones: times 16 db 0xff
    div_constant: times 4 dd 3
    t_32: times 8 dw 31
    t_96: times 8 dw 95
    t_160: times 8 dw 159
    t_224: times 8 dw 223

    ; Defino mascaras para aplicar sobre t1|...|t0 acumulativamente
    lt_32_mul: times 2 dw 4,0,0,0
    lt_32_sum: times 2 dw 128,0,0,255

    btw_32_96_dif: times 2 dw 0,32,0,0
    btw_32_96_mul: times 2 dw 0,4,0,0
    btw_32_96_sum: times 2 dw 255,0,0,255

    btw_96_160_dif: times 2 dw 96,0,96,0
    btw_96_160_mul: times 2 dw -4,0,4,0
    btw_96_160_sum: times 2 dw 255,255,0,255

    btw_160_224_dif: times 2 dw 0,160,0,0
    btw_160_224_mul: times 2 dw 0,-4,0,0
    btw_160_224_sum: times 2 dw 0,255,255,255

    geqt_224_dif: times 2 dw 0,0,224,0
    geqt_224_mul: times 2 dw 0,0,-4,0
    geqt_224_sum: times 2 dw 0,0,255,255


   
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
    movdqu xmm4,[all_ones]
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

    pmovzxbw xmm0,qword [rdi]     ; Bajo 2px a reg extendidos con zero como qw-packed data (C/componente ocupa 1 word)
    movdqu xmm1,xmm0              ; Copio en xmm1  

    ; calc_t toma como parametro al xmm0 := A R G B (1) | A R G B (0)
    call calc_t_aux

    ; Devuelve xmm0:= | t1 | t1 | t1 | t1 | t0 | t0 | t0 | t0 
    ; Trabajo cada ti como si fuera una componente propia del pixel i / al final tengo los pixeles ya procesados
    ; Voy a ir acumulando resultados , pisando si ti no cumple cierta condicion 

    call pintar
    ; xmm0 = FF | dst_r(1) | dst_g(1) | dst_b(1) | FF | dst_r(0) | dst_g(0) | dst_b(0)

    packuswb xmm0,xmm0  ; Compacto los words en bytes ->  dst<px1> | dst<px0> | dst<px1> | dst<px0>
    movd [rsi],xmm0

    add rsi,8       ; Actualizo el puntero a los proximos 2 px
    add rdi,8       ; Tambien hay q actualizar el de la imagen original :)
    loop .ciclo

    ;Epilogo
    pop rbp
    ret




; el cmpGT es dst >? src : 1s si se cumple, 0s sino.
; pandn -> ¬dst AND src

pintar:
    ;Prologo
    push rbp
    mov rbp,rsp

    ; Mi resultado final lo construyo en xmm11.
    pxor xmm10,xmm10
    pxor xmm11,xmm11

    ;Copio el valor original de t0 y t1
    movdqu xmm5,xmm0    ; xmm5:= t1 | t1 | t1 | t1 | t0 | t0 | t0 | t0 

    .less_than_32:

    movdqu xmm2,xmm5
    pcmpgtw xmm2,xmm12  ; t >= 32 ? 1 : 0
    pxor xmm2,xmm4      ; xmm2:= 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 si t1 cumple y t0 no (i.e) . Mask de la comparacion t<32

    ; Aplico mascaras de t<32
    movdqu xmm1,[lt_32_mul]        ; xmm1: tiene mask para multiplicar por 4 la componente B
    call multiply                  ; xmm0: 0 | 0 | 0 | t1*4 | 0 | 0 | 0 | t0*4
    movdqu xmm1,[lt_32_sum]
    paddw xmm0,xmm1                ; xmm0: 255 | 0 | 0 |128 + t1*4 | 255 | 0 | 0 | 128 + t0*4

    ;¿Que pixel cumple? -> aplico xmm2
    pand xmm2,xmm0
    por xmm11,xmm2                 ; xmm2 :=  0 | 0 | 0 | 0 | 255 | 0 | 0 |128 + t1*4  si t1  no cumple y t0 si.


    .btw_32_96:

    movdqu xmm0,xmm5                ; Recupero valor de t

    ;Comparo ti<96 y ti>=32

    movdqu xmm2,xmm5
    movdqu xmm3,xmm5
    pcmpgtw xmm2,xmm12            ; xmm2 tiene 1s si t>=32
    pcmpgtw xmm3,xmm13            ; xmm3 tiene 1s si t>=96
    pandn xmm3,xmm2               ; xmm3 tiene 1s <=> t>=32 and t<96


    ; Aplico mascaras de  32<=t<96
    movdqu xmm1,[btw_32_96_dif]
    psubw xmm0,xmm1               ; xmm0: 0 | t1-32 | 0 | 0 | 0 | t0-32 | 0 | 0
    movdqu xmm1,[btw_32_96_mul]
    call multiply                 ; xmm0 : 0 | 0 | t1-32 *4 | 0 | 0 | 0 | t0-32 * 4 | 0 
    movdqu xmm1,[btw_32_96_sum]
    paddw xmm0,xmm1

    ; Filtro px que no cumpla

    pand xmm0,xmm3
    por xmm11,xmm0                  ; xmm0 := 255 | 0 | t1-32 *4 | 255 | 0 | 0 | 0 | 0  si t1 cumple y t0 no (i.e)

    .btw_96_160:

    movdqu xmm0,xmm5                ; Recupero valor de t

    ;Comparo ti<160 y ti>=96

    movdqu xmm2,xmm5
    movdqu xmm3,xmm5
    pcmpgtw xmm2,xmm13            ; xmm2 tiene 1s si t>=96
    pcmpgtw xmm3,xmm14            ; xmm3 tiene 1s si t>=160
    pandn xmm3,xmm2               ; xmm3 tiene 1s <=> t>=96 and t<160


    ; Aplico mascaras de  96<=t<160

    movdqu xmm1,[btw_96_160_dif]
    psubw xmm0,xmm1                 ; xmm0: t1 | t1-96 | t1 | t1-96 | t0 | t0-96 | t0 | t0-96
    movdqu xmm1,[btw_96_160_mul]
    call multiply                   ; xmm0 : 0 | t1-96 * 4 | 0 | (t1-96) * -4 | 0 | t0-96 * 4 | 0 | (t0-96) *-4
    movdqu xmm1,[btw_96_160_sum]
    paddw xmm0,xmm1

    ; Filtro px que no cumpla

    pand xmm0,xmm3
    por xmm11,xmm0                  ; xmm0 :=  255 | t1-96 * 4 | 255 | 255 + (t1-96) * -4 | 0 | 0 | 0 | 0  si t1 cumple y t0 no (i.e)

    .btw_160_224:

    movdqu xmm0,xmm5                ; Recupero valor de t

    ;Comparo ti<224 y ti>=160

    movdqu xmm2,xmm5
    movdqu xmm3,xmm5
    pcmpgtw xmm2,xmm14            ; xmm2 tiene 1s si t>=160
    pcmpgtw xmm3,xmm15            ; xmm3 tiene 1s si t>=224
    pandn xmm3,xmm2               ; xmm3 tiene 1s <=> t>=160 and t<224


    ; Aplico mascaras de  160<=t<224

    movdqu xmm1,[btw_160_224_dif]
    psubw xmm0,xmm1                 ; xmm0: 0 | 0 | t1-160 | 0 | 0 | 0 | t0-160 | 0 
    movdqu xmm1,[btw_160_224_mul]
    call multiply                   ; xmm0 : 0 | 0 | (t1-160) *- 4  | 0 | 0 | 0 | (t0-160) * -4 | 0 
    movdqu xmm1,[btw_160_224_sum]
    paddw xmm0,xmm1

    ; Filtro px que no cumpla

    pand xmm0,xmm3
    por xmm11,xmm0                   ; xmm0 :=  255 | 255 |255 + (t1-160) * -4  | 0 | 0 | 0 | 0 | 0 si t1 cumple y t0 no

    .geqt_224:

    movdqu xmm0,xmm5

    ; Comparo t1>=224

    movdqu xmm2,xmm5
    pcmpgtw xmm2,xmm15            ; xmm2 tiene 1s <=> t>=224

    ; Aplico mascara de t>=224

    movdqu xmm1,[geqt_224_dif]
    psubw xmm0,xmm1               ; xmm0: 0 | t1-224 | 0 | 0 | 0 | t0-224 | 0 | 0 
    movdqu xmm1,[geqt_224_mul]
    call multiply                 ; xmm0: 0 | (t1-224) * -4 | 0 | 0 | 0 | (t0-224) * -4 | 0 | 0 
    movdqu xmm1,[geqt_224_sum]
    paddw xmm0,xmm1

    ;Filtro px que no cumpla

    pand xmm0,xmm2
    por xmm11,xmm0                ; xmm0:=  255 | 255 + (t1-224) * -4 | 0 | 0 | 0 | 0 | 0 | 0  , si t1 cumple y t0 no

    
.end:

    movdqu xmm0,xmm11
    ;Epilogo
    pop rbp
    ret





; xmm0:= t1 | t1 | t1 | t1 | t0 | t0 | t0 | t0 
; xmm1:= mask_mul
multiply:
    ; Multiplies 8 words in xmm0 by 8 words in xmm1
    ; Returning 8 words in xmm0. The multiplications
    ; involved are such that, when it's relevant to do
    ; them, we are not losing precision, whereas the
    ; other pixel will contain rubbish that is going
    ; to be filtered out.
    push rbp
    mov rbp, rsp
    
    movdqu xmm9, xmm0
    pmulhw xmm9, xmm1
    pmullw xmm0, xmm1
    movdqu xmm1, xmm0

    punpckhwd xmm0, xmm9
    punpcklwd xmm1, xmm9

    packssdw xmm1, xmm0
    movdqu xmm0, xmm1

    pop rbp
    ret

;Modifico que sea con ps y no con double
calc_t_aux:
    push rbp
    mov rbp, rsp
    movdqu xmm7,[divisor]
    cvtdq2ps xmm2,xmm7

    ; Sum in 16 bits because 255 * 3 wouldn't fit in 8 bits
    movdqu xmm7,[a_mask]
    pand xmm0, xmm7
    phaddw xmm0, xmm0
    phaddw xmm0, xmm0
    punpcklwd xmm0, xmm0
    movdqu xmm7,[c_mask]
    pand xmm0, xmm7    ; | t1 | 0 | t2 | 0 | 0 | 0 | 0 | 0 |

    cvtdq2ps xmm0, xmm0    ; Convert dword ints to single
    divps xmm0, xmm2       ; Packed single division
    cvttps2dq xmm0, xmm0   ; Convert packed singles to dword ints with truncation
    punpcklwd xmm0, xmm0   ; Broadcast result
    movdqu xmm2, xmm0
    psllq xmm2, 32
    por xmm0, xmm2

    ; We are returning:
    ; xmm0 = | t1 | t1 | t1 | t1 | t2 | t2 | t2 | t2 |
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

    ; Borramos A de c/pixel
    movdqu xmm2,[a_mask]
    pand xmm0,xmm2


    ; Suma horizontal
    phaddw xmm0,xmm0
    phaddw xmm0,xmm0        ; xmm0:= ... | ... | ... | (R+G+B) PX1 | (R+G+B) PX0

    ;Junto todo en xmm0 , extendiendo las sumas a DW
    pmovzxwd xmm0,xmm0

    ;Falta dividir por 3 -> tengo que convertir a float , dividir y luego truncar... Solo puedo operar con dwords
    cvtdq2ps xmm0,xmm0      ; Los convierto en Sp floats
    divps xmm0,xmm6         ; Divido c/suma
    cvttps2dq xmm0,xmm0     ; Trunco el resultado -> TODO
    ; xmm0:= ? | ? | sum1/3 | sum0/3

    ;Reconstruyo las words
    movdqu xmm7,xmm0
    psllq xmm7,64           ; xmm7:= sum1/3 | sum0/3 | ? | ? 
    packusdw xmm0,xmm7      ; xmm0:=  t1 | t0 | ? | ? | ? | ? | t1 | t0
    movdqu xmm7,xmm0
    pshufhw xmm0,xmm7,0b11111111
    movdqu xmm7,xmm0
    pshuflw xmm0,xmm7,0b00000000

    ;Epilogo
    pop rbp
    ret
