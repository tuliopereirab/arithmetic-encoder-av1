# AV1 Reference Software

## Introduction

This directory contains all the necessary files to generate valid datasets from the AV1 Reference software that match with the [testbenches](../testbenches) created.

## Important Files

### <code>[encode.sh](encode.sh)</code>
- Script responsible for generating datasets according to the following configurations:
1. <code>CQ=20: --good and --allintra</code>
2. <code>CQ=32: --good and --allintra</code>
3. <code>CQ=43: --good and --allintra</code>
4. <code>CQ=55: --good and --allintra</code>

- To work, the user must update the following variables:
1. <code>videos_path</code> at line 14: set the path that takes to a directory with <code>.y4m</code> videos;
2. <code>video_coded_dest</code> at line 15: set the path where the encoder should dump the <code>.webm</code> coded video;
3. <code>dataset_origin</code> at line 16: set the **same** path set within <code>[entenc.c](entenc.c)</code>. This path is where the encoder (with the modified <code>[entenc.c](entenc.c)</code> file) will dump the datasets.
4. <code>dataset_dest</code> at line 17: set the destination where the use wants the dataset to be stored after each encoding.


### <code>[entenc.c](entenc.c)</code>
- This is the modified <code>entenc.c</code>, which should overwrite the file with the same name located in the <code>aom/aom_dsp/</code> directory of the AV1 reference software.
- Moreover, before using this file, the user has to modified the path for the datasets generation and create the respective directory (the software doesn't create the directory and will stop if it's unable to create the file within the target directory).

### <code>[entdec.c](entdec.c)</code>
- This works exactly as the one above, with the difference of being used for the decoder instead of encoder.
- This file shouldn't be used when only running the encoder part (if you use the <code>[encode.sh](encode.sh)</code> script, don't use this file).

## How to use

1. Create a directory and clone the [AV1 Reference Software](https://aomedia.googlesource.com/aom/);
2. Before executing anything, go ahead and switch the original <code>aom/aom_dsp/entenc.c</code> with the modified one listed above;
3. Go inside the modified <code>entenc.c</code> and change the path for the files <code>complete_final_bitstream.csv</code> and <code>main_data.csv</code> (you can use <code>Ctrl+F</code> in any text editor and look for the files);
4. Copy the <code>[encode.sh](encode.sh)</code> file to the created directory on Item 1 (make you it is outside of the cloned AV1 <code>aom/</code> folder);
5. Open <code>[encode.sh](encode.sh)</code> and edit the variables listed above (lines 14 through 17);
6. Run the <code>[encode.sh](encode.sh)</code> file with <code>sudo ./encode.sh</code> (use <code>chmod 774 encode.sh</code> if necessary).
