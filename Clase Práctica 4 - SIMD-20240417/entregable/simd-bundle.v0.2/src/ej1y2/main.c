#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>

#include "checkpoints.h"

int main (void){
	/* Acá pueden realizar sus propias pruebas */
	uint16_t *p=(uint16_t*)malloc(8*sizeof(uint16_t));
	uint16_t *q=(uint16_t*)malloc(8*sizeof(uint16_t));
	uint32_t length=8;
	//Inicializo los vectores
	for (int i = 0; i < 8; i++)
	{
		p[i]=i+1;
		q[i]=i+1;
	}

	uint32_t res = dot_product_asm(p,q,length);
	printf("RES=%d\n",res);

	free(p);
	free(q);

	

	return 0;    
}


