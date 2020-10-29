#include <stdio.h>

#include "arith_encoder.c"
#include "ob_bitstream.c"


// ob_bitstream
void write_line_break();
void ob_reset();
void write_bits(int bit);
void put_bit(int bit);
void renormalization_ob(uint32_t low, uint16_t range);


// arith_encoder
uint32_t get_Low();
uint16_t get_Range();
int16_t get_cnt();
void od_ec_encode_q15(unsigned fl, unsigned fh, int s, int nsyms);;
void od_ec_encode_bool_q15(int val, unsigned f);
void od_ec_enc_normalize(uint32_t low_norm, unsigned rng);
void add_bitstream_file(uint16_t bitstream);
void carry_propagation();
