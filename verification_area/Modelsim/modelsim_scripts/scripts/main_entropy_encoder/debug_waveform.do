onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider INPUTS
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_clk
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_reset
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_final_flag
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_fl
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_fh
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_symbol
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_nsyms
add wave -noupdate -color Yellow -radix unsigned /entropy_encoder_tb/ent_enc/top_bool
add wave -noupdate -divider OUTPUTS
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_1
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_2
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/OUT_LAST_BIT
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/OUT_FLAG_BITSTREAM
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/OUT_FLAG_LAST
add wave -noupdate -divider ==============================
add wave -noupdate -divider {CARRY PROPAGATION}
add wave -noupdate -color {Cadet Blue} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/flag
add wave -noupdate -color {Cadet Blue} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/flag_final_bits
add wave -noupdate -color {Cadet Blue} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_new_bitstream_1
add wave -noupdate -color {Cadet Blue} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_new_bitstream_2
add wave -noupdate -color {Cadet Blue} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_previous_bitstream
add wave -noupdate -divider {FINAL BITS}
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/final_bits/in_cnt
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/final_bits/in_low
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/final_bits/flag
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/final_bits/out_bit_1
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/final_bits/out_bit_2
add wave -noupdate -divider ARITH_ENCODER
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_BIT_1
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_BIT_2
add wave -noupdate -color {Cornflower Blue} -radix unsigned /entropy_encoder_tb/ent_enc/arith_encoder/OUT_FLAG_BITSTREAM
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {121 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 342
configure wave -valuecolwidth 192
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
WaveRestoreZoom {0 ns} {366 ns}
