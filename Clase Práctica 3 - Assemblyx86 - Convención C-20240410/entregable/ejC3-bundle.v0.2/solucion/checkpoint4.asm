extern malloc
extern free
extern fprintf

%define nule_char 0

section .data
msg db 'NULL','\0'

section .text

global strCmp
global strClone
global strDelete
global strPrint
global strLen

; ** String **

; int32_t strCmp(char* a, char* b) rdi=a[0] , rsi=b[0]
strCmp:
	;Prologo
	push rbp
	mov rbp,rsp		; Stack alineado a 16bytes

	xor rcx,rcx		; rcx(=i):=0
	xor rdx,rdx		; rdx(=j):=0

.loop_begin:
	mov r8b,BYTE [rdi+rcx]	;r8:=a[i]
	mov r9b,BYTE [rsi+rdx]	;r9:=b[j]
	cmp r8b,nule_char		;a[i]?='\0'
	je .eq_length
	cmp r9b,nule_char		;b[i]?='\0'
	je .eq_length

	;Loop body
	cmp r8b,r9b			;a[i]?=b[j]
	jne .not_equal
	inc rcx				;i++
	inc rdx				;j++
	jmp .loop_begin

.not_equal:
	jl .a_smaller
.a_bigger:	
	mov rax,-1
	jmp .end
.a_smaller:
	mov rax,1
	jmp .end

.eq_length:				; Guarda falsa , midamos longitudes
	cmp r8b,r9b
	jl .a_smaller
	jg .a_bigger
	mov rax,0

.end:
	;Epilogo
	pop rbp
	ret

; char* strClone(char* a)
strClone:
	;Epilogo
	push rbp
	mov rbp,rsp 	; Stack alineada :)

	push rdi		; No alineada , guardo en el stack el valor de a[0]
	sub rsp,8		; Alineada

	;Calculamos longitud del str a
	xor rsi,rsi
	call strLen
	mov rsi,rax		; rsi=|a|

	;Abrimos espacio en el heap para la copia
	mov rdi,rsi		
	inc rdi			; rdi:= #bytes necesarios <->longitud del str + 1
	call malloc		; En rax esta el puntero al str copia

	;Copiamos el string
	add rsp,8
	pop rdi 		; Alineamos pila y devolvemos el puntero al str a rdi
	xor rcx,rcx		; rcx(=i):=0 , mi index de strings

	;Si |a|== 0 , copio el caracter nulo y retorno
	cmp rsi,0
	jne .loop
	jmp .exit

.loop:
	cmp BYTE [rdi+rcx],nule_char	; a[i] ?= 0
	je .exit						; IF TRUE , llego al final , finalizamos
	mov dl,BYTE [rdi+rcx]			; dl:= a[i]
	mov BYTE [rax+rcx],dl			; copia[i]:=a[i]
	inc rcx							; i++
	jmp .loop

.exit:
	mov BYTE [rax+rcx],nule_char
	;Epilogo
	pop rbp
	ret

; void strDelete(char* a)
strDelete:
	;Prolog
	push rbp
	mov rbp,rsp		;Stack alineada

	call free		;En rdi esta el puntero al char , llamo directamente a free(a)


	;Epilogo
	pop rbp
	ret

; void strPrint(char* a, FILE* pFile)
strPrint:
	;Prologo
	push rbp
	mov rbp,rsp			;Stack alineado

	;IF |a|== 0 , escribo en pFile el str 'NULL'

	mov dl,BYTE [rdi]
	cmp dl,nule_char
	jne .loop
	mov DWORD [rsi],msg		; Escribo 'NULL' donde comienza pFile 
	jmp .exit

	xor rcx,rcx			; rcx(=i):=0

.loop:
	cmp BYTE [rdi+rcx],nule_char
	je .exit
	mov dl, BYTE [rdi+rcx]		; dl:=a[i]
	mov BYTE [rsi+rcx],dl		; pFile[i]:=a[i]
	inc rcx						; i++
	jmp .loop

.exit:
	;Epilogo
	pop rbp
	ret


; uint32_t strLen(char* a)
strLen: 	
	;Prologo
	push rbp
	mov rbp,rsp

	xor rcx,rcx		; rcx(=i):=0
	
.loop:
	cmp BYTE [rdi+rcx],nule_char		; a[i] ?= 0
	je .exit							; IF TRUE , llego al final , finalizamos
	inc rcx
	jmp .loop

.exit:
	mov rax,rcx
	;Epilogo
	pop rbp
	ret


.debug: