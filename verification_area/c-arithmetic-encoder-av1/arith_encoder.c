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

#define MAX_INPUTS 1000000000

#define PRINT_RATE 3000         // This variable helps to print in different rates.
// if((counter % print) == 0), set 1 to print all

// ------------------------------------------------------
// Variables for the NEW Carry Propagation
#define SUB_BITSTREAM 256
// ------------------------------------------------------
#define FLAG_NEW_LOGIC 2      // 2: encode both arithmetic encoder logics
                              // 1: use only the NEW arithmetic encoder logic
                              // 0: use only the ORIGINAL arithmetic encoder logic
// ============
// These definitions are used within the NEW logic for range/low updating.
# define OD_EC_REDUCED_OVERHEAD 1       // 0: use normal overhead
                                        // 1: use reduced overhead
// ============
// The new arithmetic encoder logic was based on the paper below
     // @ARTICLE{7930427,
     //      author={Belyaev, Evgeny and Forchhammer, Søren and Liu, Kai},
     //      journal={IEEE Signal Processing Letters},
     //      title={An Adaptive Multialphabet Arithmetic Coding Based on Generalized Virtual Sliding Window},
     //      year={2017},
     //      volume={24},
     //      number={7},
     //      pages={1034-1038},
     //      doi={10.1109/LSP.2017.2705250}}
     // ----------------------------------------
     // @ARTICLE{8986834,
     //      author={Chen, Boyang and Liu, Kai and Belyaev, Evgeny},
     //      journal={IEEE Transactions on Very Large Scale Integration (VLSI) Systems},
     //      title={An Efficient Hardware Implementation of Multialphabet Adaptive Arithmetic Encoder Based on Generalized Virtual Sliding Window},
     //      year={2020},
     //      volume={28},
     //      number={5},
     //      pages={1326-1330},
     //      doi={10.1109/TVLSI.2020.2966306}}
// Its main goal is to update range and low without a multiplier



char new_filename[50];
uint16_t range_new, previous_new;
uint32_t low_new;
int16_t cnt_new;
int bitstream_new = 0, flag_first_new = 1, counter_255_new = 0;
// ------------------------------------------------------


void add_to_final_original(uint16_t val);
void serial_release(int op, int val, int times);
void carry_propag(int final_flag, int flag, uint16_t b1, uint16_t b2);

uint16_t previous, bit1, bit2;
int counter_255 = 0, flag_first = 1, bitstream_generated = 0;

// -----------------------------------------------------


int16_t cnt;
uint16_t range;
uint32_t low;
uint16_t previous;
int offs = 0;
int stop_after_reset_flag;
int reset_counter, bitstream_counter;

// ---------------------
void print_bar(int current, int total);           // This function is only used to print a progress bar
int range_analyzer_file = 0;  // This variable defines wheather to create the file to analyze the range or not
          // This file comprises different values that are related to the range generation
          // This is a CSV file containing:
               // range_in; uv_bool_def; fl, fh; range_without_lut; range_raw;
          // Where:
               // uv_bool_def is the definition of the equation used for the range_raw generation

int save_multiplication = 0;  // this variable allows the saving of the multiplication inputs

// ---------------------
// Time variables
clock_t cumulative_time_new = 0, cumulative_time_old = 0;
clock_t temp_time;
double get_time(clock_t input);
// ---------------------

int verify_bitstream_counter;
int last_final_flag, last_flag;
uint16_t last_b1, last_b2;
int last_counter_255;
int last_flag_first;
uint16_t last_previous;


