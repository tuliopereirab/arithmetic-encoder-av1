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

#define FLAG_NEW_LOGIC 2
#define OD_EC_WINDOW_SIZE ((int)sizeof(uint32_t) * CHAR_BIT)
// ----------------------
// Variables for the old logic

// ----------------------
// ----------------------
// ----------------------

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
     printf("=========================\n");
     setup();
     status = run_simulation();
     timing_analyzer();
     return 0;
}
