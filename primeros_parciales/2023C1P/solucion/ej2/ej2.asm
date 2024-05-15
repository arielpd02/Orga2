global miraQueCoincidencia


%define ALPHA_INDEX 11

%define LOW_DW_0 0x00
%define LOW_DW_1 0x01

%define HIGH_QW 0x01
%define LOW_QW 0x00

section .rodata:
         float_mask: dd 0.114,0.587,0.299,0
         all_255: times 16 db 255

;########### SECCION DE TEXTO (PROGRAMA)

section .text


;void miraQueCoincidencia_c( uint8_t *A, uint8_t *B, uint32_t N,uint8_t *laCoincidencia )
;                          rdi ; puntero a imagen A    rsi : puntero a imagen B   rdx: row/col  size rcx; puntero a imagen dst
miraQueCoincidencia:
    ;Prologo
    push rbp
    mov rbp,rsp

    ; Proceso 2px por iteracion -> (n*n)/2 iteraciones en total
    mov rax,rdx
    mul rdx 
    shr rax,1       ; rax : #iteraciones del ciclo

    movdqu xmm7,[float_mask]        ; Bajo mascara de floats para multiplicar
    movdqu xmm8,[all_255]

    .ciclo:
        pmovzxbw xmm1,[rdi]         ; xmm1:=  A R G B (1) | A R G B (0)
        movdqu xmm3,xmm1            ; Copio el registro
        pmovzxbw xmm2,[rsi]         ; xmm2:=  A R G B (1) | A R G B (0)
        movdqu xmm4,xmm2            ; Copio el registro

        ; Generar mascara de funcion
        pcmpeqq xmm3,xmm4           ; Si un A[ij]=B[ij] -> | 1 1 1 1 |


        ;P/convertir a grises , tengo que bajar cada pixel a un reg propio, para pasarlos a float

        pmovzxwd xmm5,xmm1            ; xmm5 tiene en cada dw 1 componente de pixel 0
        pextrq r10,xmm1,HIGH_QW
        pinsrq xmm4,r10,LOW_QW
        pmovzxwd xmm6,xmm4            ; xmm6 tiene en cada dw 1 componente de pixel 1  

        xor r9,r9                       
        pinsrd xmm5,r9d,ALPHA_INDEX            ; Limpio la componente Alpha a 0
        pinsrd xmm6,r9d,ALPHA_INDEX            ; Limpio la componente Alpha a 0

        
        ;Convierto las componentes en float

        cvtdq2ps xmm5,xmm5
        cvtdq2ps xmm6,xmm6

        ;Multiplico por valores de la funcion en xmm7

        mulps xmm5,xmm7
        mulps xmm6,xmm7

        ; Suma horizontal (de packed fp) para obtener el valor de gris

        haddps xmm5,xmm5
        haddps xmm5,xmm5

        haddps xmm6,xmm6
        haddps xmm6,xmm6

        ; Convierto el res a int_32 y despues en unsigned
        
        cvttps2dq xmm5,xmm5
        cvttps2dq xmm6,xmm6

        pabsd xmm5,xmm5
        pabsd xmm6,xmm6

        ;Extraigo el valor para pixel 1 y lo guardo en 2da dw de xmm5

        pextrd r10d,xmm6,LOW_DW_0
        pinsrd xmm5,r10d,LOW_DW_1            ; xmm5:= ...|...| RES 1 | RES 0

        ; Empaqueto los valores pero como bytes

        packusdw xmm5,xmm5
        packuswb xmm5,xmm5                  ; xmm5:= ..|..|..|..|..|..|..|..|..|..|..|..|..|RES1|RES 0

        ; Reduzco mascara del cmp a bytes

        pextrq r10,xmm3,HIGH_QW
        pinsrd xmm3,r10d,LOW_DW_1
        packssdw xmm3,xmm3
        packsswb xmm3,xmm3                  ; En los dos bytes menos significativos tengo mi mascara para aplicar al resultado anterior


        ; Combino resultados segun mascara

        movdqu xmm0,xmm3               ; Blend toma como registro 'selector' al xmm0 : si byte tiene 1 , tomo el pixel gris. CC, tiene 0 , tomo 255

        pblendvb xmm8,xmm5             ; Como dst xmm8 para pisar el byte si se cumple la condicion en xmm0 , tomo xmm5 como src


        ; Guardo los pix finales en imagen destino , manejo raro ya que lo minimo a mover es un DW

        sub rsp,8
        movq [rbp-8],xmm8
        mov r10d,dword[rbp-8]
        mov word [rcx],r10w
        add rsp,8

        ; Actualizo punteros y voy a la guarda

        add rdi,8           ; C/px ocupa 4 bytes
        add rsi,8           ; C/px ocupa 4 bytes    
        add rcx,2           ; C/px ocupa 1 byte

        dec rax
        cmp rax,0
        jne .ciclo


    ;epilogo
    pop rbp 
    ret



