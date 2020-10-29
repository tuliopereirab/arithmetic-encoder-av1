#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <inttypes.h>
#include <time.h>

uint32_t low_ob;
uint16_t range_ob;

int ob;
int firstBitFlag;
int bit_counter_line;

#define LOW_LOWER 4194304
#define LOW_HIGHER 8388608
// #define LOW_LOWER 524288
// #define LOW_HIGHER 8388608
#define RANGE_NORM_PARAMETER 32768
#define BITS_PER_LINE 8

void write_line_break();
void ob_reset();
void write_bits(int bit);
void put_bit(int bit);
void renormalization_ob(uint32_t low, uint16_t range);
uint32_t get_Low_ob();
uint16_t get_Range_ob();



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

uint32_t get_Low_ob(){
     return low_ob;
}

uint16_t get_Range_ob(){
     return range_ob;
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
          if(bit_counter_line >= BITS_PER_LINE){
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
          write_bits(1-bit);
     }
     while(ob > 0){
          write_bits(bit);
          ob--;
     }
}

void renormalization_ob(uint32_t low, uint16_t range){
     if(range >= RANGE_NORM_PARAMETER){
          if(low >= LOW_LOWER){
               if(low >= LOW_HIGHER){
                    low -= LOW_HIGHER;
                    put_bit(1);
               }else{
                    low -= LOW_LOWER;
                    ob++;
               }
          }else{
               put_bit(0);
          }
     }
     range_ob = range << (16 - (1 + (31 ^ __builtin_clz(range))));
     low_ob = low << (16 - (1 + (31 ^ __builtin_clz(range))));
}
