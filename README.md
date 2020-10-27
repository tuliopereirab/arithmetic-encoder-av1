# Arithmetic Encoder - AV1

## Description
    - This project's goal is to design, verify, and synthesize to ASIC a high-frequency low-power pipelined arithmetic encoder for the AV1 coding standard.
    - Currently, this project is comprised of a 3-stage pipeline and generates the Low, Range, and pre-bitstream according to the AV1 reference algorithm.
    - As measured in 2020-10-26, this project's frequency, when synthesizing to ASIC, is around **567,85 MHz**.

## What is still missing?
    1. **Carry propagation for the bitstream**: as the AV1's implementation for the carry propagation isn't good enough for a hardware implementation, other methods to design the same functionality are under research.
    2. **Improve frequency and reduce area**: as higher as an architecture's frequency is, there are always ways to make it even higher without increasing the area.

## About the project
### 3-stage pipeline
    - **Stage 1**: Pre-calculations for the Low and Range generation.
    - **Stage 2**: The main output is the range ready and normalized, among a few other essential values for the Low generation.
    - **Stage 3**: Defines the low value, normalizes it, and generates the pre-bitstream.
### Verification
    - This project's testbenches were created in SystemVerilog, and all of them can find any problem with the architecture.
    - All files responsible for the verification can be found in the [verification_area](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/verification_area) folder.

#### Simulation data    
    - The simulation data files are generated directly from AV1's algorithm, modified to create output files with important data.

##### How to generate?
    1. Download the modified file of the AV1's entropy encoder, [entenc.c]();
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
    - **General testbench**: testbench used to validate the overall architecture according to the low and range values. The file is called [tb_arith_encoder.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/complete-tb/tb_arith_encoder.sv).
    - **Pre-bitstream testbench**: This file also verifies the low and range outputs and the bitstream and a few other values used by the function *od_ec_enc_done* on the AV1's original code. The file is called [tb_bitstream](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/pipeline_sv_csv/tb_bitstream.sv).
    - **Component testbenches**: The LZC (Leading Zero Counter) has its own testbench called [tb_lzc.sv](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/verification_area/components/tb_lzc.sv).
