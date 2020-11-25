onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider General
add wave -noupdate /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/clk
add wave -noupdate /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/reset
add wave -noupdate -divider Inputs
add wave -noupdate -color {Medium Aquamarine} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/in_standby_flag
add wave -noupdate -color {Medium Aquamarine} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/flag_first
add wave -noupdate -color Cyan -radix binary /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/in_flag
add wave -noupdate -color Cyan -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/in_bitstream_1
add wave -noupdate -color Cyan -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/in_bitstream_2
add wave -noupdate -color {Medium Aquamarine} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/in_previous_bitstream
add wave -noupdate -color {Medium Aquamarine} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/in_standby_bitstream
add wave -noupdate -divider Regs
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/reg_addr_write
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/reg_addr_read
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/reg_propag
add wave -noupdate -color {Cornflower Blue} /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/reg_status
add wave -noupdate -divider {Main Wires}
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/addr_write
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/addr_read
add wave -noupdate -color Gold -radix binary /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/buffer_ctrl
add wave -noupdate -color Gold -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/propag_zero
add wave -noupdate -color Gold -radix binary /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/status_flag
add wave -noupdate -color Gold -radix binary /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/phase_flag
add wave -noupdate -divider Outputs
add wave -noupdate -color Magenta -radix binary /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/out_flag
add wave -noupdate -color {Medium Orchid} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/out_bit_1
add wave -noupdate -color {Medium Orchid} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/out_bit_2
add wave -noupdate -color {Medium Orchid} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/out_bit_3
add wave -noupdate -color {Medium Orchid} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/out_bit_4
add wave -noupdate -color {Orange Red} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/ctrl_mux_final
add wave -noupdate -color {Medium Orchid} -radix unsigned /tb_carry_propagation/state_pipeline_4/aux_carry_propagation/ctrl_mux_last_bit
add wave -noupdate -divider ===================
add wave -noupdate -divider {General Output}
add wave -noupdate /tb_carry_propagation/state_pipeline_4/out_carry_flag_bitstream
add wave -noupdate -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_bit_1
add wave -noupdate -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_bit_2
add wave -noupdate -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_bit_3
add wave -noupdate -radix unsigned /tb_carry_propagation/state_pipeline_4/out_carry_last_bit
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4624846 ns} 1} {{Cursor 2} {4624844 ns} 1} {{Cursor 3} {4624828 ns} 1} {{Cursor 4} {4624845 ns} 0} {{Cursor 5} {1376289 ns} 0}
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
WaveRestoreZoom {31084 ns} {31150 ns}
