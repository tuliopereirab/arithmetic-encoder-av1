onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider INPUTS
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_clk
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_reset
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_final_flag
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_fl
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_fh
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_symbol
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_nsyms
add wave -noupdate -color {Lime Green} -radix unsigned /entropy_encoder_tb/ent_enc/top_bool
add wave -noupdate -divider {CARRY INPUTS}
add wave -noupdate -divider {From Arith Encoder}
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_BIT_1
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_BIT_2
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_FLAG_BITSTREAM
add wave -noupdate -divider Flags
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/flag
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/flag_final_bits
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/in_flag_standby
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/flag_possible_error_in
add wave -noupdate -divider Bitstreams
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/in_new_bitstream_1
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/in_new_bitstream_2
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/in_previous_bitstream
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/in_standby_bitstream
add wave -noupdate -divider {CARRY OUTPUTS}
add wave -noupdate -divider Flags
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/out_flag
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/out_flag_last
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/out_flag_standby
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/flag_possible_error_out
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/confirmed_error
add wave -noupdate -divider Bitstream
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/out_bitstream_1
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/out_bitstream_2
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/out_bitstream_3
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/bitstream_hold
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propagation/out_standby_bitstream
add wave -noupdate -divider {GENERAL OUTPUTS}
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_1
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_2
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_3
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_LAST_BIT
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_FLAG_BITSTREAM
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_FLAG_LAST
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/ERROR_INDICATION
add wave -noupdate -divider -height 20 FINAL_BITS
add wave -noupdate -divider Inputs
add wave -noupdate -color {Cadet Blue} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/final_bits/in_cnt
add wave -noupdate -color {Cadet Blue} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/final_bits/in_low
add wave -noupdate -divider Outputs
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/final_bits/flag
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/final_bits/out_bit_1
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/final_bits/out_bit_2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {513396 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 310
configure wave -valuecolwidth 83
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
WaveRestoreZoom {513298 ns} {513414 ns}