// -------------------
clock_t total_time = 0, total_time_carry = 0;
// -------------------
// New Logic Functions
void add_to_final_new(uint16_t val);
void new_carry_propag(int final_flag, int flag, uint16_t b1, uint16_t b2);
void new_q15(unsigned fl, unsigned fh, int s, int nsyms);
void new_bool_q15(int val, unsigned f);
void new_normalize(uint32_t low_norm, unsigned rng);
void final_bits_new();
// --------------------------------
void timing_analyzer();
int run_simulation();
void setup();
void final_bits();
void reset_function();
uint32_t get_Low();
uint16_t get_Range();
int16_t get_cnt();
void od_ec_encode_q15(unsigned fl, unsigned fh, int s, int nsyms);;
void od_ec_encode_bool_q15(int val, unsigned f);
void od_ec_enc_normalize(uint32_t low_norm, unsigned rng);
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
     verify_bitstream_counter = 0;
     bitstream_generated = 0;
     // --------
     cumulative_time_new = 0;
     cumulative_time_old = 0;
     // --------
     if((stat("output-files/", &sb) != 0) || !S_ISDIR(sb.st_mode))
     mkdir("output-files", 0700);

     if(save_multiplication){
          if((arq = fopen("output-files/mult_inputs.csv", "w+")) == NULL){
               printf("Unable to create mult_input file.\n");
               exit(EXIT_FAILURE);
          }else{
               fclose(arq);
          }
     }

     if(FLAG_NEW_LOGIC == 1 || FLAG_NEW_LOGIC == 2){
          strcpy(new_filename, "output-files/new_logic.csv");
          if((arq = fopen(new_filename, "w+")) == NULL){
               printf("Unable to create the NEW_LOGIC file.\n");
               exit(EXIT_FAILURE);
          }else{
               fclose(arq);
          }
     }

     if(range_analyzer_file){
          if((arq = fopen("output-files/range_analyzer.csv", "w+")) == NULL){
               printf("Unable to create range_analyzer_file.\n");
               exit(EXIT_FAILURE);
          }else{
               fprintf(arq, "range_in; equation; fl; fh; u_no_lut; v_no_lut\n");
               fclose(arq);
          }
     }


     reset_function();
     arq = fopen("output-files/original_bitstream.csv", "w+");
     fclose(arq);
}

void reset_function(){
     if(FLAG_NEW_LOGIC == 0 || FLAG_NEW_LOGIC == 2){
          cnt = -9;
          range = 32768;
          low = 0;
     }
     if(FLAG_NEW_LOGIC == 1 || FLAG_NEW_LOGIC == 2){
          range_new = 32768;
          low_new = 0;
          cnt_new = -9;
     }
     if(FLAG_NEW_LOGIC != 0 && FLAG_NEW_LOGIC != 1 && FLAG_NEW_LOGIC != 2){
          printf("ERROR: FLAG_NEW_LOGIC is invalid.\n");
          exit(EXIT_FAILURE);
     }
}


int main(int argc, char **argv){
     int status;
     if(argc <= 0){
          printf("\t-> CONFIG: Don't stop after first reset (no argument)\n");
          stop_after_reset_flag = 0;
     }else{
          if((strcmp(argv[1], "1")) == 0){
               stop_after_reset_flag = 1;
               printf("\t-> CONFIG: Stop after first reset\n");
          }else{
               stop_after_reset_flag = 0;
               printf("\t-> CONFIG: Don't stop after first reset\n");
          }
     }

     if(FLAG_NEW_LOGIC == 2)
          printf("\t-> CONFIG: Running both logics.\n");
     else if(FLAG_NEW_LOGIC == 1)
          printf("\t-> CONFIG: Running only the NEW logic.\n");
     else if(FLAG_NEW_LOGIC == 0)
          printf("\t-> CONFIG: Running only the ORIGINAL logic.\n");
     else{
          printf("\t-> ERROR: FLAG_NEW_LOGIC invalid.\n");
          exit(EXIT_FAILURE);
     }

     #if OD_EC_REDUCED_OVERHEAD
          printf("\t-> CONFIG: using reduced overhead.\n");
     #else
          printf("\t-> CONFIG: using normal overhead.\n");
     #endif

     printf("=========================\n");
     setup();
     status = run_simulation();
     timing_analyzer();
     return 0;
}

