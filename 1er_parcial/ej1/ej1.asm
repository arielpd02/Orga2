section .text

global inicializar_OT_asm
global calcular_z_asm
global ordenar_display_list_asm

extern malloc
extern free

%define NULL 0

%define SIZE_OF_OT 16
%define SIZE_OF_PTR 8

%define OFF_TABLE_SIZE 0
%define OFF_TABLE 8

%define OFF_OT_NODE_DISPLAY_ELEMENT 0
%define OFF_OT_NODE_SIGUIENTE 8

%define OFF_NODE_PRIMITIVA 0
%define OFF_NODE_X  8 
%define OFF_NODE_Y  9
%define OFF_NODE_Z  10
%define OFF_NODE_SIGUIENTE 16


;########### SECCION DE TEXTO (PROGRAMA)

; ordering_table_t* inicializar_OT(uint8_t table_size);
;                                       dil : table_size
inicializar_OT_asm:
    ;Prologo 
    push rbp
    mov rbp,rsp
    push r15 
    push r14
    

    xor r15,r15
    mov r15b,dil         ; r15 preserva el table_size al ser no volatil

    ;Pedimos memoria para el struct
    xor rdi,rdi
    mov rdi,SIZE_OF_OT
    call malloc

    mov  r14,rax        ; r14 preserva el puntero a la OT


    ;Cargamos el primer atributo
    mov byte [r14+OFF_TABLE_SIZE],r15b

    ;Si table_size == 0 , table es null y finalizo 
    mov rcx,r15             ;Muevo para no perder el valor
    mov qword [r14+OFF_TABLE],NULL
    cmp rcx,0
    je .fin


    ;CC  abrimos memoria para el arr_nodos 
    xor rax,rax
    mov rax,SIZE_OF_PTR
    mul r15
    
    mov rdi,rax         ; rdi tiene la #bytes para arr_nodos , table_size*SIZEOFPTR
    call malloc

    ; Cargamos el puntero en memoria
    mov [r14+OFF_TABLE],rax         ; rax tiene el ptr al begin del arr_nodos

    ; Inicializamos los punteros en NULL
    xor rdx,rdx                     ; rdx tiene el offset para el arr_nodo_ot**

    .ciclo_init:

        mov qword [rax+rdx],NULL


        add rdx,8               ; actualizo ptr a proximo elemento del array
        dec r15                 
        cmp r15,0
        jne .ciclo_init         ; Si es igual a 0 , recorri todo arr_nodos

    .fin:
    mov rax,r14

    ;Epilogo
    pop r14
    pop r15
    pop rbp
    ret

; void* calcular_z(nodo_display_list_t* display_list,uint8_t z_size);
;                           RDI ptr a la lista          RSI z_size
calcular_z_asm:
    ;Prologo
    push rbp
    mov rbp,rsp
    push r14
    push r15
    
    ;Preservo parametros en no volatiles

    xor r15,r15

    mov r14,rdi         ; r14 tiene puntero al nodo
    mov r15b,sil        ; r15 tiene z_size

    ; Bajamos los valores a registros

    xor r8,r8
    xor r9,r9
    xor r10,r10
    
    mov rax,[r14+OFF_NODE_PRIMITIVA]     ; rax tiene ptr a funcion
    mov r8b,byte [r14+OFF_NODE_X]        ; r8 tiene coordenada x
    mov r9b,byte [r14+OFF_NODE_Y]        ; r9 tiene coordenada y
    
    xor rdi,rdi
    xor rsi,rsi
    xor rdx,rdx

    ;Paso parametros y llamo a la primitiva

    mov dil,r8b
    mov sil,r9b
    mov dl,r15b
    call rax            ; rax tiene el puntero a la funcion primitiva


    ; Cargo en memoria z (uint8_t) value devuelto en al

    mov byte [r14+OFF_NODE_Z],al

    ;Epilogo
    pop r15
    pop r14
    pop rbp 
    ret 

; void* ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) ;
;                               RDI tiene ptr de OT 
;                               RSI tiene ptr a display_list
;                               RDX  tiene z_size
ordenar_display_list_asm:
    ;Prologo
    push rbp
    mov rbp,rsp
    push r14 
    push r15
    push r13
    push r12

    xor r14,r14
    xor r15,r15
    xor r13,r13

    mov r15,rdi     ; r15 tiene ptr de OT
    mov r14,rsi     ; r14 tiene ptr a nodo de display_list --no estatico
    mov r13b,dl     ; r13 tiene z_size

    ; Iteramos por display_list_t, x cada nodo lo agrego a un node_OT en su index correspondiente
    .ciclo_display_list:

        ;Calculamos el z del nodo actual
        xor rsi,rsi
        mov rdi,r15
        mov sil,r13b
        call calcular_z_asm

        mov r13b,byte[r15+OFF_NODE_Z]       ; r13 tiene valor z de nodo actual

        ; Chequeamos si es lista vacia
        mov r12,[r15+r13]                  ; r12 tiene ptr a nodo_ot de z
        cmp r12,NULL
        je .agregar_nodo

        ;CC hay que buscar el final

        .ciclo_arr_ot:

            mov rcx,r12     ; rcx tiene el ultimo puntero OT
            mov r12,[r12+OFF_OT_NODE_SIGUIENTE]

            cmp r12,NULL
            jne .ciclo_arr_ot

        mov r12,rcx         ; Recupero el ultimo nodo


        .agregar_nodo:
        ;Pedimos memoria para el nuevo nodo_ot y asociamos a nodo_display_t

        mov rdi,SIZE_OF_OT
        call malloc         ; rax tengo ptr al  nuevo nodo_ot
        mov [rax+OFF_OT_NODE_DISPLAY_ELEMENT],r14
        mov qword [rax+OFF_OT_NODE_SIGUIENTE],NULL



        mov r14,[r14+OFF_NODE_SIGUIENTE]    ; Avanzo al proximo nodo
        cmp r14,NULL            
        jne .ciclo_display_list     ; si es igual , llegue al final de display_list



    ;Epilogo
    pop r12
    pop r13
    pop r14
    pop r15
    pop rbp
    ret

