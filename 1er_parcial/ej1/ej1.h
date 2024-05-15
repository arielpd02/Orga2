#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <unistd.h>
#define USE_ASM_IMPL 0 

typedef struct nodo_display_list_t {        //          OFFSETS
    // Puntero a la función que calcula z (puede ser distinta para cada nodo):
    uint8_t (*primitiva)(uint8_t x, uint8_t y, uint8_t z_size);     //  0
    // Coordenadas del nodo en la escena:
    uint8_t x;                   // 8   
    uint8_t y;                  // 9
    uint8_t z;                  // 10
    //Puntero al nodo siguiente:
    struct nodo_display_list_t* siguiente;      // 16
} nodo_display_list_t;          // 24= |nodo_display_list_t| 



typedef struct nodo_ot_t {          //OFFSETS   
    struct nodo_display_list_t* display_element;        //0
    struct nodo_ot_t* siguiente;                        //8
} nodo_ot_t;            //16



typedef struct ordering_table_t {       //OFFSETS
    uint8_t table_size;             // 0 -- PADDING DE 7 BYTES--
    struct nodo_ot_t** table;       //8
} ordering_table_t;             //16 x alineacion de datos




ordering_table_t* inicializar_OT(uint8_t table_size);
ordering_table_t* inicializar_OT_asm(uint8_t table_size);

void calcular_z(nodo_display_list_t* nodo, uint8_t z_size);
void calcular_z_asm(nodo_display_list_t* nodo, uint8_t z_size);

void ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list);
void ordenar_display_list_asm(ordering_table_t* ot, nodo_display_list_t* display_list);

nodo_display_list_t* inicializar_nodo(
  uint8_t (*primitiva)(uint8_t x, uint8_t y, uint8_t z_size),
  uint8_t x, uint8_t y, nodo_display_list_t* siguiente);
