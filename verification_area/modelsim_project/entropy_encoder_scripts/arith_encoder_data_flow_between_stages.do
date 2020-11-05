onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider General
add wave -noupdate /entropy_encoder_tb/ent_enc/arith_encoder/general_clk
add wave -noupdate /entropy_encoder_tb/ent_enc/arith_encoder/reset
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/control/state
add wave -noupdate -divider Inputs
add wave -noupdate -color {Medium Slate Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/general_fl
add wave -noupdate -color {Medium Slate Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/general_fh
add wave -noupdate -color {Medium Slate Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/general_symbol
add wave -noupdate -color {Medium Slate Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/general_nsyms
add wave -noupdate -color {Medium Slate Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/general_bool
add wave -noupdate -divider {Stage 1-2}
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_lut_u
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_lut_v
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_UU
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_VV
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_symbol
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_COMP_mux_1
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_bool
add wave -noupdate -divider {Stage 2-3}
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_initial_range
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_range_ready
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_u
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_v_bool
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_d
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_bool_symbol
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/reg_COMP_mux_1_s2
add wave -noupdate -divider Outputs
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/RANGE_OUTPUT
add wave -noupdate -color Magenta /entropy_encoder_tb/ent_enc/arith_encoder/LOW_OUTPUT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 353
configure wave -valuecolwidth 119
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {519964 ns} {548044 ns}
