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
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/flag
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/flag_final_bits
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_flag_standby
add wave -noupdate -color {Dark Orchid} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/flag_possible_error_in
add wave -noupdate -divider Bitstreams
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_new_bitstream_1
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_new_bitstream_2
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_previous_bitstream
add wave -noupdate -color {Orange Red} -radix unsigned /entropy_encoder_tb/ent_enc/carry_propagation/in_standby_bitstream
add wave -noupdate -divider -height 20 {NEW AUXILIAR}
add wave -noupdate -divider {Inputs Aux}
add wave -noupdate -color Sienna -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/in_standby_flag
add wave -noupdate -color Sienna -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/in_flag
add wave -noupdate -color Sienna -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/in_bitstream_1
add wave -noupdate -color Sienna -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/in_bitstream_2
add wave -noupdate -color Sienna -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/in_previous_bitstream
add wave -noupdate -color Sienna -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/in_standby_bitstream
add wave -noupdate -divider Inside
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/reg_flag_final
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/reg_addr_write
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/reg_addr_read
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/flag_final
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/flag_start
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/flag_second_time
add wave -noupdate -color Magenta -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/reg_flag_second_time_reading
add wave -noupdate -divider {Out Auxiliar}
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/out_bit_1
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/out_bit_2
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/out_bit_3
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/out_flag
add wave -noupdate -radix unsigned /entropy_encoder_tb/ent_enc/aux_carry_propagation/ctrl_mux_final
add wave -noupdate -divider {GENERAL OUTPUTS}
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_1
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_2
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_BIT_3
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_LAST_BIT
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_FLAG_BITSTREAM
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/OUT_FLAG_LAST
add wave -noupdate -color Gold -radix unsigned /entropy_encoder_tb/ent_enc/ERROR_INDICATION
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9690505 ns} 0} {{Cursor 2} {619362 ns} 1}
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
WaveRestoreZoom {9690502 ns} {9690618 ns}
