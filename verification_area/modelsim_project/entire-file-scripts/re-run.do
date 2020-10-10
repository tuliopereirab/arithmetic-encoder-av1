restart -f

# load memories
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/lut/lut_u.mem -format hex /tb_arith_encoder_entire_file/arith_encoder/state_pipeline_1/lut_u/rom
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/lut/lut_v.mem -format hex /tb_arith_encoder_entire_file/arith_encoder/state_pipeline_1/lut_v/rom


# do wave.do
# run 3000 ns             # 0- Miss America 150frames 176x144 (Only 100 rows)
run 40335750 ns         # 1- Miss America 150frames 176x144 (Entire Video)
# run 75000000 ns         # 2- Akiyo 300frames 176x144 (Entire Video)
