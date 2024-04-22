
section .text

global dot_product_asm

; uint32_t dot_product_asm(uint16_t *p, uint16_t *q, uint32_t length);
; implementacion simd de producto punto

; rdi=p 	rsi=q 	rdx=length

dot_product_asm:
	;Prologo
	push rbp
	mov rbp,rsp 		;Stack alineado a 16 bytes

	shr rdx,3			;rdx:=rdx/8
	mov rcx,rdx			;rcx:= #iter = length/8
	pxor xmm8,xmm8		;xmm8(=res):=0

	;Cuerpo del ciclo , podemos procesar 8 productos por iteracion
.ciclo:
	cmp rcx,0
	je .sum
	;Cargamos los registros
	movdqu xmm0,[rdi]		; xmm0:= p[7] | p[6] |	.	.	.	| p[1] |  p[0] 
	movdqu xmm1,[rsi]		; xmm1:= q[7] | q[6] |	.	.	.	| q[1] |  q[0]
	movdqu xmm2,xmm0		; Como voy a multiplcar dos vectores , los valores se pisan. Trabajo la parte alta con xmm2
							; xmm2:= p[7] | p[6] |	.	.	.	| p[1] |  p[0]

	;Multiplicamos p[i]*q[i]
	pmullw xmm0,xmm1		; xmm0:= p[7]*q[7]{15:0}  | p[6]*q[6]{15:0}  |	.	.	.	| p[1]*q[1]{15:0}  |  p[0]*q[0]{15:0}
	pmulhuw xmm2,xmm1		; xmm2:= p[7]*q[7]{31:16} | p[6]*q[6]{31:16} |	.	.	.	| p[1]*q[1]{31:16} |  p[0]*q[0]{31:16}
	movdqu xmm1,xmm0 		; Copio xmmo0->xmm1 para poder hacer el unpack

	;Juntamos los productos entre parte alta y parte baja
	punpcklwd xmm0,xmm2		; xmm0:=  p[3]*q[3] | p[2]*q[2] | p[1]*q[1] | p[0]*q[0] primeros 4
	punpckhwd xmm1,xmm2		; xmm1:=  p[7]*q[7] | p[6]*q[6] | p[5]*q[5] | p[4]*q[4] ultimos 4
	
	;Sumamos los elementos por componentes a xmm8
	paddd xmm8,xmm0			; xmm8:=  p[3]*q[3] +SUM3 | p[2]*q[2] + SUM2 | p[1]*q[1] + SUM1 | p[0]*q[0] + SUM0
	paddd xmm8,xmm1			; xmm8:=  p[7]*q[7] +SUM3 | p[6]*q[6] + SUM2 | p[5]*q[5] + SUM1 | p[4]*q[4] + SUM0
	
	;Volvemos a iterar con los proximos 8 elementos de p y q
	add rdi,16				; Actualizo puntero de p
	add rsi,16				; Actualizo puntero de q
	dec rcx					; rcx:-=1
	jmp .ciclo				; Vuelvo a la guarda
	
.sum:
	;Finalizado el ciclo , queda devolver la suma acumulada en componentes en xmm8
	phaddd xmm8,xmm8		; xmm8 = | ... | ... | SUM3+SUM2 | SUM1+SUM0 
	phaddd xmm8,xmm8 		; xmm8 = | ... | ... | ... | SUM3+SUM2+SUM1+SUM0
	movd eax,xmm8

	;dumb test
	;pxor xmm8,xmm8
	;pshufb xmm0,xmm8

	;Prologo
	pop rbp
	ret

.debug: