onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Inputs
add wave -noupdate /tb_artih_encoder/arith_encoder/general_clk
add wave -noupdate /tb_artih_encoder/arith_encoder/reset
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/general_fl
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/general_fh
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/general_symbol
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/general_nsyms
add wave -noupdate -divider {Stage 1-2}
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/reg_UU
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/reg_VV
add wave -noupdate /tb_artih_encoder/arith_encoder/reg_lut_u
add wave -noupdate /tb_artih_encoder/arith_encoder/reg_lut_v
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/reg_COMP_mux_1
add wave -noupdate -divider {Stage 2-3}
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/reg_Range_s2
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/reg_Low_s2
add wave -noupdate -divider Outputs
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/RANGE_OUTPUT
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/LOW_OUTPUT
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/CNT_OUTPUT
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Stage 1- LUT}
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/state_pipeline_1/lut_addr
add wave -noupdate -divider {Stage 1-Variables}
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/state_pipeline_1/UU
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/state_pipeline_1/VV
add wave -noupdate -divider {Stage 1-Compare}
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/state_pipeline_1/COMP_mux_1
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Stage 2-Mult}
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/state_pipeline_2/RR
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_2/u
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_2/v
add wave -noupdate -divider {Internal Values}
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_2/range_1
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_2/range_2
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_2/low_1
add wave -noupdate -divider {Stage 2-Outputs}
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/state_pipeline_2/low
add wave -noupdate -radix unsigned /tb_artih_encoder/arith_encoder/state_pipeline_2/range
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Stage [3,4,5] - D, S}
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/D
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/S
add wave -noupdate -divider {Stage [3,4,5] - s0}
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/C_s0
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/M_s0
add wave -noupdate -divider {Stage [3,4,5] - s8}
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/M_s8
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/C_s8
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/low_s8
add wave -noupdate -divider {Stage [3,4,5] - Comp}
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/COMP_mux_2
add wave -noupdate /tb_artih_encoder/arith_encoder/state_pipeline_3/COMP_mux_3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {43 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 401
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
WaveRestoreZoom {7 ns} {105 ns}
