restart -f

# load memories
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/Scripts/lut_u.mem -format hex /tb_artih_encoder/arith_encoder/state_pipeline_1/lut_u/rom
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/Scripts/lut_v.mem -format hex /tb_artih_encoder/arith_encoder/state_pipeline_1/lut_v/rom


# do wave.do
run 100 ns
