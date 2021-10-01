# Scripts

## Introduction
- Here are all scripts used to analyze, generate data and generate look-up tables (LUTs).
- Each of the scripts will be explained here.
- A **grade of importance** (0-10) is added to each script.

## [get_frame.py](get_frame.py)
- **Importance:** 7
- **Goal:** Randomly select a frame from datasets (originally datasets have 120 frames) and save it into a new file.
### Methodology
1. Chooses a random number between 1 and 120 (120 is originally the number of frames in a dataset, but it might variate according to the dataset);
2. Start reading the dataset file, line by line, and counts the resets. The resets are defined as **(_previous_output_range != current_input_range_)**.
3. Once it reaches the chosen frame (_num_resets == num_chosen_), then the script starts storing each line in a different _.csv_ file.
4. Once it reaches the next reset, then the script stops and the _.csv_ file created is ready to be used in any simulation.
- **Note 1**: the maximum number of frames, which is currently set to 120, might variate according to the datasets used. Hence, this number must be updated before any execution.
- **Note 2**: some frames might have too few inputs. This might reduce the verification coverage or impacts the power analysis.  


## [lut-generator.py](lut-generator.py)
- **Importance:** 10
- **Goal:** This script is able to generate the look-up table (LUT) data. It is capable of generating data in _.mem_, _.mif_ or _Verilog_ files (the latter represents an arrangements of multiplexers that behaves as a LUT).
### Methodology
- Look-up tables are defined by 2 main equations:
1. _LUT_u = 4 * (N - (s - 1))_
2. _LUT_v = 4 * (N - (s + 0))_
- The variables **N** and **s** are used as address for the look-up table, which means the LUT is **addressed by an 8-bit array**.
- By running a _for_ loop inside another _for_ loop it is possible to ensure the right addresses for the data.

## [~simulation-file-generator.py~](simulation-file-generator.py)
- **Importance:** 1
- **Goal:** Used, at the beginning of the project, to convert decimal input datasets to binary ones. _It is currently out of use due to the SystemVerilog possibility to accept decimal inputs._
### Methodology
- **This script shouldn't be used but it won't be removed from the repository.**


## [statistics.py](statistics.py)
- **Importance:** 7
- **Goal:** To calculate the percentage of _Boolean Operations_ among all inputs. Used mainly to achieve a better low-power version.
### Methodology
- This script goes through the entire dataset file, reading line-by-line and counting both the number of _Boolean Operations_ found, and the total inputs (number of lines within the file).
- After that, the script prints on screen the total of inputs, the total of _Boolean Operations_ found and the boolean percentage.


## [throughput_analysis.py](throughput_analysis.py)
- **Importance:** 8
- **Goal:** To analyze the throughput rate of the architecture according to the input datasets.
### Methodology
- The throughput analysis basically checks how many bits is encoded per clock cycle on the architecture (round of execution).
- This value is calculated based on an incoming alphabet, which is defined by the input value _nsyms_.
- The counting table is as follows:
     - _nsyms_ = 2 ------------------------------------- **1 bit**
     - _nsyms_ = 3, 4 ---------------------------------- **2 bit**
     - _nsyms_ = 5, 6, 7, 8 --------------------------- **1 bit**
     - _nsyms_ = 9, 10, 11, 12, 13, 14, 15, 16 --- **1 bit**
- After each round of execution (each line), the corresponding number of bits is added to the total number of bits already encoded.
- Once the script reaches the EOF (_end-of-file_), it divides **bits_encoded/total_inputs**.
- The final result is: **The average number of bits encoded per cycle**
- **Note:** If eventually it is found a way to increase the number of symbols encoded per clock cycle in the architecture, then this script should be modified as well. This script assumes that only one symbol will be encoded per clock cycle.

## [simulations](simulations) folder
- This folder comprises scripts ([executor.sh](simulations/executor.sh) and [Makefile](simulations/Makefile)) that allows an easier compilation with _Icarus Verilog_ (iverilog).
- _Icarus Verilog_ is a tool that runs a very light and efficient compiler. It surely provides a simulation property as well, but it doesn't support _SystemVerilog_ testbenches, which was the language chosen for the project. Hence, _iverilog_ is only used for raw compilation before sending the files to a Modelsim environment.
- To simplify the use of _iverilog_, a folder with the [lists](simulations/lists) of files was created. The lists are for the [entropy-encoder](simulations/lists/list_entropy_encoder.txt) and for the [entropy-encoder-lp](simulations/lists/list_entropy_encoder-lp.txt).
- **Note**: before using these scripts, please make sure the files **exist** and their are correctly pointed by the lists.
