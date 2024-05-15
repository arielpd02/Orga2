global templosClasicos
global cuantosTemplosClasicos


extern calloc ; la uso para alocar memoria de strings
extern malloc
extern strcpy
extern str_length






%define OFF_TEMPLO_COLUM_LARGO  0
%define OFF_TEMPLO_NOMBRE 8 
%define OFF_TEMPLO_COLUM_CORTO  16

%define SIZE_OF_CHAR 1
%define SIZE_OF_TEMPLO 24

%define NULL 0




;########### SECCION DE TEXTO (PROGRAMA)
section .text
; cuantosTemplosClasicos_c(templo *temploArr, size_t temploArr_len)
;                            RDI: puntero al arr de templos RSI: size del arreglo 
cuantosTemplosClasicos:
    ;Prologo
    push rbp
    mov rbp,rsp
    xor rax,rax         ; rax tiene la cantidad de templos clasicos
    xor r8,r8           ; r8 tiene #columnas en M
    xor r9,r9           ; r9 tiene #columnas en N
    
    .ciclo:
        mov r8b,byte [rdi+OFF_TEMPLO_COLUM_LARGO]           ; Muevo solo un byte para no pasar basura al registro
        mov r9b,byte [rdi+OFF_TEMPLO_COLUM_CORTO]           ; Muevo solo un byte para no pasar basura al registro

        shl r9,1        ; r8=2*N
        inc r9          ; r8=2*N+1

        cmp r8,r9       ; Comparo todo el registro ya que me asegure que en la parte alta hay 0s
        jne .continue   ; Si es igual , es templo clasico

        inc rax         ; Cuento el templo clasico en rax

        .continue:
        add rdi,SIZE_OF_TEMPLO  ;Aumento la #bytes del str p/ver el siguiente
        dec rsi
        cmp rsi,0       ; Si rsi==0 , ya itere por todo el arreglo
        jne .ciclo      ; Si distinto , quedan objetos

    ;Epilogo
    pop rbp
    ret



;templo* templosClasicos_c(templo *temploArr, size_t temploArr_len) 
;                           RDI: puntero al arr de templos RSI: size del arreglo 
templosClasicos:
    ;Prologo
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14

    xor r12,r12         ; En r12 preservo el puntero al arrTemplos al ser no volatil
    mov r12,rdi

    xor r13,r13         ; En r13 prservo el size del arreglo por idem
    mov r13,rsi

    xor r14,r14         ; r14 tendra el puntero al array a devolver

    ;Primero veo el caso si el arr es vacio
    mov rax , NULL                ;Devuelvo el ptr vacio si la lista es vacia
    cmp rsi,0
    je .fin

    ; Pedimos memoria para el arreglo de clasicos

    call cuantosTemplosClasicos
    
    mov rdx,SIZE_OF_TEMPLO
    imul rdx                    ; Signed multiply , same reg as MUL
    mov rdi,rax                 ; rdi tiene #templos_clasicos * sizeof(templos)

    call malloc
    mov r14,rax                 ; Preservo el puntero al arrClasicos ya que voy a llamar a calloc/strcpy

    xor r8,r8                   ; r8 tiene #columnas en M
    xor r9,r9                   ; r9 tiene #columnas en N
    
    .ciclo_clasicos:

        mov r8b,byte [r12+OFF_TEMPLO_COLUM_LARGO]           ; Muevo solo un byte para no pasar basura al registro
        mov r9b,byte [r12+OFF_TEMPLO_COLUM_CORTO]           ; Muevo solo un byte para no pasar basura al registro

        shl r9,1        ; r8=2*N
        inc r9          ; r8=2*N+1

        cmp r8,r9       ; Comparo todo el registro ya que me asegure que en la parte alta hay 0s
        jne .continuar   

        ; Si es igual , es templo clasico

        ; Copio el templo a Arr_clasicos

        xor r8,r8
        xor r9,r9

        mov r8b, byte [r12+OFF_TEMPLO_COLUM_CORTO]
        mov byte [r14+OFF_TEMPLO_COLUM_CORTO],r8b       ; Copio el atributo col_corto que es un byte

        mov r9b, byte [r12+OFF_TEMPLO_COLUM_LARGO]
        mov byte [r14+OFF_TEMPLO_COLUM_LARGO],r9b       ; Copio el atributo col_largo que es un byte

        ; Evaluo primero si nombre es NULL

        mov qword [r14+OFF_TEMPLO_NOMBRE],NULL
        mov r8,[r12+OFF_TEMPLO_NOMBRE]
        cmp r8,NULL
        je .continuar               ; Si se prendio ZF , el puntero era NULL. Continuo 


        mov rdi,[r12+OFF_TEMPLO_NOMBRE]
        call str_length

        mov rdi,rax                 ; rdi tiene el size del nombre
        mov rsi,SIZE_OF_CHAR        ; rsi tiene el size de char / 1 byte
        call calloc


        
        mov rdi,rax                         ; rdi tiene el puntero al str a copiar 
        mov rsi,[r12+OFF_TEMPLO_NOMBRE]     ; rsi tiene el puntero al atributo nombre
        call strcpy

        mov [r14+OFF_TEMPLO_NOMBRE],rax     ; Copio el puntero a la copia del nombre
        add r14,SIZE_OF_TEMPLO              ; Aumento hacia el siguiente templo clasico


        .continuar:

        add r12,SIZE_OF_TEMPLO          ; Aumento la #bytes del str p/ver el siguiente
        dec r13
        cmp r13,0                        ; Si r13==0 , ya itere por todo el arreglo
        jne .ciclo_clasicos              ; Si distinto , quedan objetos


    .fin:

    ;epilogo
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
























