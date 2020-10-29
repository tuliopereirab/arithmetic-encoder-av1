#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <inttypes.h>


#define EC_PROB_SHIFT 6
#define CDF_SHIFT 0
#define EC_MIN_PROB 4
#define CDF_PROB_TOP 32768

#define MAX_INPUTS 1000

int16_t cnt;
uint16_t range;
uint32_t low;

uint32_t get_Low();
uint16_t get_Range();
int16_t get_cnt();
void od_ec_encode_q15(unsigned fl, unsigned fh, int s, int nsyms);;
void od_ec_encode_bool_q15(int val, unsigned f);
void od_ec_enc_normalize(uint32_t low_norm, unsigned rng);
void add_bitstream_file(uint16_t bitstream);

uint32_t get_Low(){
     return low;
}

uint16_t get_Range(){
     return range;
}

int16_t get_cnt(){
     return cnt;
}

int main(){
    FILE *arq_input;
    int i, status;
    // init
    cnt = -9;
    range = 32768;
    low = 0;
    // -----
    unsigned fl, fh;
    uint16_t file_input_range, file_in_norm_range, file_output_range;
    uint32_t file_input_low, file_in_norm_low, file_output_low;
    int s, nsyms, bool;
    if((arq_input = fopen("input-files/main_data", "r")) != NULL){
        i = 0;
        status = 1;
        while((i < MAX_INPUTS) && (status != 0)){
            fscanf(arq_input, "%i;%i;%i;%i;%i;%i;%i;%i;%i;%i;%i\n", &bool, &file_input_range, &file_input_low, &fl, &fh, &s, &nsyms, &file_in_norm_range, &file_in_norm_low, &file_output_range, &file_output_low);
            printf("Input %i:\nFL = %"PRIu16"\tFH = %"PRIu16"\ts = %i\tnsyms = %i\n", i, fl, fh, s, nsyms);
            if(bool)
                od_ec_encode_q15(fl, fh, s, nsyms);
            else
                od_ec_encode_bool_q15(s, fh);
            printf("Output:\nLow = %" PRIu32 "\tRange = %" PRIu16 "\tCnt = %" PRId16 "\n----------------------\n", low, range, cnt);
            if((file_output_range != range) || (file_output_low != low))
                status = 0;
            i++;
        }
    }else{
        printf("Unable to open the input file.\n");
    }
    if(status == 0){
        printf("Execution finished with error\n=========================\n");
        printf("Line: %i\n\t-> Low expected: %" PRIu32 ", got %" PRIu32 "\n\t-> Range expected: %" PRIu16 ", got %" PRIu16 "\n", i-1, file_output_low, low, file_output_range, range);
        printf("--------------------------------------------------\n");
    }else{
        printf("No error found.\n");
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
          // uint16_t *buf;
          // uint32_t storage;
          // uint32_t offs;
          unsigned m;
          // buf = enc->precarry_buf;
          // storage = enc->precarry_storage;
          // offs = enc->offs;
          // Not used for now
          // if (offs + 2 > storage) {
          //      storage = 2 * storage + 2;
          //      buf = (uint16_t *)realloc(buf, sizeof(*buf) * storage);
          //      if (buf == NULL) {
          //           enc->error = -1;
          //           enc->offs = 0;
          //           return;
          //      }
          //      enc->precarry_buf = buf;
          //      enc->precarry_storage = storage;
          // }
          // ---------------------------------------------------------------------------
          c += 16;
          m = (1 << c) - 1;
          if (s >= 8) {
               // assert(offs < storage);
               // buf[offs++] = (uint16_t)(low >> c);
               add_bitstream_file((uint16_t)(low >> c));
               low_norm &= m;
               c -= 8;
               m >>= 8;
          }
          // assert(offs < storage);
          // buf[offs++] = (uint16_t)(low >> c);
          add_bitstream_file((uint16_t)(low >> c));
          s = c + d - 24;
          low_norm &= m;
          // enc->offs = offs;
     }
     low = low_norm << d;
     range = rng << d;
     cnt = s;
}


void add_bitstream_file(uint16_t bitstream){
    FILE *arq;
    if((arq = fopen("output-file/pre_bitstream", "a")) != NULL){
        fprintf(arq, "%" PRIu32 "\n", bitstream);
        fclose(arq);
    }else
        printf("Unable to open the bitstream file\n");
}