double get_time(clock_t input){
     return (double)(input * 1000 / CLOCKS_PER_SEC);
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
     if((arq_input = fopen("/media/tulio/HD1/y4m_files/generated_files/cq_20/Bosphorus_1920x1080_120fps_420_8bit_YUV_cq20_main_data.csv", "r")) != NULL){
          i = 0;
          status = 1;
          reset = 0;
          while((i <= MAX_INPUTS) && (final_flag != 1) && (status != 0) && (reset != 1)){
               if((i%PRINT_RATE) == 0)
                    printf("\rInput # %d, Reset # %d, Time Old: %.2lf ms, Time New: %.2lf ms, Original Bitstream: %i, New Bitstream: %i.",
                         i, reset_counter, get_time(cumulative_time_old), get_time(cumulative_time_new), bitstream_generated, bitstream_new);
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
                         //printf("Reset Detected!\n");
                         if(FLAG_NEW_LOGIC == 1 || FLAG_NEW_LOGIC == 2)
                              final_bits_new();
                         if(FLAG_NEW_LOGIC == 0 || FLAG_NEW_LOGIC == 2)
                              final_bits();
                         flag_first_new = 1;
                         flag_first = 1;
                         end = clock();
                         reset_function();
                         total_time_carry = total_time_carry + (end-begin);
                         if(stop_after_reset_flag)
                              reset = 1;
                    }
                    begin = clock();
                    if(bool){
                         if(FLAG_NEW_LOGIC == 0 || FLAG_NEW_LOGIC == 2)
                              od_ec_encode_q15(fl, fh, s, nsyms);
                         if(FLAG_NEW_LOGIC == 1 || FLAG_NEW_LOGIC == 2)
                              new_q15(fl, fh, s, nsyms);
                    }else{
                         if(FLAG_NEW_LOGIC == 0 || FLAG_NEW_LOGIC == 2)
                              od_ec_encode_bool_q15(s, fh);
                         if(FLAG_NEW_LOGIC == 1 || FLAG_NEW_LOGIC == 2)
                              new_bool_q15(s, fh);
                    }
                    if(verify_bitstream_counter>0 && flag_first != 1){
                         if((verify_bitstream_counter-1-counter_255) != bitstream_generated){
                              printf("\nBitstreams: %d\nVerifier: %d\n", bitstream_generated, verify_bitstream_counter);
                              printf("\nLast Inputs into Carry Propag: ");
                              printf("\t-> Flag_First = %i\n\t-> Flag = %i\n\t-> B1 = %" PRIu16 "\n\t-> B2 = %" PRIu16 "\n\t-> Prev = %" PRIu16 "\n\t-> Counter 255 = %d\n", last_final_flag, last_flag, last_b1, last_b2, previous, counter_255);
                              printf("\n\t-> Last Counter = %d\n\t-> Last Flag First = %d\n\t-> Last Previous = %" PRIu16 "\n", last_counter_255, last_flag_first, last_previous);

                              assert((verify_bitstream_counter-1-counter_255) == bitstream_generated);
                         }
                    }
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
               printf("\n=========================\nFinished with reset\n");
               if(FLAG_NEW_LOGIC == 1 || FLAG_NEW_LOGIC == 2)
                    final_bits_new();
               if(FLAG_NEW_LOGIC == 0 || FLAG_NEW_LOGIC == 2)
                    final_bits();
          }else{
               if(FLAG_NEW_LOGIC == 1 || FLAG_NEW_LOGIC == 2)
                    final_bits_new();
               if(FLAG_NEW_LOGIC == 0 || FLAG_NEW_LOGIC == 2)
                    final_bits();
               printf("\n=========================\nNo error found.\n");
               printf("Times:\n\t-> Old logic: %.2lf ms\n\t-> New logic: %.2lf ms\n", get_time(cumulative_time_old), get_time(cumulative_time_new));
               printf("=========================\n");
          }
     }else{
          printf("Unable to open the input file.\n");
          return -1;
     }


     return 0;
}

void save_mult_inputs(unsigned r, uint32_t other){
     FILE *arq;
     if((arq = fopen("output-files/mult_inputs.csv", "a+")) != NULL){
          fprintf(arq, "%"PRIu16";%"PRIu32";\n", r, other);
          fclose(arq);
     }else{
          printf("Unable to save into the mult_inputs file\n");
          exit(EXIT_FAILURE);
     }
}

void add_to_file(int bool_flag, unsigned range_in, char equation[], unsigned fl, unsigned fh, unsigned u, unsigned v){
     FILE *arq;
     if((arq = fopen("output-files/range_analyzer.csv", "a+")) == NULL){
          printf("Error opening range_analyzer_file");
          exit(EXIT_FAILURE);
     }else{
          if(bool_flag)
               fprintf(arq, "%"PRIu16";%s;%"PRIu16";N/A;N/A;%"PRIu16";\n", range_in, equation, fl, v);
          else
               fprintf(arq, "%"PRIu16";%s;%"PRIu16";%"PRIu16";%"PRIu16";%"PRIu16";\n", range_in, equation, fl, fh, u, v);
          fclose(arq);
     }
}

