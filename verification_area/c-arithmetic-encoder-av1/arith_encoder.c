#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <inttypes.h>
#include <time.h>
#include <sys/stat.h>



#define EC_PROB_SHIFT 6
#define CDF_SHIFT 0
#define EC_MIN_PROB 4
#define CDF_PROB_TOP 32768

#define MAX_INPUTS 20000000000000

int16_t cnt;
uint16_t range;
uint32_t low;
int offs = 0;
int stop_after_reset_flag;
int reset_counter, bitstream_counter;


// -------------------
clock_t total_time = 0, total_time_carry = 0;
// -------------------

// --------------------------------
void timing_analyzer();
int run_simulation();
void setup();
void reset_function();
uint32_t get_Low();
uint16_t get_Range();
int16_t get_cnt();
void od_ec_encode_q15(unsigned fl, unsigned fh, int s, int nsyms);;
void od_ec_encode_bool_q15(int val, unsigned f);
void od_ec_enc_normalize(uint32_t low_norm, unsigned rng);
void add_bitstream_file(uint16_t bitstream);
void carry_propagation();
double get_total_time();

uint32_t get_Low(){
     return low;
}

uint16_t get_Range(){
     return range;
}

int16_t get_cnt(){
     return cnt;
}

void setup(){
     FILE *arq;
     struct stat sb;
     bitstream_counter = 0;
     if((stat("output-files/", &sb) != 0) || !S_ISDIR(sb.st_mode))
          mkdir("output-files", 0700);
     reset_function();
     arq = fopen("output-files/final_bitstream.csv", "w+");
     fclose(arq);
}

void reset_function(){
     FILE *arq;
     cnt = -9;
     range = 32768;
     low = 0;
     arq = fopen("output-files/pre_bitstream.csv", "w+");
     fclose(arq);
}


int main(int argc, char **argv){
     int status;
     if(argc <= 0){
          printf("Config: Don't stop after first reset (no argument)\n");
          stop_after_reset_flag = 0;
     }else{
          if((strcmp(argv[1], "1")) == 0){
               stop_after_reset_flag = 1;
               printf("Config: Stop after first reset\n");
          }else{
               stop_after_reset_flag = 0;
               printf("Config: Don't stop after first reset\n");
          }
     }
     printf("=========================\n");
     setup();
     status = run_simulation();
     timing_analyzer();
     return 0;
}

double get_total_time(){
     double total_time_print, carry_propagation_time_print, coding_time_print;

     carry_propagation_time_print = (double)((total_time_carry) * 1000 / CLOCKS_PER_SEC);
     coding_time_print = (double)(total_time * 1000 / CLOCKS_PER_SEC);
     total_time_print = coding_time_print + carry_propagation_time_print;
     return total_time_print;
}

void timing_analyzer(){
     double total_time_print, carry_propagation_time_print, coding_time_print;

     carry_propagation_time_print = (double)((total_time_carry) * 1000 / CLOCKS_PER_SEC);
     coding_time_print = (double)(total_time * 1000 / CLOCKS_PER_SEC);
     total_time_print = get_total_time();
     printf("\t-> Coding time: %.2lf ms\n\t-> Carry Propagation time: %.2lf ms\n\t-> Total System Time: %.2lf ms\n---------------------------------------\n",
               coding_time_print, carry_propagation_time_print, total_time_print);
}

