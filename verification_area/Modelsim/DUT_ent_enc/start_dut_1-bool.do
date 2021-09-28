vsim -gui -t ns work.entropy_encoder_tb
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Inputs
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_clk
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_reset
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_flag_first
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_final_flag
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_fl
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_fh
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_symbol
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_nsyms
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/top_bool
add wave -noupdate -divider Outputs
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/OUT_FLAG_BITSTREAM
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/OUT_BIT_1
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/OUT_BIT_2
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/OUT_BIT_3
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/OUT_BIT_4
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/OUT_BIT_5
add wave -noupdate -radix unsigned /entropy_encoder_tb/DUT_ent_enc/OUT_FLAG_LAST
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ns} {1 us}