#define OD_SUBSATU(a, b) ((a) - OD_MINI(a, b))
#define OD_MINI(a, b) ((a) ^ (((b) ^ (a)) & -((b) < (a))))

void new_q15(unsigned fl, unsigned fh, int s, int nsyms) {
     uint32_t l;
     unsigned r;
     unsigned u;
     unsigned v;
     unsigned d;
     unsigned ss;
     l = low_new;
     r = range_new;
     unsigned ft;
     ft = 32768U;
     // On the AV1 reference code there is an assert that ensures (icdf[nsyms-1] == CDF_PROB_TOP), which is 32,768
     // Hence, there is not much to do regarding this variable, as the AV1 itself uses it on it's maximum
     // According to the Daala definition, however, this variable might variate within the range 16,384 <= ft <= 32,768
     // I don't believe there is anything working with fixing this value at 32,768.
     assert(32768U <= r);
     assert(fh <= fl);
     assert(fl <= 32768U);
     assert(7 - EC_PROB_SHIFT - CDF_SHIFT >= 0);
     const int N = nsyms - 1;

     // Time control
     temp_time = clock();
     // -------------------
     ss = r - ft >= ft;
     ft <<= ss;
     fl <<= ss;
     fh <<= ss;
     d = r - ft;
     // ------------
     #if OD_EC_REDUCED_OVERHEAD
     {
          unsigned e;
          e = OD_SUBSATU(2*d, ft);
          u = fl + OD_MINI(fl, e) + OD_MINI(OD_SUBSATU(fl, e) >> 1, d);
          v = fh + OD_MINI(fh, e) + OD_MINI(OD_SUBSATU(fh, e) >> 1, d);
     }
     #else
          u = fl + OD_MINI(fl, d);
          v = fh + OD_MINI(fh, d);
     #endif
     // ------------
     if (u > v) {     // Comparison created to assert data for the Daala method
          l += r - u;
          r = u - v;
     } else
          r -= v;
     // r = u-v;
     // printf("\n%" PRIu32 "\t%" PRIu32 "\n", u, v);
     // printf("%" PRIu32 "\t%" PRIu32 "\n", r, range_new);
     // exit(EXIT_SUCCESS);
     //l += u;      // Daala method to set low
     // Time control
     cumulative_time_new += clock() - temp_time;
     // -------------
     new_normalize(l, r);
}

void new_bool_q15(int val, unsigned f) {
     uint32_t l;
     unsigned r;
     unsigned v;
     unsigned s;
     unsigned ft;
     ft = 32768U;
     assert(0 < f);
     assert(f < 32768U);
     l = low_new;
     r = range_new;

     assert(32768U <= r);
     // Time control
     temp_time = clock();
     // -------------------
     s = r - ft >= ft;
     ft <<= s;
     f <<= s;
     // -------------
     #if OD_EC_REDUCED_OVERHEAD
     {
          unsigned d;
          unsigned e;
          d = r - ft;
          e = OD_SUBSATU(2*d, ft);
          v = f + OD_MINI(f, e) + OD_MINI(OD_SUBSATU(f, e) >> 1, d);
     }
     #else
          v = f + OD_MINI(f, r - ft);
     #endif
     // -------------
     // if (val) l += v;           // Daala method to set low
     // r = val ? r - v : v;       // Daala method to set range
     // ------
     // AV1 original methods to set Range and Low
     if (val)
          l += r - v;
     r = val ? v : r - v;
     // ------
     // Time control
     cumulative_time_new += clock() - temp_time;
     // -------------
     new_normalize(l, r);
}

