/*
 * Copyright (c) 2001-2016, Alliance for Open Media. All rights reserved
 *
 * This source code is subject to the terms of the BSD 2 Clause License and
 * the Alliance for Open Media Patent License 1.0. If the BSD 2 Clause License
 * was not distributed with this source code in the LICENSE file, you can
 * obtain it at www.aomedia.org/license/software. If the Alliance for Open
 * Media Patent License 1.0 was not distributed with this source code in the
 * PATENTS file, you can obtain it at www.aomedia.org/license/patent.
 */

#include <assert.h>
#include "aom_dsp/entdec.h"
#include "aom_dsp/prob.h"


int flag_first_dec = 1;
void add_to_file(uint16_t icdf, uint32_t dif, unsigned r, int nsyms, unsigned f, const unsigned char *bptr, const unsigned char *end, int file_code, int print_code);

/*A range decoder.
  This is an entropy decoder based upon \cite{Mar79}, which is itself a
   rediscovery of the FIFO arithmetic code introduced by \cite{Pas76}.
  It is very similar to arithmetic encoding, except that encoding is done with
   digits in any base, instead of with bits, and so it is faster when using
   larger bases (i.e.: a byte).
  The author claims an average waste of $\frac{1}{2}\log_b(2b)$ bits, where $b$
   is the base, longer than the theoretical optimum, but to my knowledge there
   is no published justification for this claim.
  This only seems true when using near-infinite precision arithmetic so that
   the process is carried out with no rounding errors.

  An excellent description of implementation details is available at
   http://www.arturocampos.com/ac_range.html
  A recent work \cite{MNW98} which proposes several changes to arithmetic
   encoding for efficiency actually re-discovers many of the principles
   behind range encoding, and presents a good theoretical analysis of them.

  End of stream is handled by writing out the smallest number of bits that
   ensures that the stream will be correctly decoded regardless of the value of
   any subsequent bits.
  od_ec_dec_tell() can be used to determine how many bits were needed to decode
   all the symbols thus far; other data can be packed in the remaining bits of
   the input buffer.
  @PHDTHESIS{Pas76,
    author="Richard Clark Pasco",
    title="Source coding algorithms for fast data compression",
    school="Dept. of Electrical Engineering, Stanford University",
    address="Stanford, CA",
    month=May,
    year=1976,
    URL="http://www.richpasco.org/scaffdc.pdf"
  }
  @INPROCEEDINGS{Mar79,
   author="Martin, G.N.N.",
   title="Range encoding: an algorithm for removing redundancy from a digitised
    message",
   booktitle="Video & Data Recording Conference",
   year=1979,
   address="Southampton",
   month=Jul,
   URL="http://www.compressconsult.com/rangecoder/rngcod.pdf.gz"
  }
  @ARTICLE{MNW98,
   author="Alistair Moffat and Radford Neal and Ian H. Witten",
   title="Arithmetic Coding Revisited",
   journal="{ACM} Transactions on Information Systems",
   year=1998,
   volume=16,
   number=3,
   pages="256--294",
   month=Jul,
   URL="http://researchcommons.waikato.ac.nz/bitstream/handle/10289/78/content.pdf"
  }*/

/*This is meant to be a large, positive constant that can still be efficiently
   loaded as an immediate (on platforms like ARM, for example).
  Even relatively modest values like 100 would work fine.*/
#define OD_EC_LOTS_OF_BITS (0x4000)

/*The return value of od_ec_dec_tell does not change across an od_ec_dec_refill
   call.*/
static void od_ec_dec_refill(od_ec_dec *dec) {
  int s;
  od_ec_window dif;
  int16_t cnt;
  const unsigned char *bptr;
  const unsigned char *end;
  dif = dec->dif;
  cnt = dec->cnt;
  bptr = dec->bptr;
  end = dec->end;
  add_to_file(0, dif, 0, cnt, 0, bptr, end, 2, 0);
  s = OD_EC_WINDOW_SIZE - 9 - (cnt + 15);
  for (; s >= 0 && bptr < end; s -= 8, bptr++) {
    /*Each time a byte is inserted into the window (dif), bptr advances and cnt
       is incremented by 8, so the total number of consumed bits (the return
       value of od_ec_dec_tell) does not change.*/
    assert(s <= OD_EC_WINDOW_SIZE - 8);
    dif ^= (od_ec_window)bptr[0] << s;
    cnt += 8;
    add_to_file(0, dif, 0, cnt, 0, NULL, NULL, 3, 0);     // Refill for

  }
  add_to_file(0, 0, 0, 0, 0, NULL, NULL, 3, 1);      // Final For

  if (bptr >= end) {
    /*We've reached the end of the buffer. It is perfectly valid for us to need
       to fill the window with additional bits past the end of the buffer (and
       this happens in normal operation). These bits should all just be taken
       as zero. But we cannot increment bptr past 'end' (this is undefined
       behavior), so we start to increment dec->tell_offs. We also don't want
       to keep testing bptr against 'end', so we set cnt to OD_EC_LOTS_OF_BITS
       and adjust dec->tell_offs so that the total number of unconsumed bits in
       the window (dec->cnt - dec->tell_offs) does not change. This effectively
       puts lots of zero bits into the window, and means we won't try to refill
       it from the buffer for a very long time (at which point we'll put lots
       of zero bits into the window again).*/
    dec->tell_offs += OD_EC_LOTS_OF_BITS - cnt;
    cnt = OD_EC_LOTS_OF_BITS;
  }
  add_to_file(0, dif, 0, cnt, 0, bptr, NULL, 2, 1);
  dec->dif = dif;
  dec->cnt = cnt;
  dec->bptr = bptr;
}

/*Takes updated dif and range values, renormalizes them so that
   32768 <= rng < 65536 (reading more bytes from the stream into dif if
   necessary), and stores them back in the decoder context.
  dif: The new value of dif.
  rng: The new value of the range.
  ret: The value to return.
  Return: ret.
          This allows the compiler to jump to this function via a tail-call.*/
static int od_ec_dec_normalize(od_ec_dec *dec, od_ec_window dif, unsigned rng,
                               int ret) {
  int d;
  assert(rng <= 65535U);
  /*The number of leading zeros in the 16-bit binary representation of rng.*/
  d = 16 - OD_ILOG_NZ(rng);
  /*d bits in dec->dif are consumed.*/
  add_to_file(0, 0, 0, dec->cnt, 0, NULL, NULL, 1, 3);
  dec->cnt -= d;
  /*This is equivalent to shifting in 1's instead of 0's.*/
  dec->dif = ((dif + 1) << d) - 1;
  dec->rng = rng << d;
  add_to_file(0, dec->dif, dec->rng, dec->cnt, 0, NULL, NULL, 1, 4);
  add_to_file(0, 0, 0, ret, 0, NULL, NULL, 1, 5);
  if (dec->cnt < 0){
       add_to_file(0, 0, 0, 0, 0, NULL, NULL, 1, 6);
       od_ec_dec_refill(dec);
 }
  return ret;
}

/*Initializes the decoder.
  buf: The input buffer to use.
  storage: The size in bytes of the input buffer.*/
void od_ec_dec_init(od_ec_dec *dec, const unsigned char *buf,
                    uint32_t storage) {
  dec->buf = buf;
  dec->tell_offs = 10 - (OD_EC_WINDOW_SIZE - 8);
  dec->end = buf + storage;
  dec->bptr = buf;
  dec->dif = ((od_ec_window)1 << (OD_EC_WINDOW_SIZE - 1)) - 1;
  dec->rng = 0x8000;
  dec->cnt = -15;
  FILE *arq;
  if(flag_first_dec == 1){
      flag_first_dec = 0;
      if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/icdf.csv", "w+")) == NULL){
           printf("\n\tERROR 10: Unable to create ICDF file.\n");
           exit(EXIT_FAILURE);
      }else
          fclose(arq);
     if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/dataset.csv", "w+")) == NULL){
          printf("\n\tERROR 11: Unable to create DATASET file.\n");
          exit(EXIT_FAILURE);
     }else
          fclose(arq);
     if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/refill.csv", "w+")) == NULL){
          printf("\n\tERROR 12: Unable to create REFILL file.\n");
          exit(EXIT_FAILURE);
     }else
          fclose(arq);
     if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/refill_for.csv", "w+")) == NULL){
          printf("\n\tERROR 13: Unable to create REFILL_FOR file.\n");
          exit(EXIT_FAILURE);
     }else
          fclose(arq);
 }
  od_ec_dec_refill(dec);
}

