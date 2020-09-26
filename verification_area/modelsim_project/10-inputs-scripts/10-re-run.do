restart -f

# load memories
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/lut/lut_u.mem -format hex /tb_arith_encoder_10/arith_encoder/state_pipeline_1/lut_u/rom
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/lut/lut_v.mem -format hex /tb_arith_encoder_10/arith_encoder/state_pipeline_1/lut_v/rom


# do wave.do
run 300 ns