void new_normalize(uint32_t low_norm, unsigned rng) {
     int d;
     int c;
     int s;
     uint16_t b1, b2;
     int flag = 0;
     c = cnt_new;
     assert(rng <= 65535U);
     d = 16 - (1 + (31 ^ __builtin_clz(rng)));
     s = c + d;
     if (s >= 0) {
          unsigned m;
          c += 16;
          m = (1 << c) - 1;
          if (s >= 8) {
               flag++;
               b1 = (uint16_t)(low_norm >> c);
               low_norm &= m;
               c -= 8;
               m >>= 8;
          }
          // assert(offs < storage);
          //printf("Low: %" PRIu32 "\tc = %i\td = %i\tcnt = %i\n", low, c, d, cnt );
          if(flag == 1){
               flag++;
               b2 = (uint16_t)(low_norm >> c);
          }else{
               flag++;
               b1 = (uint16_t)(low_norm >> c);
               b2 = 0;
          }
          s = c + d - 24;
          low_norm &= m;
     }
     low_new = low_norm << d;
     range_new = rng << d;
     cnt_new = s;
     if(flag != 0)
          new_carry_propag(0, flag, b1, b2);
}

void final_bits_new(){
     uint16_t temp_bitstream;
     uint16_t *buf;
     unsigned char *out;
     uint32_t l, e, m;
     int c, s;
     l = low_new;
     c = cnt_new;
     s = 10;
     m = 0x3FFF;
     e = ((l + m) & ~m) | (m + 1);
     s += c;
     if(s > 0){
          unsigned n;
          n = (1 << (c + 16)) - 1;
          do{
               temp_bitstream = (uint16_t)(e >> (c + 16));
               e &= n;
               s -= 8;
               if(s > 0)
                    new_carry_propag(0, 1, temp_bitstream, 0);
               else
                    new_carry_propag(1, 1, temp_bitstream, 0);

               c -= 8;
               n >>= 8;
          }while(s > 0);
     }
}

