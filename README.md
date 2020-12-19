# Arithmetic Encoder - AV1

## Description
- This project's goal is to design, verify, and synthesize to ASIC a high-frequency low-power pipelined arithmetic encoder for the AV1 coding standard.
- Currently, this project is comprised of a 3-stage pipeline and generates the Low, Range, and pre-bitstream according to the AV1 reference algorithm.
- As measured in 2020-10-26, this project's frequency, when synthesizing to ASIC, is around **567,85 MHz**.

## What is still missing?
1. **Fix some problems with the carry propagation block ([stage_4.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/stage_4.v))**: the stage for is a very detailed and complex block that is still missing one specific exception (receiving _B != 255_ followed by _B == 255_).
2. **Improve frequency and reduce area**: as higher as an architecture's frequency is, there are always ways to make it even higher without increasing the area.

## Project overview
### 4-stage pipeline
- **Stage 1**: Pre-calculations for the Low and Range generation.
- **Stage 2**: The main output is the range ready and normalized, among a few other essential values for the Low generation.
- **Stage 3**: Defines the low value, normalizes it, and generates the pre-bitstream.
- **Stage 4**: Carry propagation block and generation of last 9-bit bitstreams.
### Verification
- This project's testbenches were created in SystemVerilog, and all of them can find any problem with the architecture.
- All files responsible for the verification can be found in the [verification_area](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/verification_area) folder.

#### Simulation data    
- The simulation data files are generated directly from AV1's algorithm, modified to create output files with important data.

