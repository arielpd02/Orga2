
global Pintar_asm

;void Pintar_asm(unsigned char *src,	-> rdi=src , puntero a pixel_t 4 bytes
;              unsigned char *dst,		-> rsi=dst	, idem en destino
;              int width,				-> rdc=width
;              int height,				-> rcx=height
;              int src_row_size,		-> r8=src_row_size
;              int dst_row_size);		-> r9=dst_row_size

; Los pixeles se bajan a registro en sentido inverso : xmmx:= A,B,G,R (3)| A,G,B,R (2) | A,G,B,R (1) | A,G,B,R (0)
; Registros disponibles s/usar stack ; rax,r10,r11

section .rodata:
	align 16
	black_paint: times 4 dd 0xff000000
	white_paint: times 4 dd 0xffffffff
	black_paint_high: times 2 dd 0xff000000
	black_paint_low: times 2 dd 0xffffffff

Pintar_asm:
	;Prologo
	push rbp
	mov rbp,rsp 	

	
	;Bajo mascaras
	movdqu xmm1,[black_paint]			; xmm1:= ff000000 | ... | ff000000
	movdqu xmm2,[white_paint]			; xmm2:= ffffffff | ... | ffffffff
	movdqu xmm3,[black_paint_high]		; xmm3:= ff000000 | ff000000 | ffffffff | ffffffff
	movdqu xmm4,[white_paint+8]			; xmm4:= ffffffff | ffffffff | ff000000 | ff000000 x contiguidad de memoria

	
	;Inicializo contadores y var de control de ciclo
	mov rax,rdx
	shr rax,4		; width/4 -> #iteraciones para procesar una fila
	mul rcx			; rax:= (width/4)*height
	mov rcx,rax		; rcx:= # iteraciones del ciclo 
	
	mov rax,rdx
	mul rcx
	mov r9,rax 		; r9:= #pixels

	mov rax,rdx		; rax:= width
	shl rax,1		; rax*=2 (#pixels en 2 filas)
	sub r9,rax		; r9:=#pixels-2filas de pixels

	xor r11,r11		; r11  -> pixel counter

	mov r10,rsi
	add r10,r8
	add r10,r8		; En r10 tengo puntero a [2,0]

	mov rdx,r10
	add rdx,r8
	sub rdx,16		; En rdx tengo puntero a [2,m-3], ultimos 4px de fila 2

.ciclo:
	;Filtramos segun fila en que estemos
	cmp rax,r11
	je .paint_white		; Si ya pinte los 2px borde inferior, pinto con blanco
	cmp r9,r11			
	jne .paint_white	; Si no pinte (n-2) filas , sigo con blanco
	jmp .paint_black	; Caso contrario , estamos en fila 0,1,n,n-1

.paint_white:
	cmp rsi,r10
	je .border_l 		; IF EQ entonces  ptr_actual == ptr_fila_anterior_inicio + |fila| -> inicio nueva fila
	cmp rsi,rdx 		; IF EQ entonces  ptr_actual == ptr_fila_anterior_final + |fila| -> final nueva fila
	je .border_r

	;CC,pintamos 4 pixeles de blanco
	movdqu [rsi],xmm2		

.paint_black:
	movdqu [rsi],xmm1 	; dst[rsi-rsi+16bytes]:= ff000000 | ... | ff000000
	jmp .end

.border_l:
	movdqu [rsi],xmm3	; Pinto 2px borde de negro , los otros 2 de blanco
	add r10,r8			; Marco en r10 un seed a la fila posterior

.border_r:
	movdqu [rsi],xmm4 	; Pinto 2px de blanco , 2px borde de negro
	add rdx,r8			; Actualizo el seed a la fila posterior

.end:
	add r11,4		; Cuento los 4 pixels procesados
	add rsi,16		; Actualizo el puntero

	loop .ciclo


	;Epilog
	pop rbp
	ret
	