void new_carry_propag(int final_flag, int flag, uint16_t b1, uint16_t b2){
     //printf("-> Flag_First = %i\t-> Flag = %i\t-> B1 = %" PRIu16 "\t-> B2 = %" PRIu16 "\t-> Prev = %" PRIu16 "\n", flag_first, flag, b1, b2, previous_new);
     if(flag_first_new == 1 && flag != 0){
          flag_first_new = 0;
          if(flag == 1){
               if(b1 > 255)
                    previous_new = b1 - SUB_BITSTREAM;
               else
                    previous_new = b1;
          }else if(flag == 2 && b2 != 255){
               if(b2 > 255){
                    if(b1 > 255)
                         add_to_final_new(b1-SUB_BITSTREAM+1);
                    else
                         add_to_final_new(b1+1);
                    previous_new = b2 - SUB_BITSTREAM;
               }else{
                    if(b1 > 255)
                         add_to_final_new(b1-SUB_BITSTREAM);
                    else
                         add_to_final_new(b1);
                    previous_new = b2;
               }
               counter_255_new = 0;
          }else if(flag == 2 && b2 == 255){
               counter_255_new = 1;
               if(b1 > 255)
                    previous_new = b1 - SUB_BITSTREAM;
               else
                    previous_new = b1;
          }
     }else{
          if(flag == 1 && b1 != 255 && counter_255_new == 0){
               if(b1 > 255){
                    add_to_final_new(previous_new+1);
                    previous_new = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_new(previous_new);
                    previous_new = b1;
               }
          }else if(flag == 2 && b2 != 255 && counter_255_new == 0){
               if(b1 == 255){
                    if(b2 > 255){
                         add_to_final_new(previous_new+1);
                         add_to_final_new(0);
                         previous_new = b2-SUB_BITSTREAM;
                    }else{
                         add_to_final_new(previous_new);
                         add_to_final_new(b1);
                         previous_new = b2;
                    }
               }else{
                    if(b1 > 255){
                         add_to_final_new(previous_new+1);
                         b1 = b1 - SUB_BITSTREAM;
                    }else
                         add_to_final_new(previous_new);
                    if(b2 > 255){
                         add_to_final_new(b1+1);
                         previous_new = b2 - SUB_BITSTREAM;
                    }else{
                         add_to_final_new(b1);
                         previous_new = b2;
                    }
               }
          }else if(flag == 1 && b1 == 255){
               counter_255_new++;
          }else if(flag == 2 && b1 == 255 && b2 == 255){
               counter_255_new = counter_255_new + 2;
          }else if(flag == 2 && b2 == 255 && b1 != 255 && counter_255_new == 0){
               if(b1 > 255){
                    add_to_final_new(previous_new+1);
                    previous_new = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_new(previous_new);
                    previous_new = b1;
               }
               counter_255_new = 1;
          }else if(flag == 1 && b1 != 255 && counter_255_new > 0){
               if(b1 > 255){
                    add_to_final_new(previous_new+1);
                    serial_release(1, 0, counter_255_new);
                    counter_255_new = 0;
                    previous_new = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_new(previous_new);
                    serial_release(1, 255, counter_255_new);
                    counter_255_new = 0;
                    previous_new = b1;
               }
          }else if(flag == 2 && b2 != 255 && counter_255_new > 0){
               if(b1 == 255){
                    counter_255_new++;
                    if(b2 > 255){
                         add_to_final_new(previous_new+1);
                         serial_release(1, 0, counter_255_new);
                         counter_255_new = 0;
                         previous_new = b2 - SUB_BITSTREAM;
                    }else{
                         add_to_final_new(previous_new);
                         serial_release(1, 255, counter_255_new);
                         counter_255_new = 0;
                         previous_new = b2;
                    }
               }else{
                    if(b1 > 255){
                         add_to_final_new(previous_new+1);
                         serial_release(1, 0, counter_255_new);
                         counter_255_new = 0;
                         if(b2 > 255){
                              add_to_final_new(b1 - SUB_BITSTREAM + 1);
                              previous_new = b2 - SUB_BITSTREAM;
                         }else{
                              add_to_final_new(b1 - SUB_BITSTREAM);
                              previous_new = b2;
                         }
                    }else{
                         add_to_final_new(previous_new);
                         serial_release(1, 255, counter_255_new);
                         counter_255_new = 0;
                         if(b2 > 255){
                              add_to_final_new(b1 + 1);
                              previous_new = b2 - SUB_BITSTREAM;
                         }else{
                              add_to_final_new(b1);
                              previous_new = b2;
                         }
                    }
               }
          }else if(flag == 2 && b2 == 255 && b1 != 255 && counter_255_new > 0){
               if(b1 > 255){
                    add_to_final_new(previous_new+1);
                    serial_release(1, 0, counter_255_new);
                    previous_new = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_new(previous_new);
                    serial_release(1, 255, counter_255_new);
                    previous_new = b1;
               }
               counter_255_new = 1;
          }
     }
     if(final_flag == 1 && counter_255_new == 0){
          add_to_final_new(previous_new);
     }else if(final_flag == 1 && counter_255_new > 0){
          add_to_final_new(previous_new);
          serial_release(1, 255, counter_255_new);
          counter_255_new = 0;
     }
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
     // Time control
     temp_time = clock();
     // -------------------
     u = ((r >> 8) * (uint32_t)(fl >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT - CDF_SHIFT)) + EC_MIN_PROB * (N - (s - 1));
     v = ((r >> 8) * (uint32_t)(fh >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT - CDF_SHIFT)) + EC_MIN_PROB * (N - (s + 0));
     if (fl < CDF_PROB_TOP) {
          l += r - u;
          r = u - v;
     } else
          r -= v;
     // Time control
     cumulative_time_old += clock() - temp_time;
     // -------------
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
     // Time control
     temp_time = clock();
     // -------------------
     v = ((r >> 8) * (uint32_t)(f >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT));
     if(save_multiplication){
          save_mult_inputs((r >> 8), (uint32_t)(f >> EC_PROB_SHIFT));
     }
     v += EC_MIN_PROB;
     if (val)
          l += r - v;
     r = val ? v : r - v;
     if(range_analyzer_file){
          if(val)
               add_to_file(1, range, "bool v", f, 0, 1, (v-EC_MIN_PROB));
          else
               add_to_file(1, range, "bool r-v", f, 0, 1, (v-EC_MIN_PROB));
     }
     // Time control
     cumulative_time_old += clock() - temp_time;
     // -------------
     od_ec_enc_normalize(l, r);
}

