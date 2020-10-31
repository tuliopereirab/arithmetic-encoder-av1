restart -f

# load memories
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/lut/lut_u.mem -format hex /entropy_encoder_tb/ent_enc/arith_encoder/state_pipeline_1/lut_u/rom
mem load -i C:/Users/Tulio/Desktop/arithmetic_encoder_av1/lut/lut_v.mem -format hex /entropy_encoder_tb/ent_enc/arith_encoder/state_pipeline_1/lut_v/rom


# do wave.do
run 70000000 ns