int run_simulation(){
     //printf("\n===================================================\n");
     FILE *arq_input, *arq_output;
     int temp_range, temp_low;
     int i, status, reset;
     clock_t begin, end;
     int num_input_read_file, final_flag = 0;
     // -----
     double total_time_print, carry_propagation_time_print, coding_time_print;
     unsigned fl, fh;
     uint16_t file_input_range, file_in_norm_range, file_output_range;
     uint32_t file_input_low, file_in_norm_low, file_output_low;
     int s, nsyms, bool;
     if((arq_input = fopen("/home/tulio/Desktop/y4m_files/generated_files/cq_55/Beauty_1920x1080_120fps_420_8bit_YUV_cq55_main_data.csv", "r")) != NULL){
          i = 0;
          status = 1;
          reset = 0;
          while((i <= MAX_INPUTS) && (final_flag != 1) && (status != 0) && (reset != 1)){
               printf("\rInput # %d, Reset # %d, Bitstream # %d, cnt: %d, Time: %.2lf ms, Range: %d, Low: %d ", i, reset_counter, bitstream_counter, cnt, get_total_time(), range, low);
               num_input_read_file = fscanf(arq_input, "%i;%i;%i;%i;%i;%i;%i;%" SCNd16 ";%" SCNd32 ";%" SCNd16 ";%" SCNd32 ";\n",
                                             &bool, &temp_range, &temp_low, &fl, &fh, &s, &nsyms, &file_in_norm_range, &file_in_norm_low, &file_output_range, &file_output_low);
               if(num_input_read_file == 11){
                    file_input_low = (uint32_t)temp_low;
                    file_input_range = (uint16_t)temp_range;
                    fflush(stdin);
                    //printf("Input %i:\n\t-> FL = %"PRIu16"\n\t-> FH = %"PRIu16"\n\t-> s = %i\n\t-> nsyms = %i\n", i, fl, fh, s, nsyms);
                    //printf("\t-> Input Range: %"PRIu16"\n\t-> Input Low: %"PRIu32"\n\t-> In Norm Range: %"PRIu16"\n\t-> In Norm Low: %"PRIu32"\n\t-> Final Range: %"PRIu16"\n\t-> Final Low: %"PRIu32"\n-----------\n", file_input_range, file_input_low, file_in_norm_range, file_in_norm_low, file_output_range, file_output_low);
                    if((i>1) && (temp_low == 0) && (temp_range == 32768) && ((temp_range != range) || (temp_low != low))){            // reset detection
                         reset_counter++;
                         begin = clock();
                         //carry_propagation();
                         end = clock();
                         reset_function();
                         total_time_carry = total_time_carry + (end-begin);
                         if(stop_after_reset_flag)
                              reset = 1;
                    }
                    begin = clock();
                    if(bool)
                         od_ec_encode_q15(fl, fh, s, nsyms);
                    else
                         od_ec_encode_bool_q15(s, fh);

                    end = clock();
                    total_time = total_time + (end - begin);

                    if((file_output_range != range) || (file_output_low != low)){
                         status = 0;
                    }
               }else{
                    final_flag = 1;
               }
               i++;
          }
          if(status == 0){
               printf("\n=========================\nExecution finished with error\n");
               printf("Input %i:\n\t-> In Range: %d\n\t-> In Low: %d\n\t-> FL = %"PRIu16"\n\t-> FH = %"PRIu16"\n\t-> s = %i\n\t-> nsyms = %i\n", i-1, file_input_range, file_input_low, fl, fh, s, nsyms);
               printf("Line: %i\n\t-> Low: expected %" PRIu32 ", got %" PRIu32 "\n\t-> Range: expected %" PRIu16 ", got %" PRIu16 "\n", i-1, file_output_low, low, file_output_range, range);
               printf("--------------------------------------------------\n");
               return -2;
          }else if(reset == 1){
               printf("=========================\nFinished with reset\n");
          }else{
               printf("\n=========================\nNo error found.\n");
          }
     }else{
          printf("Unable to open the input file.\n");
          return -1;
     }


     return 0;
}

void od_ec_encode_q15(unsigned fl, unsigned fh, int s, int nsyms) {
     uint32_t l;
     unsigned r;
     unsigned u;
     unsigned v;
     l = low;
     r = range;
     assert(32768U <= r);
     assert(fh <= fl);
     assert(fl <= 32768U);
     assert(7 - EC_PROB_SHIFT - CDF_SHIFT >= 0);
     const int N = nsyms - 1;
     if (fl < CDF_PROB_TOP) {
          u = ((r >> 8) * (uint32_t)(fl >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT - CDF_SHIFT)) + EC_MIN_PROB * (N - (s - 1));
          v = ((r >> 8) * (uint32_t)(fh >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT - CDF_SHIFT)) + EC_MIN_PROB * (N - (s + 0));
          l += r - u;
          r = u - v;
     } else {
          r -= ((r >> 8) * (uint32_t)(fh >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT - CDF_SHIFT)) + EC_MIN_PROB * (N - (s + 0));
     }

     od_ec_enc_normalize(l, r);
}