void od_ec_enc_normalize(uint32_t low_norm, unsigned rng) {
     int d;
     int c;
     int s;
     uint16_t b1, b2;
     int flag = 0;
     c = cnt;
     assert(rng <= 65535U);
     d = 16 - (1 + (31 ^ __builtin_clz(rng)));
     s = c + d;
     if (s >= 0) {
          unsigned m;
          c += 16;
          m = (1 << c) - 1;
          if (s >= 8) {
               flag++;
               b1 = (uint16_t)(low_norm >> c);
               low_norm &= m;
               c -= 8;
               m >>= 8;
          }
          // assert(offs < storage);
          //printf("Low: %" PRIu32 "\tc = %i\td = %i\tcnt = %i\n", low, c, d, cnt );
          if(flag == 1){
               flag++;
               b2 = (uint16_t)(low_norm >> c);
          }else{
               flag++;
               b1 = (uint16_t)(low_norm >> c);
               b2 = 0;
          }
          s = c + d - 24;
          low_norm &= m;
     }
     low = low_norm << d;
     range = rng << d;
     cnt = s;
     verify_bitstream_counter += flag;

     if(flag != 0)
          carry_propag(0, flag, b1, b2);

}




void final_bits(){
     uint16_t temp_bitstream;
     uint16_t *buf;
     unsigned char *out;
     uint32_t l, e, m;
     int c, s;
     l = low;
     c = cnt;
     s = 10;
     m = 0x3FFF;
     e = ((l + m) & ~m) | (m + 1);
     s += c;
     if(s > 0){
          unsigned n;
          n = (1 << (c + 16)) - 1;
          do{
               temp_bitstream = (uint16_t)(e >> (c + 16));
               e &= n;
               s -= 8;
               verify_bitstream_counter++;
               if(s > 0)
                    carry_propag(0, 1, temp_bitstream, 0);
               else
                    carry_propag(1, 1, temp_bitstream, 0);

               c -= 8;
               n >>= 8;
          }while(s > 0);
     }
}

