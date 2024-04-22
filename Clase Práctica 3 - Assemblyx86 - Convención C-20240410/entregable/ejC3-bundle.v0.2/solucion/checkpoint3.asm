%define NULL 0	
;########### ESTOS SON LOS OFFSETS Y TAMAÑO DE LOS STRUCTS
; Completar:

NODO_LENGTH	EQU	32				; Longitud del struct nodo
LONGITUD_OFFSET	EQU	24			; Offset del atributo longitud

PACKED_NODO_LENGTH	EQU	21
PACKED_LONGITUD_OFFSET	EQU	17
PACKED_NEXT_OFFSET EQU 0

;########### SECCION DE DATOS
section .data 	;Aca guardo variables globales inicializadas

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;########### LISTA DE FUNCIONES EXPORTADAS
global cantidad_total_de_elementos
global cantidad_total_de_elementos_packed

;########### DEFINICION DE FUNCIONES
;extern uint32_t cantidad_total_de_elementos(lista_t* lista);
;registros: lista[rdi]
cantidad_total_de_elementos: 
	;Prologo
	push rbp
	mov rbp,rsp 	; Pila alineada a 16 bytes
	
	mov rdi,[rdi]	; Acceso a lista->head (PRE: lista->head!=NULL)
	cmp rdi,NULL	; Si head == NULL , no hay elementos , retorno 0
	mov rax,0		; Count:=0
	je .exit

	mov rsi,rdi		; rsi=node:=lista->head

.loop:
	cmp rsi,NULL					; If node?=null
	je .exit						; If TRUE jump .exit
	add rax,[rsi+LONGITUD_OFFSET]	; count+=node->longitud
	mov rsi,[rsi]					; node:=node->next
	jmp .loop

.exit:
	;Epilogo
	pop rbp	
	ret

;extern uint32_t cantidad_total_de_elementos_packed(packed_lista_t* lista);
;registros: lista[rdi]
cantidad_total_de_elementos_packed:
	;Prologo
	push rbp
	mov rbp,rsp 	; Pila alineada a 16 bytes
	
	mov rdi,[rdi]	; Acceso a lista->head (PRE: lista->head!=NULL)
	cmp rdi,NULL	; Si head == NULL , no hay elementos , retorno 0
	mov rax,0		; Count:=0
	je .exit

	mov rsi,rdi		; rsi=node:=lista->head

.loop:
	cmp rsi,NULL							; If node?=null
	je .exit								; If TRUE jump .exit
	add rax,[rsi+PACKED_LONGITUD_OFFSET]	; count+=node->longitud
	mov rsi,[rsi+PACKED_NEXT_OFFSET]		; node:=node->next
	jmp .loop

.exit:
	;Epilogo
	pop rbp	
	ret

.debug: