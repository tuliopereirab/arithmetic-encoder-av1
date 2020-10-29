#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <inttypes.h>
#include <time.h>

int ob;
int firstBitFlag;
int bit_counter_line;

// #define LOW_LOWER 4194304
// #define LOW_HIGHER 8388608
#define LOW_LOWER 32768
#define LOW_HIGHER 65536
#define RANGE_NORM_PARAMETER 32768

void write_line_break();
void ob_reset();
void write_bits(int bit);
void put_bit(int bit);
void renormalization_ob(uint32_t low, uint16_t range);



void ob_reset(){
     FILE *arq;
     if((arq = fopen("output-ob/final_bitstream.csv", "w+")) == NULL){
          printf("Unable to create the Bitstream file for OB execution.\n");
          exit(EXIT_FAILURE);
     }else{
          fclose(arq);
     }
     ob = 0;
     firstBitFlag = 1;
     bit_counter_line = 0;

}

void write_line_break(){
     FILE *arq;
     if((arq = fopen("output-ob/final_bitstream.csv", "a")) != NULL){
          fprintf(arq, "\n");
          fclose(arq);
     }else{
          printf("Unable to open the Bitstream file for OB to add the line breaker\n");
          exit(EXIT_FAILURE);
     }
}

void write_bits(int bit){
     FILE *arq;
     if((arq = fopen("output-ob/final_bitstream.csv", "a")) != NULL){
          if(bit_counter_line >= 15){
               fprintf(arq, "\n");
               bit_counter_line = 0;
          }else{
               bit_counter_line++;
          }
          if(bit)
               fprintf(arq, "1");
          else
               fprintf(arq, "0");
          fclose(arq);
     }else{
          printf("Unable to open the Bitstream file for OB\n");
          exit(EXIT_FAILURE);
     }
}

void put_bit(int bit){
     if(firstBitFlag != 0){
          firstBitFlag = 0;
     }else{
          write_bits(bit);
     }
     while(ob > 0){
          write_bits(1-bit);
          ob--;
     }
}

void renormalization_ob(uint32_t low, uint16_t range){
     if(range >= RANGE_NORM_PARAMETER){
          if(low >= LOW_LOWER){
               if(low >= LOW_HIGHER){
                    put_bit(1);
               }else{
                    ob++;
               }
          }else{
               put_bit(0);
          }
     }
}
