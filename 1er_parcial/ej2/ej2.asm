global YUYV_to_RGBA

; Trabajo de a 2px por iteracion de manera que cada px me ocupa un reg xmmx , ya que tengo que 
; realizar operaciones operando con floats => para no perder precision lo hago de manera 
; independiente con cada ergistro y luego guardo el resultado contiguo en memoria.

%define SHUFFLE_PX_0 0b11000100
%define SHUFFLE_PX_1 0b11100110

%define ALPHA_BYTE_INDEX 0b0011
%define ALPHA 255

section .rodata:
    cmp_error: dd 0,127,0,127
    mask_for_error: times 4 db 127,255,0,255 
    
    todos_128: times 4 dd 128
    wipe_y: dd -1,0,-1,0
    wipe_all_but_g: dd 0,-1,0,0

    red_blue_mask: dd 1.370705,0,1.732446,0
    green_mask_1: dd 0,-0.337633,0,0
    green_mask_2: dd 0,-0.698001,0,0




;########### SECCION DE TEXTO (PROGRAMA)
section .text

;void YUYV_to_RGBA( int8_t *X, uint8_t *Y, uint32_t width, uint32_t height);
;                       RDI X     RSI Y     RDX width           RCX height
YUYV_to_RGBA:
    ;Prologo
    push rbp
    mov rbp,rsp

    ; Calculamos #iteraciones , la imagen de dst tiene el doble de width y procesamos 2 px por iteraciones.
    ; Iteramos width*height veces
    mov rax,rcx
    mul rdx
    
    mov rcx,rdx     ; Parte alta en rdx[63:32], baja en eax
    mov ecx,eax     ; rcx tiene # iteraciones

    movdqu xmm15,[cmp_error]
    movdqu xmm12,[todos_128]
    movdqu xmm11,[wipe_y]
    movdqu xmm10,[wipe_all_but_g]

    movdqu xmm5,[red_blue_mask]
    movdqu xmm4,[green_mask_1]
    movdqu xmm3,[green_mask_2]

    pxor xmm14,xmm14
    pxor xmm9,xmm9
    pxor xmm8,xmm8

    .ciclo:
        pmovsxbd xmm0,dword [rdi]     ; Bajo 2px , c/componente ext a dw con signo
        movdqu xmm1,xmm0               

        pshufd xmm0,xmm0,SHUFFLE_PX_0       ; xmm0 : v | y1 | u | y1 
        pshufd xmm1,xmm1,SHUFFLE_PX_1       ; xmm1 : v | y2 | u | y2
        
        ;Comparo si u y v son 127 . Si eso sucede , los px tienen error, voy directo a ese caso.    
        pcmpeqq xmm14,xmm14                 ; xmm14 : all ones

        movdqu xmm6,xmm0
        pcmpeqd xmm6,xmm15                   ; xmm6: 1 | ... | 1 | ... si hay error 
        pshufd xmm6,xmm6,0b11_11_01_01       ; Desplazo el res del cmp 
        pxor xmm6,xmm14                      ; Si hay error , queda todo en 0
        ptest xmm6,xmm6                      ; Chequeo si xmm6 es todo 0
        jz .error_en_px

        ;En primer lugar , inicializamos el reg RES -> la base de todas las componentes es Y (salvo alpha en 0)
        movdqu xmm8,xmm0            
        movdqu xmm9,xmm1            
        
        pshufd xmm8,xmm8,0b11_00_00_00      ; xmm8 tiene res parcial de pixel 0 -> 0 | Y | Y | Y
        pshufd xmm9,xmm9,0b11_00_00_00      ; xmm9 tiene res parcial de pixel 1 -> 0 | Y | Y | Y

        ;Restamos a u y v 128 y alineo a componentes R/G/B para operar

        psubd xmm0,xmm12

        pshufd xmm0,xmm0,0b11_01_01_11
        pshufd xmm7,xmm0,0b11_10_00_00
        pshufd xmm6,xmm0,0b11_10_10_00      ; A | B | G | R

        pand xmm0,xmm11               ; xmm0: 0 | U | 0 | V
        pand xmm7,xmm10               ; xmm7: 0 | 0 | V | 0
        pand xmm6,xmm10               ; xmm6: 0 | 0 | U | 0

        
        ; Convertimos a float , multiplicamos y luego sumamos.

        cvtdq2ps xmm8,xmm8
        cvtdq2ps xmm9,xmm9

        cvtdq2ps xmm0,xmm0
        cvtdq2ps xmm7,xmm7
        cvtdq2ps xmm6,xmm6      

        mulps xmm0,xmm5               ; xmm0: 0 | U*1.73.. | 0 | V*1,37..
        mulps xmm7,xmm3               ; xmm7: 0 | 0 | V *-0.69.. | 0
        mulps xmm6,xmm4               ; xmm6: 0 | 0 | U *-0.33.. | 0

        addps xmm8,xmm0
        addps xmm8,xmm7
        addps xmm8,xmm6               ; xmm8: 0 | Y + U*1.73.. | Y - V*0.69.. - U*0.33.. | Y+ V*1,37..

        addps xmm9,xmm0
        addps xmm9,xmm7
        addps xmm9,xmm6               ; xmm9: 0 | Y + U*1.73.. | Y - V*0.69.. - U*0.33.. | Y+ V*1,37..

        ;Convertimos a uint y tomamos valor absoluto para poder empaquetar

        cvttps2dq xmm8,xmm8
        cvttps2dq xmm9,xmm9

        pabsd xmm8,xmm8
        pabsd xmm9,xmm9

        ; Empaquetamos dw->w->b y agregamos valor Alpha

        xor rax,rax
        mov al,ALPHA

        packusdw xmm8,xmm8
        packuswb xmm8,xmm8
        pinsrb xmm8,al,ALPHA_BYTE_INDEX        ; xmm8: ... | ... | ... | A G B R (0)

        packusdw xmm9,xmm9
        packuswb xmm9,xmm9          
        pinsrb xmm9,al,ALPHA_BYTE_INDEX        ; xmm9: ... | ... | ... | A G B R (1)

        ; Desplazamos el pixel 1 a la parte alta de mm9 y colocamos el pixel 0 en la parte baja

        xor rax,rax
        psllq xmm9,32
        pextrd eax,xmm8,0
        pinsrd xmm9,eax,0           ; xmm9: ... | ... | A G B R (1)| A G B R (0)

        jmp .load

        .error_en_px:   

        ;Guardamos en reg RES los px a devolver en formato rgba
        movdqu xmm9,[mask_for_error]   ; xmm9: 255|255|0|127| ... |255|255|0|127

        .load:

        ; Guardamos en memoria y avanzamos los punteros
        movq [rsi],xmm9

        add rdi,4       ; Miro los proximos 2 px de src
        add rsi,8       ; Avanzo a los prox 2 px en dst 
        dec rcx         ; rcx--

        cmp rcx,0
        jne .ciclo


    ;Epilogo
    pop rbp
    ret









