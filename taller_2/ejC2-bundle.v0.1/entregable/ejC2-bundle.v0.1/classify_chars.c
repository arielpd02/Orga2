#include "classify_chars.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


uint64_t is_vowel(char c){
    char vowels[10]="aeiou"; 
    int i=0;
    while(c!=vowels[i] && vowels[i]!='\0'){
        i++;
    }
    return (c==vowels[i]);
}

void classify_chars_in_string(char* string, char** vowels_and_cons){
    vowels_and_cons[0]=(char*)calloc(64+1,sizeof(char));              //tengo un array(char*) de 2 elementos
    vowels_and_cons[1]=(char*)calloc(64+1,sizeof(char));

    uint64_t i=0,v=0,c=0;
    while(string[i]!='\0'){
        if(is_vowel(string[i])==1){
            vowels_and_cons[0][v]=string[i];
            v++;
        }else{
            vowels_and_cons[1][c]=string[i];
            c++;
        }
        i++;
    }
}

void classify_chars(classifier_t* array, uint64_t size_of_array) {
    for(uint64_t i=0;i<size_of_array;i++){
        array[i].vowels_and_consonants= (char**)malloc(sizeof(char**)*2);
        classify_chars_in_string(array[i].string , array[i].vowels_and_consonants);
    }
}
