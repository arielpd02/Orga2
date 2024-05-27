; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"
%define C_FG_LIGHT_CYAN  0xb
%define C_FG_LIGHT_GREEN  0xa
%define BORDER (0x0<<4|0x2)

global start


; COMPLETAR - Agreguen declaraciones extern según vayan necesitando

;Extern code
extern A20_enable
extern A20_disable
extern screen_draw_layout
extern screen_draw_box
;Extern data
extern GDT_DESC

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL  0b0000000001000     
%define DS_RING_0_SEL  0b0000000011000           

%define STACK_BASE 0x25000


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg
eq: db '='
;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; COMPLETAR - Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO REAL
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    print_text_rm start_rm_msg,start_rm_len,C_FG_LIGHT_CYAN,0x00,0x00

    ; COMPLETAR - Habilitar A20
    ; (revisar las funciones definidas en a20.asm)
    call A20_enable
    call A20_check

    ; COMPLETAR - Cargar la GDT
    lgdt [GDT_DESC]

    ; COMPLETAR - Setear el bit PE del registro CR0
    mov eax,cr0
    or eax,0x00000001
    mov cr0,eax

    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido

BITS 32
modo_protegido:
    ; COMPLETAR - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    mov ax,DS_RING_0_SEL
    mov ds,ax
    mov es,ax
    mov gs,ax
    mov fs,ax
    mov ss,ax

    ; COMPLETAR - Establecer el tope y la base de la pila
    mov ebp,STACK_BASE
    mov esp,STACK_BASE

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg,start_pm_len,C_FG_LIGHT_GREEN,0x00,0x00
    ; COMPLETAR - Inicializar pantalla
    call screen_draw_layout
    
    
    xor eax,eax
    mov edx,BORDER
    push edx
    xor eax,eax
    mov edx,[eq]
    push edx
    mov edx,40
    push edx
    mov edx,40
    push edx
    mov edx,0
    push edx
    mov edx,0
    push edx
    ;call screen_draw_box
    pop eax
    pop eax
    pop eax
    pop eax
    pop eax
    pop eax

    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
