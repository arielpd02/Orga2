#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "checkpoints.h"

nodo_t* armar_nodo(nodo_t *node,uint32_t n){
	//Inicializamos el array del nodo
	uint32_t *arr=malloc(n*sizeof(uint32_t));
	for (size_t i = 0; i < n; i++)
	{	
		arr[i]=i;
	}
	//Inicializamos el struct y cargamos atributos
	node=(nodo_t*)malloc(sizeof(nodo_t));
	node->arreglo=arr;
	node->categoria=0;
	node->longitud=n;
	node->next=NULL;
	
	return node;
}

packed_nodo_t* armar_nodo_p(packed_nodo_t *node,uint32_t n){
	//Inicializamos el array del nodo
	uint32_t *arr=malloc(n*sizeof(uint32_t));
	for (size_t i = 0; i < n; i++)
	{	
		arr[i]=i;
	}
	//Inicializamos el struct y cargamos atributos
	node=(packed_nodo_t*)malloc(sizeof(packed_nodo_t));
	node->arreglo=arr;
	node->categoria=0;
	node->longitud=n;
	node->next=NULL;
	
	return node;
}

int main (void){
	/* Acá pueden realizar sus propias pruebas */

	//Checkpoint 2

	/*
	printf("RES:%d\n",alternate_sum_4_using_c(8,2,5,1));
	printf("RES:%d\n",alternate_sum_4_simplified(8,2,5,1));

	assert(alternate_sum_4(8,2,5,1) == 10);	

	printf("RES:%d\n",alternate_sum_8(8,2,5,1,8,2,5,1));

	assert(alternate_sum_8(8,2,5,1,8,2,5,1)==20);
	*/

	uint32_t *destination=(uint32_t*)malloc(sizeof(uint32_t));		//Pido 4 bytes de memoria para guardar el uint32
	product_2_f(destination,583,521.44);
	printf("RES:%d\n",*destination);
		
	/*
	double *destination = (double*)malloc(1*sizeof(double));
	product_9_f(destination,2,3,4,5,6,7,8,9,10,11,2,3,4,5,6,7,8,9);

	printf("RES:%f\n",*destination);

	*/

	//Checkpoint 3


	/*
	// Test lista_t

	lista_t lista;

	
	nodo_t *node_1=armar_nodo(node_1,6);
	nodo_t *node_2=armar_nodo(node_2,100);
	nodo_t *node_3=armar_nodo(node_3,200);
	node_1->next=node_2;
	node_2->next=node_3;

	lista.head = node_1;


	uint32_t res=cantidad_total_de_elementos(&lista);
	printf("RES:%d \n",res);
	
	//Liberamos la memoria pedida
	free(node_1);
	free(node_2);
	free(node_3);

	//Test packed_lista_t

	packed_lista_t lista_p;

	packed_nodo_t *p_node1 = armar_nodo_p(p_node1,9);
	packed_nodo_t *p_node2= armar_nodo_p(p_node2,100);
	packed_nodo_t *p_node3 = armar_nodo_p(p_node3,200);
	p_node1->next=p_node2;
	p_node2->next=p_node3;

	lista_p.head=p_node1;

	res=cantidad_total_de_elementos_packed(&lista_p);
	printf("RES:%d \n",res);
	
	free(p_node1);
	free(p_node2);
	free(p_node3);
	*/

	//Checkpoint 4


	//TEST strCmp

	/*
	int32_t res=0;

	char a[]="aeiou";
	char b[]="aeioz";


	res=strCmp(a,b);
	printf("RES:%d\n",res);	//Deberia dar 1

	res=strCmp("","");
	printf("RES:%d\n",res);	//Deberia dar 0
	*/
	//TEST strClone
	char a[]="aeiou";
	char *res=strClone(a);
	
	int i=0;
	while(res[i]!='\0'){
		printf("%c",res[i]);
		i++;
	}
	printf("\n");

	return 0;    
}


