# Arithmetic Encoder - Versions
- This folder presents the different versions of the arithmetic encoder architecture.
- The explanation of each stage can be found in the [master README](https://github.com/tuliopereirab/arithmetic-encoder-av1).

## [High-throughput](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder-original)

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

## [Low-power](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder-lp)

### Introduction

- This version comprises the same logic as the [High-throughput](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder-original) version, but uses low-power techniques (i.e., clock gating and operand isolation) to reduce the overall power consumption.
- As the reduction of the power consumption relies on the addition of clock gating and operand isolation cells into the architecture, the critical path was then enlarged. This surely affected the architecture's frequency.
- For an accurate power estimation with real-world inputs, simulations were executed and the power consumed was estimated by analysis the _.tcf_ files.

### Changes from [High-throughput](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/entropy-encoder-original)
#### Clock Gating
- It was added clock gating triggers nto all registers related to the _Boolean Operation_ (_bool_);
- Moreover, the registers related to the _bitstream generation_ (before and after Stage 4) also received the triggers.
- **Triggers**: formulas used as _enable_ and capable of deciding whether the register will useful or not for the current round;
#### Operand Isolation
- It was added triggers before each operation inside the _Bool_ block (see Stage 2 of [Figure](https://github.com/tuliopereirab/arithmetic-encoder-av1/blob/master/Project/images/Architecture-Stage_2.jpg));
- The _final_bits_ block also received operand isolation triggers as it is only executed upon the arrival of the last input for the current frame (in other words, just before the reset).

### Characteristics
- _Information generated in 2021-08-12_
- _ST 65 nm PDK_
- **Frequency**: 562 MHz
- **Area**: 11.2k gates count
- **Throughput rate**: 951 bits/sec
- **Average power consumption**: 6.166 mW

## [Other-blocks](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/other-blocks)

### Introduction
- The herein presented blocks were created during the development process as part of the experiments made.
- If applicable, one may find inside the source files the reference to the paper that allowed the block's creation.  

### Components
#### [Ripple Carry Adder](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/other-blocks/ripple_carry_adder)
- Ripple carry adder created to be a basic module for the [Vedic Multiplier](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/other-blocks/vedic-multiplier).

#### [Vedic Multiplier](https://github.com/tuliopereirab/arithmetic-encoder-av1/tree/master/rtl/other-blocks/vedic-multiplier)
- The Vedic multiplier was implemented as a trial for increasing the overall frequency of the architecture by accelerating the multiplication process (critical path).
- However, as synthesis tools already comprise the state-of-art in hardware multipliers within their cells, this block ended up increasing the frequency and, therefore, was not used.