##### How to generate?
1. Download the modified file of the AV1's entropy encoder, [entenc.c](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/AV1-reference-info/entenc.c);
2. Download/clone the [AV1's reference code](https://aomedia.googlesource.com/aom/);
3. Copy and overwrite the file _entenc.c_ modified into the folder _aom/aom_dsp_;
4. Run any encoding process according to the procedure as specified in the AV1's website;
5. After the encoding process is completed, access the folder *arith_analysis* created;
6. The normal data sequence for the testbench is a file called *main_data*.

##### Other files generated
- **Input**: this file contains only the input values for the architecture. In the case of a testbench, this file cannot be used because it does not contain the algorithm's outputs.
- **Bitstream pre-carry**:
- **Final bitstream**:
#### Testbenches
- **Entropy encoder testbench**: This is the main testbench for the entire archicture. It validades the bitstreams generated and after the carry propagation process. The file is called [entropy_encoder_tb.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/entropy_encoder_tb.sv)
- **Arithmetic encoder testbench**: This testbench is used to validade only the stages 1, 2 and 3 of the pipeline together. The file is called [tb_arith_encoder.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/tb_arith_encoder.sv).
- **Pre-bitstream testbench**: This file also verifies the low and range outputs and the bitstream and a few other values used by the function *od_ec_enc_done* on the AV1's original code. The file is called [tb_bitstream](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/other_tb/pipeline_sv_csv/tb_bitstream.sv).
- **Component testbenches**: The LZC (Leading Zero Counter) has its own testbench called [tb_lzc.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/components/tb_lzc.sv).
- **Carry propagation testbench**: The Carry Propagation testbench verifies only the 4th stage of pipeline with random input data and it is called [tb_carry_propagation.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/components/tb_carry_propagation.sv).

## Architecture in-depth explanation
### Stage 1
- In order to increase frequency, this block executes pre-calculations that are required for both range and low definitions on stages 2 and 3, respectively.
- It also accesses the two look-up tables, which are generated by the script [lut-generator.py](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/Scripts/lut-generator.py).

### Stage 2
- This stage basically uses the results coming from the 1st stage and finds the range initial value.
- Furthermore, this stage normalizes the range using the [LZC.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/LZC.v) block.

### Stage 3
- This stage receives values from the stages 1 and 2.
- This stage's main goal is to find the low value and normalize it.
- Moreover, this stage is responsible for generating up to two 9-bit bitstreams per clock cycle.

### Stage 4
- The output bitstreams are 8-bit arrays.
- As Stage 3 generates 9-bit bitstreams, the 4th stage propagates the _b[9]_ to previously generated bitstreams.
- This block is divided in 3 sub-blocks: [carry_propagation.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/carry_propagation.v), [auxiliar_carry_propagation.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/auxiliar_carry_propagation.v) and [final_bits.v](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/final_bits.v).
- The following subsections explain exactly the blocks' behaviors.

#### Main Carry Propagation
- This block makes the 9th bit propagation to previosly generated bitstreams.
- This block is able to receive up to 9-bit bitstreams per cycle.
- The main limitation of this block is that it is only able to propagate until _i-3_ (generating 2 bitstreams), or _i-2_ (generating 1 bitstream), where _i_ represents the last bitstream generated.
- This block generates outputs according to demand and according to what is stored in the internal registers.
- The idea is to keep the just generated bitstream and release the one(s) already in stand-by.
##### Internal Architecture
- 2 main registers: stand-by and previous
- **Previous**: saves the previous bitstream generated.
- **Stand-by**: this register is used to treat the 255 exception (explained below). Briefly, when receiving 255 as input, saves here the previos bitstreams.
- Below are the equations for normal operation for 1 input:
[Equation 1](https://render.githubusercontent.com/render/math?math=Out_1=B_{PREV}[7:0]+B_{IN_1}[8])
[Equation 2](https://render.githubusercontent.com/render/math?math=B_{PREV}=B_{IN_1}[7:0])
- Below are the equations for normal operation for 2 inputs:
[Equation 3](https://render.githubusercontent.com/render/math?math=Out_1=B_{PREV}[7:0]+B_{IN_1}[8])
[Equation 4](https://render.githubusercontent.com/render/math?math=Out_2=B_{IN_1}[7:0]+B_{IN_2}[8])
[Equation 5](https://render.githubusercontent.com/render/math?math=B_{PREV}=B_{IN_2}[7:0])
- Below are the equations when receiving 255:
[Equation 6](https://render.githubusercontent.com/render/math?math=B_{STAND-BY}=B_{PREV}[7:0])
[Equation 7](https://render.githubusercontent.com/render/math?math=B_{PREV}=B_{IN_1}[7:0])
[Equation 8](https://render.githubusercontent.com/render/math?math=Out_1=0)
- When using the _stand-by_ register, do the same operation that are used during normal operations. The only different is that _stand-by_ comes before _previous_.

##### The 255 exception
- The architecture under normal conditions only needs to propagate the carry to the bitstream generated right before the current one (_i-1_).
- However, when receiving 255 followed by _B[8] = 1_ bitstream, it is necessary to propagate the carry to _i-2_.
- The Main carry propagation architecture has the limit of handling only one 255 at the time.
- Auxiliary carry propagation is able to handle the _2^x_ 255s, where _x_ is the _255_counter_'s width.  

#### Auxiliary Carry Propagation
- When more than one 255 is received in a row, this block is activated.
- This block takes control of the output pins and start couting the number of 255s received.
- This block also saves the bitstream received just before the first 255 into a buffer.
- When a number different than 255 (_B != 255_) is received, this block starts to release all values saved so far.
- This block is able to release up to four 8-bit bitstreams per cycles (all of them with the carry already propagated).
- This block is also able to save new bitstreams if not possible to release them at the same clock cycle.

#### Last Bitstreams generation
- When the frame execution is over, it is necessary to release bitstreams according to the _low_ and _cnt_ values.
- This block basically generates up to two bitstreams once the _final_flag_ (sent by the testbench) reaches the Stage 4.
- The bitstreams generated here are also 9-bit arrays and require to pass through the carry propagation process.

## Analysis
### Critical Path
- On 2020-12-19, the frequency reached for a 65nm library synthesis was 559 MHz.
- The architecture's current critical path is the _range_ generation and normalization, which passes through a multiplication and the LZC sub-block.

### Ways to improve
1. Find a way to multiply faster (already did some unsuccessful trials with Vedic multiplication method);
2. Find a way to split the range generation equation and execute some parts in Stage 1;
3. Use approximate computing to avoid the multiplication of the range.

**More information about the architecture in [Project](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/Project) folder.**


## How to run the main testbench?
1. Generate the simulation data and generate the LUT data ([lut-generator.py](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/Scripts/lut-generator.py));
2. Import the testbench file [entropy_encoder_tb.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/testbenches/entropy_encoder_tb.sv) and change the simulation file's path;
3. Import all _.v_ files;
4. Compile all files in a simulation software (e.g., Modelsim);
5. Use the scripts in folder [verification_area/modelsim_project/scripts/main_entropy_encoder/](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/verification_area/modelsim_project/scripts/main_entropy_encoder);
6. With the waveform scripts, some waveforms will be imported to the project (**only tested on Modelsim**);
7. With the [re-run.do](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/modelsim_project/scripts/main_entropy_encoder/re-run.do) file, the LUT memories will be filled with generated data and the simulation will start.
