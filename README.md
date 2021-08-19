![Architecture](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/Project/images/Original_Arc.png?raw=true)

# Arithmetic Encoder - AV1

## Description
- **The Goal**: To accelerate the AV1 Arithmetic Encoder process by creating a pipelined architecture and synthesize it to ASIC.
- **Current State**: the architecture is completed and, after careful validation, no problems were found.
- **Versions**: there are two versions of the architecture within this repository: [High-throughput](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder) and [Low-power](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder-lp).
- **Features**: The [High-throughput](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder) version has the following characteristics: **588 MHz**, **11.7k gates count** and **982 bits/sec** with ST 65 nm PDK. Meanwhile, [Low-power](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder-lp) has the following: **562 MHz**, **11.2k gates count** and **951 bits/sec** with ST 65 nm PDK. The [Low-power](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder-lp) version saves around **21%** of power, according to analysis made with real-world datasets.

## What is still missing?
1. **Improve frequency and reduce area**: as higher as an architecture's frequency is, there are always ways to make it even higher without increasing the area.
2. **Possible solution**: One of the possible solutions for increasing the throughput rate without increasing the frequency would be to remove the multiplication from the _Boolean Operation_ and create on the testbenches the possibility to execute two or three input lines (from the _.csv_ files) during the same clock cycle. This would only be possible on the _Boolean Operation_ and would required a burst of booleans.

## Project overview
### 4-stage pipeline
- **Stage 1**: Pre-calculations for the _Low_ and _Range_ generation.
- **Stage 2**: The main output is the _Range_ ready and normalized, among a few other essential values for the _Low_ generation
- **Stage 3**: Defines the low value, normalizes it, and generates the pre-bitstream.
- **Stage 4**: Carry propagation block. Transforms the 9-bit pre-bitstream generated in Stage 3 into an 8-bit final bitstream.

### Verification
- This project's testbenches were created in SystemVerilog, and all of them can find any problem with the architecture.
- All files responsible for the verification can be found in the [verification_area](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/verification_area) folder.

#### Simulation data    
- The simulation data files are generated directly from AV1's algorithm, modified to create output files with important data.

