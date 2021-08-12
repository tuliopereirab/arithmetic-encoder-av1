onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Input
add wave -noupdate -color Gold -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/in_s
add wave -noupdate -color Gold -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/in_low
add wave -noupdate -divider Comp
add wave -noupdate -color Blue -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/s_comp
add wave -noupdate -divider Internals
add wave -noupdate -color Magenta -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/low_s0
add wave -noupdate -color Magenta -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/c_bit_s0
add wave -noupdate -color Magenta -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/c_bit_s8
add wave -noupdate -divider Output
add wave -noupdate -color {Orange Red} -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/out_offs
add wave -noupdate -color {Orange Red} -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/out_bit_1
add wave -noupdate -color {Orange Red} -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/out_bit_2
add wave -noupdate -color {Orange Red} -radix unsigned /tb_bitstream/arith_encoder/stage_pipeline_3/flag_bitstream
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
