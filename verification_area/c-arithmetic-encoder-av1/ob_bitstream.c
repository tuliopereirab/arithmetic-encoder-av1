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

// #define LOW_LOWER 4194304
// #define LOW_HIGHER 8388608
#define LOW_LOWER 0x400000
#define LOW_HIGHER 0x800000
// #define RANGE_NORM_PARAMETER 32768
#define RANGE_NORM_PARAMETER 0x8000
#define BITS_PER_LINE 8

void write_line_break();
int get_OB_value();
void ob_reset();
void write_bits(int bit, int n_bits);
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

int get_OB_value(){
     int value = ob;
     ob = 0;
     return value;
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

void write_bits(int bit, int n_bits){
     FILE *arq;
     int i;
     if((arq = fopen("output-ob/final_bitstream.csv", "a")) != NULL){
          for(i=0;i<n_bits;i++){
               if(bit){
                    fprintf(arq, "1");
               }else{
                    fprintf(arq, "0");
               }
               if(bit_counter_line >= (BITS_PER_LINE-1)){
                    fprintf(arq, "\n");
                    bit_counter_line = 0;
               }else{
                    bit_counter_line++;
               }
          }
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
          write_bits(bit, 1);
     }
     while(ob > 0){
          write_bits(1-bit, 1);
          ob--;
     }
}

void renormalization_ob(uint32_t low_norm_ob, uint16_t rng_norm_ob){
     if(low_norm_ob < LOW_HIGHER){
          if(low_norm_ob >= LOW_LOWER){
               ob++;
          }
     }
}


// void renormalization_ob(uint32_t low_norm_ob, uint16_t rng_norm_ob){
//      if(rng_norm_ob >= RANGE_NORM_PARAMETER){
//           if(low_norm_ob >= LOW_LOWER){
//                if(low_norm_ob >= LOW_HIGHER){
//                     low_norm_ob -= LOW_HIGHER;
//                     put_bit(1);
//                }else{
//                     low_norm_ob -= LOW_LOWER;
//                     ob++;
//                }
//           }else{
//                printf("%" PRIu32 " < %i\n", low_norm_ob, LOW_LOWER);
//                put_bit(0);
//           }
//      }
//      range_ob = rng_norm_ob << (16 - (1 + (31 ^ __builtin_clz(rng_norm_ob))));
//      low_ob = low_norm_ob << (16 - (1 + (31 ^ __builtin_clz(rng_norm_ob))));
// }
