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

int16_t cnt;
uint16_t range;
uint32_t low;

uint32_t get_Low();
uint16_t get_Range();
int16_t get_cnt();
void od_ec_encode_q15(unsigned fl, unsigned fh, int s, int nsyms);
void od_ec_enc_normalize(uint32_t low_norm, unsigned rng);

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
     int i;
     // init
     cnt = -9;
     range = 32768;
     low = 0;
     // -----
     unsigned fl, fh;
     int s, nsyms;
     if((arq_input = fopen("input-files/input", "r")) != NULL){
          for(i=0;i<100; i++){
               fscanf(arq_input, "%i;%i;%i;%i;\n", &fl, &fh, &s, &nsyms);
               printf("Input %i:\nFL = %"PRIu16"\tFH = %"PRIu16"\ts = %i\tnsyms = %i\n", i, fl, fh, s, nsyms);
               od_ec_encode_q15(fl, fh, s, nsyms);
               printf("Output:\nLow = %" PRIu32 "\tRange = %" PRIu16 "\tCnt = %" PRId16 "\n----------------------\n", low, range, cnt);
          }
     }else{
          printf("Unable to open the input file.\n");
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
               low_norm &= m;
               c -= 8;
               m >>= 8;
          }
          // assert(offs < storage);
          // buf[offs++] = (uint16_t)(low >> c);
          s = c + d - 24;
          low_norm &= m;
          // enc->offs = offs;
     }
     low = low_norm << d;
     range = rng << d;
     cnt = s;
}