##### How to generate?
1. Download the modified file of the AV1's entropy encoder, <code>[entenc.c](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/AV1-reference-info/entenc.c)</code>;
2. Download/clone the [AV1's reference code](https://aomedia.googlesource.com/aom/);
3. Copy and overwrite the file <code>entenc.c</code> modified into the folder <code>aom/aom_dsp</code>;
4. Run any encoding process according to the procedure as specified in the AV1's website;
5. After the encoding process is completed, access the folder <code>arith_analysis</code> created;
6. The normal data sequence for the testbench is a file called <code>main_data</code>.

##### Other files generated
- **Input**: this file contains only the input values for the architecture. In the case of a testbench, this file cannot be used because it does not contain the algorithm's outputs.

#### Testbenches
- **Entropy encoder testbench**: This is the main testbench for the entire archicture. It validades the bitstreams generated and after the carry propagation process. The file is called [entropy_encoder_tb.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/entropy_encoder_tb.sv)
- **Arithmetic encoder testbench**: This testbench is used to validade only the stages 1, 2 and 3 of the pipeline together. The file is called [tb_arith_encoder.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/tb_arith_encoder.sv).
- **Pre-bitstream testbench**: This file also verifies the low and range outputs and the bitstream and a few other values used by the function <code>od_ec_enc_done</code> on the AV1's original code. The file is called [tb_bitstream](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/other_tb/pipeline_sv_csv/tb_bitstream.sv).
- **Component testbenches**: The LZC (Leading Zero Counter) has its own testbench called [tb_lzc.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/components/tb_lzc.sv).
- **Carry propagation testbench**: The Carry Propagation testbench verifies only the 4th stage of pipeline with random input data and it is called [tb_carry_propagation.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/components/tb_carry_propagation.sv).

## Architecture in-depth explanation
### Stage 1
- In order to increase frequency, this block executes pre-calculations that are required for both range and low definitions on stages 2 and 3, respectively.
- It also accesses the two look-up tables, which are generated by the script [lut-generator.py](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/Scripts/lut-generator.py).

### Stage 2
- This stage basically uses the results coming from the 1st stage and finds the range initial value.
- Furthermore, this stage normalizes the range using the [LZC.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/rtl/entropy-encoder/LZC.v) block.

![Stage 2](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/Project/images/Architecture-Stage_2.jpg?raw=true)

### Stage 3
- This stage receives values from the stages 1 and 2.
- This stage's main goal is to find the low value and normalize it.
- Moreover, this stage is responsible for generating up to two 9-bit bitstreams per clock cycle.

### Stage 4
- The output bitstreams are 8-bit arrays.
- As Stage 3 generates 9-bit bitstreams, the 4th stage propagates the <code>b[9]</code> to previously generated bitstreams.
- This block is divided in 2 sub-blocks: [carry_propagation.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/rtl/entropy-encoder/carry_propagation.v) and [final_bits.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/rtl/entropy-encoder/final_bits.v).
- The following subsections explain exactly the blocks' behaviors.

#### Carry Propagation block
- Always when <code>(B_in > 255)</code> -> <code>B_out = B_prev[7:0] + B_in[15:8]</code>
- Therefore, this block will save the last generated 8-bit bistream (B_prev) and propagate the carry of the following bitstreams (B_in).
- <code>B_in = B_prev[7:0] + B_in[15:8]; B_prev = B_in[7:0]</code>
- This block is also able to count the number of 255s received in sequence and release n 255s at the same time using <code>OUT_BIT_2</code> (255 or 0) and <code>OUT_BIT_3</code> (number saved in the counter).
- This block is able to release up to five 8-bit arrays when necessary.

#### 255 Exception
- Everytime when 255 is received followed by a <code>number > 255</code>, it is necessary to propagate the carry beyond i-1 (<code>i-2, i-3, i-x</code>).
- To solve this problem, the _bitstream received just before the first 255_ is kept stored within _Bprev_, while a _255_counter_ counts the number of 255 received in sequence.
- Once a bitstream != 255 arrives, the architecture releases as follows: <code>Bout1_ = _Bprev</code>; <code>Bout2 = 255 or 0</code>; <code>Bout3 = _255_counter</code>; <code>Bprev = Bin1 or Bin2</code> (<code>Bin1</code> is release as <code>Bout4</code> if <code>flagIn == 2</code>).

#### Last Bitstreams generation
- When the frame execution is over, it is necessary to release bitstreams according to the _low_ and _cnt_ values.
- This block basically generates up to two bitstreams once the _final_flag_ (sent by the testbench) reaches the Stage 4.
- The bitstreams generated here are also 9-bit arrays and require to pass through the carry propagation process.

## Analysis
### Critical Path
- On 2020-12-19, the frequency reached for a 65nm library synthesis was 559 MHz.
- The architecture's current critical path is the _range_ generation and normalization, which passes through a multiplication and the LZC sub-block.

### Ways to improve
1. Find a way to multiply faster (already did some unsuccessful trials with _Vedic multiplication_ method) -- **(_not possible_)**;
2. Find a way to split the range generation equation and execute some parts in Stage -- **(_not possible_)**;
3. Use approximate computing to avoid the multiplication of the range;
4. Find a multiplier-free solution for arithmetic encoding and analyze how it behaves when added to the AV1 reference software (_Window Sliding might be a great option_).

#### Why is it not possible? (_Indexes above_)
1. When synthesizing the ASIC, the synthesizer will automatically find the best combination of cells possible for the multiplication (usually it's a custom cell specifically made for multiplication). It is just not feasible to beat something designed for multiplications with Verilog code and different multiplication methodologies. The cell itself has state-of-art multiplication methodologies.

2. Splitting the _Range_ or _Low_ generation process in two or more stages would create bubble in the pipeline. It just doesn't make sense to, for example, split _Stage 2_ and send inputs with a 2-cycle gap. Sure the frequency will get better, but the throughput rate will still be the same (or perhaps get lower).

**More information about the architecture in [Project](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/Project) folder.**

## Versions
1. _entropy-encoder_ is the original architecture comprised by stages 1, 2, 3 and 4, as explained above.
2. _entropy-encoder-lp_ is a low-power version of the architecture. This version uses Operand Isolation and Clock Gating to reduce the power consumption of the architecture. This version aims to prevent useless values from _Boolean Operation_ from being generated and stored.

## How to run the main testbench?
1. Generate the simulation data and generate the LUT data ([lut-generator.py](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/Scripts/lut-generator.py));
2. Import the testbench file [entropy_encoder_tb.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/entropy_encoder_tb.sv) and change the simulation file's path;
3. Import all _.v_ files;
4. Compile all files in a simulation software (e.g., Modelsim);
5. Use the scripts in folder [verification_area/modelsim_project/scripts/main_entropy_encoder/](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/verification_area/Modelsim/modelsim_scripts/scripts/main_entropy_encoder);
6. With the waveform scripts, some waveforms will be imported to the project (**only tested on Modelsim**);
7. With the [re-run.do](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/Modelsim/modelsim_scripts/scripts/main_entropy_encoder/re-run.do) file, the LUT memories will be filled with generated data and the simulation will start.