/*Decode a single binary value.
  f: The probability that the bit is one, scaled by 32768.
  Return: The value decoded (0 or 1).*/
int od_ec_decode_bool_q15(od_ec_dec *dec, unsigned f) {
  od_ec_window dif;
  od_ec_window vw;
  unsigned r;
  unsigned r_new;
  unsigned v;
  int ret;
  assert(0 < f);
  assert(f < 32768U);
  dif = dec->dif;
  r = dec->rng;
  add_to_file(0, dif, r, 2, f, NULL, NULL, 1, 1);
  assert(dif >> (OD_EC_WINDOW_SIZE - 16) < r);
  assert(32768U <= r);
  v = ((r >> 8) * (uint32_t)(f >> EC_PROB_SHIFT) >> (7 - EC_PROB_SHIFT));
  v += EC_MIN_PROB;
  vw = (od_ec_window)v << (OD_EC_WINDOW_SIZE - 16);
  ret = 1;
  r_new = v;
  if (dif >= vw) {
    r_new = r - v;
    dif -= vw;
    ret = 0;
  }
  add_to_file(0, dif, r_new, ret, 0, NULL, NULL, 1, 2);
  return od_ec_dec_normalize(dec, dif, r_new, ret);
}

/*Decodes a symbol given an inverse cumulative distribution function (CDF)
   table in Q15.
  icdf: CDF_PROB_TOP minus the CDF, such that symbol s falls in the range
         [s > 0 ? (CDF_PROB_TOP - icdf[s - 1]) : 0, CDF_PROB_TOP - icdf[s]).
        The values must be monotonically non-increasing, and icdf[nsyms - 1]
         must be 0.
  nsyms: The number of symbols in the alphabet.
         This should be at most 16.
  Return: The decoded symbol s.*/
int od_ec_decode_cdf_q15(od_ec_dec *dec, const uint16_t *icdf, int nsyms) {
  od_ec_window dif;
  unsigned r;
  unsigned c;
  unsigned u;
  unsigned v;
  int ret;
  (void)nsyms;
  dif = dec->dif;
  r = dec->rng;
  const int N = nsyms - 1;
  add_to_file(0, dif, r, nsyms, 0, NULL, NULL, 1, 0);

  assert(dif >> (OD_EC_WINDOW_SIZE - 16) < r);
  assert(icdf[nsyms - 1] == OD_ICDF(CDF_PROB_TOP));
  assert(32768U <= r);
  assert(7 - EC_PROB_SHIFT - CDF_SHIFT >= 0);
  c = (unsigned)(dif >> (OD_EC_WINDOW_SIZE - 16));
  v = r;
  ret = -1;
  do {
    u = v;
    v = ((r >> 8) * (uint32_t)(icdf[++ret] >> EC_PROB_SHIFT) >>
         (7 - EC_PROB_SHIFT - CDF_SHIFT));
     add_to_file(icdf[ret], 0, 0, 0, 0, NULL, NULL, 0, 0);      // Add the current icdf being used
    v += EC_MIN_PROB * (N - ret);
  } while (c < v);
  add_to_file(0, 0, 0, 0, 0, NULL, NULL, 0, 1);  // Add the label in a separate line
  assert(v < u);
  assert(u <= r);
  r = u - v;
  dif -= (od_ec_window)v << (OD_EC_WINDOW_SIZE - 16);
  add_to_file(0, dif, r, ret, 0, NULL, NULL, 1, 2);
  return od_ec_dec_normalize(dec, dif, r, ret);
}

