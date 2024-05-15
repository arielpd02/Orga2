#include "ej1.h"

// Calcula la longitud de un string ---AUX--------

uint32_t str_length(char* src){
    uint32_t s_index=0;

    while(src[s_index] != '\0'){
        s_index++;
    }
    s_index++; // por el char nulo
    return s_index;
}


uint32_t cuantosTemplosClasicos_c(templo *temploArr, size_t temploArr_len){
    uint32_t res=0;
    for (size_t i = 0; i < temploArr_len; i++)
    {
        if(temploArr[i].colum_largo == (2*temploArr[i].colum_corto+1)){
            res++;
        }
    }
    return res;
}
  
templo* templosClasicos_c(templo *temploArr, size_t temploArr_len){
    // Chequeo si arr de templos es vacio
    if(temploArr_len == 0){
       templo *templos_clasicos=NULL;
       return templos_clasicos; 
    }
    
    //Primero contamos #clasicos para poder pedir  memoria justa
    uint32_t cant_clasicos= cuantosTemplosClasicos(temploArr,temploArr_len);

    templo *clasicos = (templo*)malloc(cant_clasicos * sizeof(templo));
    uint32_t index_clasicos=0;

    for (size_t i = 0; i < temploArr_len; i++)
    {
        if(temploArr[i].colum_largo==(2*temploArr[i].colum_corto + 1)){

            clasicos[index_clasicos].colum_corto=temploArr[i].colum_corto;
            clasicos[index_clasicos].colum_largo=temploArr[i].colum_largo;

            if(temploArr[i].nombre==NULL){
                clasicos[index_clasicos].nombre=NULL;
            }else{
                //Para copiar el nombre, tengo que reservar memoria. CC al liberar 'temploArr' pierdo la data al ser solo un puntero
                
                uint32_t size=str_length(temploArr[i].nombre);           //Contamos el size de nombre

                char *copia_nombre = (char *)calloc(size,sizeof(char));
                copia_nombre=strcpy(copia_nombre,temploArr[i].nombre);   // Uso strcpy de la lib string , que me devuelve el puntero al str copiado

                clasicos[index_clasicos].nombre=copia_nombre;
            }

            index_clasicos++;
        }
    }
    return clasicos;
}