void od_ec_encode_bool_q15(int val, unsigned f) {
    uint32_t l;
    unsigned r;
    unsigned v;
    assert(0 < f);
    assert(f < 32768U);
    l = low;
    r = range;
    assert(32768U <= r);
    v = ((r >> 8) * (uint32_t)(f >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT));
    v += EC_MIN_PROB;
    if (val)
        l += r - v;
    r = val ? v : r - v;

    od_ec_enc_normalize(l, r);
}

void od_ec_enc_normalize(uint32_t low_norm, unsigned rng) {
     int d;
     int c;
     int s;
     c = cnt;
     assert(rng <= 65535U);
     d = 16 - (1 + (31 ^ __builtin_clz(rng)));
     s = c + d;
     if (s >= 0) {
          unsigned m;
          c += 16;
          m = (1 << c) - 1;
          if (s >= 8) {
               // assert(offs < storage);
               // buf[offs++] = (uint16_t)(low >> c);
               offs++;
               add_bitstream_file((uint16_t)(low_norm >> c));
               bitstream_counter++;
               low_norm &= m;
               c -= 8;
               m >>= 8;
          }
          // assert(offs < storage);
          // buf[offs++] = (uint16_t)(low >> c);
          offs++;
          add_bitstream_file((uint16_t)(low_norm >> c));
          bitstream_counter++;
          s = c + d - 24;
          low_norm &= m;
     }
     low = low_norm << d;
     range = rng << d;
     cnt = s;
}


void add_bitstream_file(uint16_t bitstream){
    FILE *arq;
    if(bitstream >= 256)
          //printf("\nCarry!\n");
    if((arq = fopen("output-files/pre_bitstream.csv", "a+")) != NULL){
        //printf("\nAdding bitstream: %" PRIu16 "\n", bitstream);
        fprintf(arq, "%" PRIu16 ";\n", bitstream);
        fclose(arq);
    }else
        printf("Unable to open the bitstream file\n");
}

void carry_propagation(){
     FILE *arq, *arq_reference;
     uint16_t temp_bitstream;
     uint16_t *buf;
     unsigned char *out;
     uint32_t l, e, m;
     int c, s, start = 1, counter = 0, out_size, i;
     l = low;
     c = cnt;
     s = 10;
     m = 0x3FFF;
     e = ((l + m) & ~m) | (m + 1);
     s += c;
     if(s > 0){
          unsigned n;
          if((arq = fopen("output-files/pre_bitstream.csv", "a+")) != NULL){
               n = (1 << (c + 16)) - 1;
               do{
                    temp_bitstream = (uint16_t)(e >> (c + 16));
                    offs++;
                    fprintf(arq, "%" PRIu16 ";\n", temp_bitstream);
                    e &= n;
                    s -= 8;
                    c -= 8;
                    n >>= 8;
               } while(s > 0);
               fclose(arq);
          }else{
               printf("Unable to open the bitstream file.\n");
               exit(EXIT_FAILURE);
          }
     }
     if((arq = fopen("output-files/pre_bitstream.csv", "r")) != NULL){
          buf = (uint16_t *)malloc(sizeof(uint16_t));
          counter++;
          while((fscanf(arq, "%" SCNd16 "\n", &buf[counter-1])) != EOF){
               counter++;
               buf = (uint16_t *)realloc(buf, sizeof(uint16_t) * counter);
          }
          counter--;
     }else{
          printf("Unable to open the bitstream file.\n");
          exit(EXIT_FAILURE);
     }

     // carry propagation itself
     out_size = offs;
     out = (unsigned char*)malloc(sizeof(unsigned char) * out_size);
     c = 0;
     while(offs > 0){
          offs--;
          c = buf[offs] + c;
          //printf("%" PRIu16 "\n", buf[offs]);
          out[offs] = (unsigned char)c;
          c >>= 8;
     }

     // if((arq = fopen("output-files/final_bitstream.csv", "a")) != NULL){
     //      for(i=0; i<out_size; i++){
     //           fprintf(arq, "%u;\n", out[i]);
     //      }
     //      fclose(arq);
     // }else{
     //      printf("Unable to open the final bitstream file.\n");
     //      exit(EXIT_FAILURE);
     // }
}
