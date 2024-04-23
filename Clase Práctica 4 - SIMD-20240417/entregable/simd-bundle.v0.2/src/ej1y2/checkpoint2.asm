; En .rodata declaro las mascaras que voy a utilizar
section .rodata: 	
shuffle_h1: times 4 db 15 	;La mascara queda en posiciones contiguas de memoria
shuffle_h2: times 4 db 11
shuffle_h3: times 4 db 7
shuffle_h4: times 4 db 3
wipe_suit: times 16 db 15
count_hands: times 16 db 0xff

section .text

global four_of_a_kind_asm

; uint32_t four_of_a_kind_asm(card_t *hands, uint32_t n);
;								rdi=*hands 		rsi=n

four_of_a_kind_asm:
	;Prologo
	push rbp
	mov rbp,rsp					; Stack alineado a 16 bytes

	xor rax,rax 				; rax(=count):=0
	mov rcx,rsi					; rcx:= n (cant. de manos)
	shr rcx,2					; Divido por 4 / itero n/4 veces

	movdqu xmm7,[shuffle_h1]	; Bajo la mascara de shift a xmm7
	movdqu xmm6,[wipe_suit]		; Bajo la mascara de wipe-suit a xmm6
	movdqu xmm5,[count_hands]	; Bajo la mascara de '1s' a xmm5
	xor r8,r8					; r8(=partial_count):= 0

.ciclo:
	;Limpiamos el suit de cada carta , nos molesta para hacer comparaciones entre packed data
	movdqu xmm0,[rdi]	; xmm0:= M33 | M32 | M31 | M30 | M23 |.........| M10 | M03 | M02 | M01 | M00 (MANOxCARTAy) -> 16 cartas, 4 manos
	psrlw xmm0,4		; Desplazo 4 bits a derecha en cada word para luego aplicar mascara para wipear el suit de c/carta
	pand xmm0,xmm6		; xmm0:= 0V15 | 0V14 | .	.	.	| 0V1 | 0V0 -> En cada carta/byte nos queda solo el valor

	;Pintamos el c/mano del valor de la carta en el byte + significativo de esta
	movdqu xmm1,xmm0 	; Copio las cartas en xmm1 y trabajo con este registro
	pshufb xmm1,xmm7	; xmm1:= v15 | v15 | v15 | v15 | v14 | v14 | ... | v0 | v0 | v0 | v0 

	;Comparamos con mascara de '1s' para filtrar manos que no cumplen
	pcmpeqb xmm1,xmm0	; Comparo con los valores originales -> 0xffffffff si las cartas de una mano tienen el mismo valor
	pcmpeqw xmm1,xmm5	; Comparo de a doublewords -> 0xffffffff si la mano cumple , todo 0 sino  
	pabsd xmm1,xmm1		; Hago el valor absoluto , luego en cada dw/mano me queda 1 si cumple, 0 sino

	;Sumamos las manos obtenidas en xmm1
	phaddd xmm1,xmm1
	phaddd xmm1,xmm1 	; xmm1:= ... | ... | ... | #manos

	;Sumamos el resultado parcial a xmm4
	movd r8d,xmm1 		; r8d:= res + # manos
	add eax,r8d			; Acumulo la sol parcial en eax
	
	add rdi,16			; Actualizo el puntero de cartas

	loop .ciclo

	;Epilogo
	pop rbp
	ret

