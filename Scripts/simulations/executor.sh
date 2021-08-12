#!/bin/bash
LIST_ORIGINAL="lists/list_entropy_encoder.txt"
LIST_LP="lists/list_entropy_encoder-lp.txt"

OUTPUT_DIR="outputs/"
OUTPUT_ORIGINAL="design.out"
OUTPUT_LP="design-lp.out"


sim_entropy_encoder () {
     if [ -f "$OUTPUT_DIR/$OUTPUT_ORIGINAL" ]
     then
          rm $OUTPUT_DIR/$OUTPUT_ORIGINAL
     fi

     if [ -n $1  ]
     then
          echo "No option chosen..."
     fi
     echo "Running Entropy Encoder: Original version"
     iverilog -o $OUTPUT_DIR/$OUTPUT_ORIGINAL -c $LIST_ORIGINAL
     if [ -f "$OUTPUT_DIR/$OUTPUT_ORIGINAL" ]
     then
          # echo "Trying to simulate the original"
          # vvp $OUTPUT_DIR/$OUTPUT_ORIGINAL
          echo "--------------"
          echo "Currently not compiling the testbench in SystemVerilog."
          echo "Done"
     else
          echo "-------------------"
          echo "Unable to generate the output file for some reason."
     fi
}

sim_entropy_encoder_lp () {
     if [ -f "$OUTPUT_DIR/$OUTPUT_LP" ]
     then
          rm $OUTPUT_DIR/$OUTPUT_LP
     fi
     echo "Running Entropy Encoder: Low-power version"
     iverilog -o $OUTPUT_DIR/$OUTPUT_LP -c $LIST_LP

     if [ -f "$OUTPUT_DIR/$OUTPUT_LP" ]
     then
          # echo "Trying to simulate the low-power"
          # vvp $OUTPUT_DIR/$OUTPUT_LP
          echo "--------------"
          echo "Currently not compiling the testbench in SystemVerilog."
          echo "Done"
     else
          echo "-------------------"
          echo "Unable to generate the output file for some reason."
     fi
}

if [ ! -d "$OUTPUT_DIR/" ]
then
     mkdir outputs
fi

if [ -z $1 ]
then
     sim_entropy_encoder 1
elif [ $1 = "1" ]
then
     sim_entropy_encoder
elif [ $1 = "2" ]
then
     sim_entropy_encoder_lp
fi
