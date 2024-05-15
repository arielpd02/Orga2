#include "ej1.h"

nodo_display_list_t* inicializar_nodo(
  uint8_t (*primitiva)(uint8_t x, uint8_t y, uint8_t z_size),
  uint8_t x, uint8_t y, nodo_display_list_t* siguiente) {
    nodo_display_list_t* nodo = malloc(sizeof(nodo_display_list_t));
    nodo->primitiva = primitiva;
    nodo->x = x;
    nodo->y = y;
    nodo->z = 255;
    nodo->siguiente = siguiente;
    return nodo;
}

ordering_table_t* inicializar_OT(uint8_t table_size) {
  //En primer lugar pedimos memoria para la OT (struct)
  ordering_table_t * ot_res= (ordering_table_t*)malloc(16);

  if(table_size==0){
    ot_res->table_size=table_size;
    ot_res->table=NULL; //puesto que no tiene elementos
    return ot_res;
  }
  //CC hay elementos en table
  
  //Asignamos el primer atributo
  ot_res->table_size=table_size;

  //Abrimos la memoria a pedir para el array table
  nodo_ot_t **arr_nodos=(nodo_ot_t**)malloc(table_size*sizeof(nodo_ot_t*));
  ot_res->table=arr_nodos;

  //Iniciamos table  con todo elemento/puntero en NULL
  for (size_t i = 0; i < table_size; i++)
  {
    arr_nodos[i]=NULL;
  }
  
  return ot_res;

}
// Me das un nodo y un z_size y te tengo que dar el valor de z y guardarlo en el nodo
void calcular_z(nodo_display_list_t* nodo, uint8_t z_size) {
    uint8_t x=nodo->x;
    uint8_t y=nodo->y;

    //Llamamos a la primitiva
    uint8_t z=nodo->primitiva(x,y,z_size);
    //Cargamos el valor de z
    nodo->z=z;
}

// Voy a querer iterar por display_list , en cada nodo calculo su z y lo pego al final de la lista asociada 
// a z en la ordering_table
void ordenar_display_list(ordering_table_t* ot, nodo_display_list_t* display_list) {

  nodo_display_list_t *nodo_actual=display_list;
  uint8_t z_size= ot->table_size;
  nodo_ot_t **table=ot->table;

  while(nodo_actual!=NULL){

    //calculamos z a nodo actual
    calcular_z(nodo_actual,z_size);
    uint8_t z=nodo_actual->z;

    //z me sirve como offset para desplazarme en OT 
    nodo_ot_t *nodo_ot_ptr=table[z]; // Me devuelve un ptr a un arr_nodo_ot asociado a z

    //Lista vacia si era NULL
    if(nodo_ot_ptr != NULL){
    
      //CC hay que encontrar el final
      nodo_ot_t *previous;

      while(nodo_ot_ptr!=NULL){
        previous=nodo_ot_ptr;
        nodo_ot_ptr=nodo_ot_ptr->siguiente;
      }
      // Recupero el ultimo nodo
      nodo_ot_ptr=previous; 
    }

      //Creamos el nuevo nodo_ot y asociamos
      nodo_ot_t *nuevo_nodo=(nodo_ot_t*)malloc(16);
      
      nuevo_nodo->display_element=nodo_actual;
      nuevo_nodo->siguiente=NULL;

      nodo_ot_ptr->siguiente=nuevo_nodo;

      //Avanzo al prox nodo_display_t
      nodo_actual=nodo_actual->siguiente;
    
  }
  
}
