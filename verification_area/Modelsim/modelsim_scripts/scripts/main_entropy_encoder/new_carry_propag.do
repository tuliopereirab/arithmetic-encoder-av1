onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {GENERAL STUFF}
add wave -noupdate -color Green -radix unsigned /entropy_encoder_tb/ent_enc/top_clk
add wave -noupdate -color Green -radix unsigned /entropy_encoder_tb/ent_enc/top_reset
add wave -noupdate -color Green -radix unsigned /entropy_encoder_tb/ent_enc/top_flag_first
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/top_final_flag
add wave -noupdate -divider INPUTS
add wave -noupdate -color Red -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/clk
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/flag_final
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/flag_first
add wave -noupdate -color Red -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/flag_in
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/in_bitstream_1
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/in_bitstream_2
add wave -noupdate -divider {Middle Variables}
add wave -noupdate -color Orange -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/reg_previous
add wave -noupdate -color Orange -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/reg_counter
add wave -noupdate -color Gold /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/reg_1st_bitstream
add wave -noupdate -divider OUTPUTS
add wave -noupdate -color {Medium Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/out_flag
add wave -noupdate -color {Medium Sea Green} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/out_bitstream_1
add wave -noupdate -color {Medium Sea Green} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/out_bitstream_2
add wave -noupdate -color {Medium Sea Green} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/out_bitstream_3
add wave -noupdate -color {Medium Sea Green} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/out_bitstream_4
add wave -noupdate -color {Medium Sea Green} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/out_bitstream_5
add wave -noupdate -color {Spring Green} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/carry_propag/out_flag_last
add wave -noupdate -divider {ARC OUTPUT}
add wave -noupdate -color {Medium Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/output_flag_last
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/out_carry_bit_1
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/out_carry_bit_2
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/out_carry_bit_3
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/out_carry_bit_4
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/out_carry_bit_5
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/state_pipeline_4/out_carry_flag_bitstream
add wave -noupdate -divider {Arith Encoder Outputs}
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_BIT_1
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_BIT_2
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_FLAG_BITSTREAM
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5112316 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 198
configure wave -valuecolwidth 100
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
WaveRestoreZoom {17857 ns} {17891 ns}