;No pude continuar con este ejercicio debido a fallas que me hicieron demorar en el medio del examen con mi computadora que no respondia , lo cual paso varias veces. Pero la logica esta , no llegue a bajarlo a ASM :(

;He aqui mi idea , voy a procesar de a 2 pixeles `puesto que tengo que operar con sumas y operaciones con float.
;1)Bajo 2px a un xmmx y los reacomodo de manera que cada qw sea un pixel con extension con signo. |v|y2|u|y2|v|y1|u|y1| reacomodados con un blend.
;2)Comparo si u yv son 127 y me guardo esta mascara de igualda para aplicar al final
;3) Realizo las siguiente operaciones:
;	i) Restamos a u y v 128 con un mask
;	ii)genero mascara de V para lo .R .G y .B
;	*Shifteo a  der c/DW 16 bits sin signo 
;	* Aplico mascara p/wipear valores :
;		|0|V|0|U|0|V|0|U|= xmmx
;	*Sumo ctes. A u `para .B y a V para .R
;	*genero otra copia del xmmx shifteo a der c/qw 2 bytes . En la otra shifteo a izq. c/qw 2 bytes
;	Y me quedan dos registros que solo tiene V y U en .G respectivamente
;	*Luego cvt a float y multiplico x ctes.
;	* Despues sumo 
;	iii) Despues de operaciones -> mascara del cmp de 2) y aplico la mascara para los pixeles errados .