void carry_propag(int final_flag, int flag, uint16_t b1, uint16_t b2){
     last_final_flag = final_flag;
     last_flag = flag;
     last_b1 = b1;
     last_b2 = b2;
     last_counter_255 = counter_255;
     last_flag_first = flag_first;
     last_previous = previous;
     //printf("-> Flag_First = %i\t-> Flag = %i\t-> B1 = %" PRIu16 "\t-> B2 = %" PRIu16 "\t-> Prev = %" PRIu16 "\n", flag_first, flag, b1, b2, previous);
     if(flag_first == 1 && flag != 0){
          flag_first = 0;
          if(flag == 1){
               if(b1 > 255)
                    previous = b1 - SUB_BITSTREAM;
               else
                    previous = b1;
          }else if(flag == 2 && b2 != 255){
               if(b2 > 255){
                    if(b1 > 255)
                         add_to_final_original(b1-SUB_BITSTREAM+1);
                    else
                         add_to_final_original(b1+1);
                    previous = b2 - SUB_BITSTREAM;
               }else{
                    if(b1 > 255)
                         add_to_final_original(b1-SUB_BITSTREAM);
                    else
                         add_to_final_original(b1);
                    previous = b2;
               }
               counter_255 = 0;
          }else if(flag == 2 && b2 == 255){
               counter_255 = 1;
               if(b1 > 255)
                    previous = b1 - SUB_BITSTREAM;
               else
                    previous = b1;
          }
     }else{
          if(flag == 1 && b1 != 255 && counter_255 == 0){
               if(b1 > 255){
                    add_to_final_original(previous+1);
                    previous = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_original(previous);
                    previous = b1;
               }
          }else if(flag == 2 && b2 != 255 && counter_255 == 0){
               if(b1 == 255){
                    if(b2 > 255){
                         add_to_final_original(previous+1);
                         add_to_final_original(0);
                         previous = b2-SUB_BITSTREAM;
                    }else{
                         add_to_final_original(previous);
                         add_to_final_original(b1);
                         previous = b2;
                    }
               }else{
                    if(b1 > 255){
                         add_to_final_original(previous+1);
                         b1 = b1 - SUB_BITSTREAM;
                    }else
                         add_to_final_original(previous);
                    if(b2 > 255){
                         add_to_final_original(b1+1);
                         previous = b2 - SUB_BITSTREAM;
                    }else{
                         add_to_final_original(b1);
                         previous = b2;
                    }
               }
          }else if(flag == 1 && b1 == 255){
               counter_255++;
          }else if(flag == 2 && b1 == 255 && b2 == 255){
               counter_255 = counter_255 + 2;
          }else if(flag == 2 && b2 == 255 && b1 != 255 && counter_255 == 0){
               if(b1 > 255){
                    add_to_final_original(previous+1);
                    previous = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_original(previous);
                    previous = b1;
               }
               counter_255 = 1;
          }else if(flag == 1 && b1 != 255 && counter_255 > 0){
               if(b1 > 255){
                    add_to_final_original(previous+1);
                    serial_release(0, 0, counter_255);
                    counter_255 = 0;
                    previous = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_original(previous);
                    serial_release(0, 255, counter_255);
                    counter_255 = 0;
                    previous = b1;
               }
          }else if(flag == 2 && b2 != 255 && counter_255 > 0){
               if(b1 == 255){
                    counter_255++;
                    if(b2 > 255){
                         add_to_final_original(previous+1);
                         serial_release(0, 0, counter_255);
                         counter_255 = 0;
                         previous = b2 - SUB_BITSTREAM;
                    }else{
                         add_to_final_original(previous);
                         serial_release(0, 255, counter_255);
                         counter_255 = 0;
                         previous = b2;
                    }
               }else{
                    if(b1 > 255){
                         add_to_final_original(previous+1);
                         serial_release(0, 0, counter_255);
                         counter_255 = 0;
                         if(b2 > 255){
                              add_to_final_original(b1 - SUB_BITSTREAM + 1);
                              previous = b2 - SUB_BITSTREAM;
                         }else{
                              add_to_final_original(b1 - SUB_BITSTREAM);
                              previous = b2;
                         }
                    }else{
                         add_to_final_original(previous);
                         serial_release(0, 255, counter_255);
                         counter_255 = 0;
                         if(b2 > 255){
                              add_to_final_original(b1 + 1);
                              previous = b2 - SUB_BITSTREAM;
                         }else{
                              add_to_final_original(b1);
                              previous = b2;
                         }
                    }
               }
          }else if(flag == 2 && b2 == 255 && b1 != 255 && counter_255 > 0){
               if(b1 > 255){
                    add_to_final_original(previous+1);
                    serial_release(0, 0, counter_255);
                    previous = b1 - SUB_BITSTREAM;
               }else{
                    add_to_final_original(previous);
                    serial_release(0, 255, counter_255);
                    previous = b1;
               }
               counter_255 = 1;
          }
     }
     if(final_flag == 1 && counter_255 == 0){
          add_to_final_original(previous);
     }else if(final_flag == 1 && counter_255 > 0){
          add_to_final_original(previous);
          serial_release(0, 255, counter_255);
          counter_255 = 0;
     }
}

void add_to_final_original(uint16_t val){
     FILE *arq;
     if((arq = fopen("output-files/original_bitstream.csv", "a+")) != NULL){
          fprintf(arq, "%" PRIu16 ";\n", val);
          fclose(arq);
          bitstream_generated++;
     }else{
          printf("Unable to open the final bitstream file.\n");
          exit(EXIT_FAILURE);
     }
     //printf("Val: %" PRIu16 "\n", val);
}

void add_to_final_new(uint16_t val){
     FILE *arq;
     if((arq = fopen(new_filename, "a+")) != NULL){
          fprintf(arq, "%" PRIu16 ";\n", val);
          fclose(arq);
          bitstream_new++;
     }else{
          printf("Unable to open the final bitstream file.\n");
          exit(EXIT_FAILURE);
     }
     //printf("Val: %" PRIu16 "\n", val);
}


void serial_release(int op, int val, int times){
     do{
          if(op == 1)
               add_to_final_new(val);
          else
               add_to_final_original(val);
          times--;
     }while(times > 0);
}

void print_bar(int current, int total){
     char *str_print;
     str_print = (char*)malloc(sizeof(char)*50);
     int i;
     float p;
     int num_hashs;
     p = (((float)current)/((float)total))*100;
     num_hashs = (int)(p);
     //printf("Num: %i\n", num_hashs);
     for(i=0;i<50;i++){
          if(i <= num_hashs)
               str_print[i] = '#';
          else
               str_print[i] = '_';
     }
     printf("\r[%s] %.2f %% \t %d/%d", str_print, p, current, total);
     fflush(stdin);
}
