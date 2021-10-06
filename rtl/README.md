# Arithmetic Encoder - Versions
- This folder presents the different versions of the arithmetic encoder architecture.
- The explanation of each stage can be found in the [master README](https://github.com/tuliopereirab/arithmetic-encoder-av1).

## [High-throughput](entropy-encoder-original)

### Introduction

This is considered to be the _original_ version of the architecture. It comprises the entire functionality related to the arithmetic encoding process of the AV1 codec.

This architecture, as the other versions of it, relies on a 4-stage pipeline. The explanation of each stage can be found in the [master README](https://github.com/tuliopereirab/arithmetic-encoder-av1).

### Characteristics
- _Information generated in 2021-08-12_
- _ST 65 nm PDK_
- **Frequency**: 588 MHz
- **Area**: 11.7k gates count
- **Throughput rate**: 982 bits/sec
- **Average power consumption**: 7.801 mW

## [Low-power](entropy-encoder-lp)

### Introduction

- This version comprises the same logic as the [High-throughput](entropy-encoder-original) version, but uses low-power techniques (i.e., clock gating and operand isolation) to reduce the overall power consumption.
- As the reduction of the power consumption relies on the addition of clock gating and operand isolation cells into the architecture, the critical path was then enlarged. This surely affected the architecture's frequency.
- For an accurate power estimation with real-world inputs, simulations were executed and the power consumed was estimated by analysis the _.tcf_ files.

### Changes from [High-throughput](entropy-encoder-original)
#### Clock Gating
- It was added clock gating triggers nto all registers related to the _Boolean Operation_ (_bool_);
- Moreover, the registers related to the _bitstream generation_ (before and after Stage 4) also received the triggers.
- **Triggers**: formulas used as _enable_ and capable of deciding whether the register will useful or not for the current round;
#### Operand Isolation
- It was added triggers before each operation inside the _Bool_ block (see Stage 2 of [Figure](../Project/images/Original_Arc/hitecture-Stage_2.jpg));
- The _final_bits_ block also received operand isolation triggers as it is only executed upon the arrival of the last input for the current frame (in other words, just before the reset).

### Characteristics
- _Information generated in 2021-08-12_
- _ST 65 nm PDK_
- **Frequency**: 562 MHz
- **Area**: 11.2k gates count
- **Throughput rate**: 951 bits/sec
- **Average power consumption**: 6.166 mW

## Multi-Boolean (MB) Versions

### Introduction
- The Multi-Bool versions of the architecture uses an approach for the Boolean Operation (see [Stage_2](entropy-encoder-1-bool/stage_2.v) **s2_bool** module for details);
- As the new approach for the Boolean Operation is faster than the CDF block (which can't receive the new approach due to its always-changing probabilities), it is possible to allocate multiple Boolean blocks in sequence in Stages 2 and 3. The ones in Stage 2 are still faster than CDF, whereas the Stage 3 sequence gets slower than CDF_s2 when using more than 3 blocks.
- If considered only the bits encoded per cycle (bits/cycle), the graph below displays the improvements according to the number of Boolean blocks used.
![Graph](../Project/images/Graph_MB.png?raw=true)
- Although the Boolean blocks are positioned in sequence from each other, we call the Multi-Boolean approach as a **parallelization** because the 1/2/3/4 boolean symbols will be stored at the same time.

### Versions:
- _Following information generated in 2021-09-27_
- _Using ST 65nm PDF for synthesis_
- [1-bool](entropy-encoder-1-bool): only 1 Boolean block. Critical path located in Stage 2 (_Range updating process_).
  - **Frequency**: 581.395 MHz
  - **Area**: 11.7k
- [2-bool](entropy-encoder-2-bool): only 2 Boolean blocks. Critical path located in Stage 2 (_Range updating process_).
  - **Frequency**: 590.319 MHz
  - **Area**: 16.3k
- [3-bool](entropy-encoder-3-bool): only 3 Boolean blocks. Critical path located in Stage 2 (_Range updating process_).
  - **Frequency**: 558.971 MHz
  - **Area**: 20.3k
- [4-bool](entropy-encoder-4-bool): only 4 Boolean blocks. Frequency drop due to critical path moving to Stage 3 instead of Stage 2.
  - **Frequency**: 445.434 MHz
  - **Area**: 20.7k

### Low-Power Multi-Boolean Versions
- _Check the v1.3-MB-LP tag for all techniques and important information._
- _Following information generated in 2021-10-06_
- _Using ST 65nm PDF for synthesis_
- [1-bool-lp](entropy-encoder-1-bool-lp): only 1 Boolean block using Low-Power techniques. Critical path in Stage 2 (_Range updating process_).
  - **Frequency**: 584.795 MHz
  - **Area**: 11.5k
- [2-bool-lp](entropy-encoder-2-bool-lp): only 2 Boolean blocks using Low-Power techniques. Critical path in Stage 2 (_Range updating process_).
  - **Frequency**: 584.112 MHz
  - **Area**: 16.8k
- [3-bool-lp](entropy-encoder-3-bool-lp): only 3 Boolean blocks using Low-Power techniques. Critical path in Stage 2 (_Range updating process_).
  - **Frequency**: 519.211 MHz
  - **Area**: 20.8k


## [Other-blocks](other-blocks)

### Introduction
- The herein presented blocks were created during the development process as part of the experiments made.
- If applicable, one may find inside the source files the reference to the paper that allowed the block's creation.  

### Components
#### [Ripple Carry Adder](other-blocks/ripple_carry_adder)
- Ripple carry adder created to be a basic module for the [Vedic Multiplier](other-blocks/vedic-multiplier).

#### [Vedic Multiplier](other-blocks/vedic-multiplier)
- The Vedic multiplier was implemented as a trial for increasing the overall frequency of the architecture by accelerating the multiplication process (critical path).
- However, as synthesis tools already comprise the state-of-art in hardware multipliers within their cells, this block ended up increasing the frequency and, therefore, was not used.
