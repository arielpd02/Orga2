extern sumar_c
extern restar_c

;########### SECCION DE DATOS
section .data

;########### SECCION DE TEXTO (PROGRAMA)
section .text
;########### LISTA DE FUNCIONES EXPORTADAS

global alternate_sum_4
global alternate_sum_4_simplified
global alternate_sum_8
global product_2_f
global product_9_f
global alternate_sum_4_using_c

;########### DEFINICION DE FUNCIONES
; uint32_t alternate_sum_4(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[rdi], x2[rsi], x3[rdx], x4[rcx]
alternate_sum_4:
	;prologo
	push rbp
	mov rbp,rsp ; Stack alineado a 16 bytes
	
	; COMPLETAR
	mov rax,rdi
	sub rax,rsi
	add rax,rdx
	sub rax,rcx

	;recordar que si la pila estaba alineada a 16 al hacer la llamada
	;con el push de RIP como efecto del CALL queda alineada a 8

	;epilogo
	pop rbp ; luego de esta linea rsp->rip
	; COMPLETAR
	ret     ; luego de esta linea rip:= [rsp]

; uint32_t alternate_sum_4_using_c(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[rdi], x2[rsi], x3[rdx], x4[rcx]
alternate_sum_4_using_c:
	;prologo
	push rbp 	  ; alineado a 16
	mov rbp,rsp

	; COMPLETAR
	call restar_c ; por convencion rax:=x1-x2
	mov r8,rax    ; guardo el valor de sumar_c
	mov rdi,rdx
	mov rsi,rcx
	call restar_c ; rax:= x3-x4
	mov rdi,r8
	mov rsi,rax
	call sumar_c

	;epilogo
	pop rbp
	ret



; uint32_t alternate_sum_4_simplified(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4);
; registros: x1[rdi], x2[rsi], x3[rdx], x4[rcx]
alternate_sum_4_simplified:

	call restar_c ; por convencion rax:=x1-x2
	mov r8,rax    ; guardo el valor de sumar_c
	mov rdi,rdx
	mov rsi,rcx
	call restar_c ; rax:= x3-x4
	mov rdi,r8
	mov rsi,rax
	call sumar_c
	ret


; uint32_t alternate_sum_8(uint32_t x1, uint32_t x2, uint32_t x3, uint32_t x4, uint32_t x5, uint32_t x6, uint32_t x7, uint32_t x8);
; registros y pila: x1[rdi], x2[rsi], x3[rdx], x4[rcx], x5[r8], x6[r9], x7[rbp+0x10], x8[rbp+0x18]
alternate_sum_8:
	;prologo
	push rbp
	mov rbp,rsp			;Stack alineado a 16

	; COMPLETAR
	mov rax,rdi			; rax=x1
	sub rax,rsi			; x1=-x2
	sub rdx,rcx			; x3=-x4
	add rax,rdx			; x1+=x3
	sub r8,r9			; x5=-x6
	add rax,r8			; x1+=x5
	mov rdi,[rbp+0x10]	; rdi=x7
	sub rdi,[rbp+0x18]	; x7=-x8
	add rax,rdi



	;epilogo
	pop rbp
	ret


; SUGERENCIA: investigar uso de instrucciones para convertir enteros a floats y viceversa
;void product_2_f(uint32_t * destination, uint32_t x1, float f1);
;registros: destination[rdi], x1[rsi], f1[xmm0]
product_2_f:
	;Epilogo
	push rbp
	mov rbp,rsp			;Stack alineado a 16

	cvtsi2ss xmm1,rsi	;Convierto un uint_32 -> float
	mulss xmm0,xmm1		;Multiplico float(x1) con f1
	cvttss2si eax,xmm0	;Convierto el producto (float) como int truncado , en eax puesto que es de uint32_t
	mov [rdi],eax		;Guardo en destination el producto
		
	;Prolog
	pop rbp
	ret


;extern void product_9_f(uint32_t * destination
;, uint32_t x1, float f1, uint32_t x2, float f2, uint32_t x3, float f3, uint32_t x4, float f4
;, uint32_t x5, float f5, uint32_t x6, float f6, uint32_t x7, float f7, uint32_t x8, float f8
;, uint32_t x9, float f9);
;registros y pila: destination[rdi], x1[rsi], f1[xmm0], x2[rdx], f2[xmm1], x3[rcx], f3[xmm2], x4[r8], f4[xmm3]
;	, x5[r9], f5[xmm4], x6[rbp+16], f6[xmm5], x7[rbp+24], f7[xmm6], x8[rbp+32], f8[xmm7],
;	, x9[rbp+40], f9[rbp+48]
product_9_f:
	;prologo
	push rbp
	mov rbp, rsp 		; Stack alineado a 16 bytes

	;convertimos los flotantes de cada registro xmm en doubles
	; COMPLETAR
	cvtss2sd xmm0,xmm0
	cvtss2sd xmm1,xmm1
	cvtss2sd xmm2,xmm2
	cvtss2sd xmm3,xmm3
	cvtss2sd xmm4,xmm4
	cvtss2sd xmm5,xmm5
	cvtss2sd xmm6,xmm6
	cvtss2sd xmm7,xmm7

	;multiplicamos los doubles en xmm0 <- xmm0 * xmm1, xmmo * xmm2 , ...
	; COMPLETAR
	mulsd xmm0,xmm1
	mulsd xmm0,xmm2
	mulsd xmm0,xmm3
	mulsd xmm0,xmm4
	mulsd xmm0,xmm5
	mulsd xmm0,xmm6
	mulsd xmm0,xmm7
	cvtss2sd xmm1,[rbp+48]	; Convierto a double f9 pasado por stack, usando xmm1
	mulsd xmm0,xmm1

	; convertimos los enteros en doubles y los multiplicamos por xmm0.
	; COMPLETAR
	cvtsi2sd xmm1,rsi
	mulsd xmm0,xmm1
	cvtsi2sd xmm2,rdx
	mulsd xmm0,xmm2
	cvtsi2sd xmm3,rcx
	mulsd xmm0,xmm3
	cvtsi2sd xmm4,r8
	mulsd xmm0,xmm4
	cvtsi2sd xmm5,r9
	mulsd xmm0,xmm5
	cvtsi2sd xmm6,[rbp+16]
	mulsd xmm0,xmm6
	cvtsi2sd xmm7,[rbp+24]
	mulsd xmm0,xmm7
	cvtsi2sd xmm1,[rbp+32]	; A partir de aca reutilizo el registro xmm1 / me quede sin reg xmm
	mulsd xmm0,xmm1
	cvtsi2sd xmm1,[rbp+40]
	mulsd xmm0,xmm1

	movsd [rdi],xmm0


	; epilogo
	pop rbp
	ret

.debug:
