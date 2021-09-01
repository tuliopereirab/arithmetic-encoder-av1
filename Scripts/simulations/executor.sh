#!/bin/bash
LIST_ORIGINAL="lists/list_entropy_encoder.txt"
LIST_LP="lists/list_entropy_encoder-lp.txt"
LIST_IMPROVED="lists/list_entropy_encoder_improved.txt"

OUTPUT_DIR="outputs/"
OUTPUT_ORIGINAL="design.out"
OUTPUT_LP="design-lp.out"
OUTPUT_IMPROVED="design-improved.out"

line_space="${red}-------------------${nc}"

red='\033[0;31m'
boldRed='\033[1;31m'
boldGreen='\033[1;32m'
underGreen='\033[4;32m'
green='\033[0;32m'
nc='\033[0m'
cyan='\033[0;36m'
underCyan='\033[4;36m'


sim_entropy_encoder () {
     if [ -f "$OUTPUT_DIR/$OUTPUT_ORIGINAL" ]
     then
          rm $OUTPUT_DIR/$OUTPUT_ORIGINAL
     fi

     if [ -n $1  ]
     then
          echo -e "${red}No option chosen...${red}"
     fi
     echo -e "${cyan}Running Entropy Encoder: ${underCyan}Original version${nc}"
     iverilog -o $OUTPUT_DIR/$OUTPUT_ORIGINAL -c $LIST_ORIGINAL
     if [ -f "$OUTPUT_DIR/$OUTPUT_ORIGINAL" ]
     then
          # echo "Trying to simulate the original"
          # vvp $OUTPUT_DIR/$OUTPUT_ORIGINAL
          echo -e $line_space
          echo -e "${boldGreen}Successfully compiled: ${underGreen}Original version.${nc}"
          # echo -e "${green}Done.${nc}"
     else
          echo -e $line_space
          echo -e "${boldRed}Unable to compile. ${red}Check the problems on the log above.${nc}"
     fi
}

sim_entropy_encoder_lp () {
     if [ -f "$OUTPUT_DIR/$OUTPUT_LP" ]
     then
          rm $OUTPUT_DIR/$OUTPUT_LP
     fi
     echo -e "${cyan}Running Entropy Encoder: ${underCyan}Low-power version${nc}"
     iverilog -o $OUTPUT_DIR/$OUTPUT_LP -c $LIST_LP

     if [ -f "$OUTPUT_DIR/$OUTPUT_LP" ]
     then
          # echo "Trying to simulate the low-power"
          # vvp $OUTPUT_DIR/$OUTPUT_LP
          echo -e $line_space
          echo -e "${boldGreen}Successfully compiled: ${underGreen}Low-power version.${nc}"
          # echo -e "${green}Done.${nc}"
     else
          echo -e $line_space
          echo -e "${boldRed}Unable to compile. ${red}Check the problems on the log above.${nc}"
     fi
}

sim_entropy_encoder_improved () {
     if [ -f "$OUTPUT_DIR/$OUTPUT_IMPROVED" ]
     then
          rm $OUTPUT_DIR/$OUTPUT_IMPROVED
     fi

     echo -e "${cyan}Running Entropy Encoder: ${underCyan}Improved version${nc}"
     iverilog -o $OUTPUT_DIR/$OUTPUT_IMPROVED -c $LIST_IMPROVED
     if [ -f "$OUTPUT_DIR/$OUTPUT_IMPROVED" ]
     then
          # echo "Trying to simulate the original"
          # vvp $OUTPUT_DIR/$OUTPUT_ORIGINAL
          echo -e $line_space
          echo -e "${boldGreen}Successfully compiled: ${underGreen}Improved version.${nc}"
          # echo -e "${green}Done.${nc}"
     else
          echo -e $line_space
          echo -e "${boldRed}Unable to compile. ${red}Check the problems on the log above.${nc}"
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
elif [ $1 = "3" ]
then
     sim_entropy_encoder_improved
fi
