onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider General
add wave -noupdate -color Magenta -radix unsigned /tb_carry_propagation/state_pipeline_4/s4_clk
add wave -noupdate -color Magenta -radix unsigned /tb_carry_propagation/state_pipeline_4/s4_reset
add wave -noupdate /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/ctrl_mux_final
add wave -noupdate -divider Inputs
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_carry_propagation/state_pipeline_4/in_arith_bitstream_1
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_carry_propagation/state_pipeline_4/in_arith_bitstream_2
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_carry_propagation/state_pipeline_4/in_arith_flag
add wave -noupdate -divider Outputs
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_bit_1
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_bit_2
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_bit_3
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_last_bit
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_flag_bitstream
add wave -noupdate -divider {Start Values}
add wave -noupdate -radix unsigned /tb_carry_propagation/state_pipeline_4/s4_flag_first
add wave -noupdate -radix unsigned /tb_carry_propagation/state_pipeline_4/s4_final_flag
add wave -noupdate -radix unsigned /tb_carry_propagation/state_pipeline_4/s4_final_flag_2_3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4624846 ns} 1} {{Cursor 2} {4624844 ns} 1} {{Cursor 3} {4624828 ns} 1} {{Cursor 4} {4624845 ns} 0}
quietly wave cursor active 4
configure wave -namecolwidth 352
configure wave -valuecolwidth 89
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
WaveRestoreZoom {4624803 ns} {4624869 ns}
