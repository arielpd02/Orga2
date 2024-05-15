global YUYV_to_RGBA



;########### SECCION DE TEXTO (PROGRAMA)
section .text

;void YUYV_to_RGBA( int8_t *X, uint8_t *Y, uint32_t width, uint32_t height);
;                       DIL X     SIL Y     EDX width           ECX height
YUYV_to_RGBA:
    ;Prologo
    push rbp
    mov rbp,rsp

    ; Calculamos #iteraciones , la imagen de dst tiene el doble de width y procesamos 2 px por iteraciones.
    ; Iteramos width veces
    mov rcx,j





    .ciclo:




;No pude continuar con este ejercicio debido a fallas que me hicieron demorar en el medio del examen con mi computadora que no respondia , lo cual paso varias veces. Pero la logica esta , no llegue a bajarlo a ASM :(

He aqui mi idea , voy a procesar de a 2 pixeles `puesto que tengo que operar con sumas y operaciones con float.
1)Bajo 2px a un xmmx y los reacomodo de manera que cada qw sea un pixel con extension con signo. |v|y2|u|y2|v|y1|u|y1| reacomodados con un blend.
2)Comparo si u yv son 127 y me guardo esta mascara de igualda para aplicar al final
3) Realizo las siguiente operaciones:
	i) Restamos a u y v 128 con un mask
	ii)genero mascara de V para lo .R .G y .B
	*Shifteo a  der c/DW 16 bits sin signo 
	* Aplico mascara p/wipear valores :
		|0|V|0|U|0|V|0|U|= xmmx
	*Sumo ctes. A u `para .B y a V para .R
	*genero otra copia del xmmx shifteo a der c/qw 2 bytes . En la otra shifteo a izq. c/qw 2 bytes
	Y me quedan dos registros que solo tiene V y U en .G respectivamente
	*Luego cvt a float y multiplico x ctes.
	* Despues sumo 
	iii) Despues de operaciones -> mascara del cmp de 2) y aplico la mascara para los pixeles errados .
	
	 






    ;Epilogo
    pop rbp
    ret




;No pude continuar con este ejercicio debido a fallas que me hicieron demorar en el medio del examen con mi computadora que no respondia , lo cual paso varias veces. Pero la logica esta , no llegue a bajarlo a ASM :(








    ;Epilogo
    pop rbp
    ret