void add_to_file(uint16_t icdf, uint32_t dif, unsigned r, int nsyms, unsigned f, const unsigned char *bptr, const unsigned char *end, int file_code, int print_code){
     FILE *arq;
     if(file_code == 0){
          if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/icdf.csv", "a")) != NULL){
               if(print_code == 0)
                    fprintf(arq, "%"PRIu16"\n", icdf);
               else if(print_code == 1)
                    fprintf(arq, "-------\n");
               fclose(arq);
          }else{
               printf("\n\tERROR 00: Problem to open ICDF file.\n\n");
               exit(EXIT_FAILURE);
          }
     }else if(file_code == 1){
          if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/dataset.csv", "a")) != NULL){
               /* q15_flag; dif; r; nsyms; f; r_norm; dif_norm; ret_norm; cnt_norm; dif_final; rng_final; cnt_final; ret_final;
               Inputs:
                    q15_flag, dif, r, nsyms, f
               Normalize inputs:
                    dif_norm, r_norm, ret_norm, cnt_norm
               Normalize outputs:
                    dif_final, rng_final, cnt_final, ret_final */
               if(print_code == 0)      // q15 inputs
                    fprintf(arq, "1;%"PRIu32";%"PRIu32";%d;0;", dif, r, nsyms);
               else if(print_code == 1)      // bool inputs
                    fprintf(arq, "0;%"PRIu32";%"PRIu32";%d;%"PRIu32";", dif, r, nsyms, f);
               else if(print_code == 2)      // Normalize inputs
                    fprintf(arq, "%"PRIu32";%"PRIu32";%d;", dif, r, nsyms);   // nsyms = ret here
               else if(print_code == 3)
                    fprintf(arq, "%d;", nsyms);   // nsyms = cnt_norm here
               else if(print_code == 4)      // Normalize outputs 1 (without ret)
                    fprintf(arq, "%"PRIu32";%"PRIu32";%d;", dif, r, nsyms); // nsyms = cnt_final here
               else if(print_code == 5)
                    fprintf(arq, "%d;\n", nsyms);  // nsyms = ret_final here
               else if(print_code == 6)
                    fprintf(arq, "Refill;-;-;-;-;-;-;-;-;-;-;-;-;\n");
               fclose(arq);
          }else{
               printf("\n\tERROR 01: Problem to open DATASET file.\n\n");
               exit(EXIT_FAILURE);
          }
     }else if(file_code == 2){
          if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/refill.csv", "a")) != NULL){
               // dif_in; cnt_in; bptr_in; end_in || dif_out; cnt_out; bptr_out
               if(print_code == 0) // Refill inputs
                    fprintf(arq, "%"PRIu32";%d;%s;%s;", dif, nsyms, bptr, end);          // nsyms = cnt_in
               if(print_code == 1) // Refill outputs
                    fprintf(arq, "%"PRIu32";%d;%s;\n", dif, nsyms, bptr);             // r = bptr_out; nsyms = cnt_out
               fclose(arq);
          }else{
               printf("\n\tERROR 02: Problem to open REFILL file.\n\n");
               exit(EXIT_FAILURE);
          }
     }else if(file_code == 3){
          if((arq = fopen("/home/tulio/Desktop/av1-new-test/arith_decoder/refill_for.csv", "a")) != NULL){
               // dif; cnt
               if(print_code == 0)
                    fprintf(arq, "%"PRIu32";%d;\n", dif, nsyms);
               if(print_code == 1)
                    fprintf(arq, "---------\n");
               fclose(arq);
          }else{
               printf("\n\tERROR 03: Problem to open REFILL_FOR file.\n\n");
               exit(EXIT_FAILURE);
          }
     }
}


/*Returns the number of bits "used" by the decoded symbols so far.
  This same number can be computed in either the encoder or the decoder, and is
   suitable for making coding decisions.
  Return: The number of bits.
          This will always be slightly larger than the exact value (e.g., all
           rounding error is in the positive direction).*/
int od_ec_dec_tell(const od_ec_dec *dec) {
  /*There is a window of bits stored in dec->dif. The difference
     (dec->bptr - dec->buf) tells us how many bytes have been read into this
     window. The difference (dec->cnt - dec->tell_offs) tells us how many of
     the bits in that window remain unconsumed.*/
  return (int)((dec->bptr - dec->buf) * 8 - dec->cnt + dec->tell_offs);
}

/*Returns the number of bits "used" by the decoded symbols so far.
  This same number can be computed in either the encoder or the decoder, and is
   suitable for making coding decisions.
  Return: The number of bits scaled by 2**OD_BITRES.
          This will always be slightly larger than the exact value (e.g., all
           rounding error is in the positive direction).*/
uint32_t od_ec_dec_tell_frac(const od_ec_dec *dec) {
  return od_ec_tell_frac(od_ec_dec_tell(dec), dec->rng);
}
