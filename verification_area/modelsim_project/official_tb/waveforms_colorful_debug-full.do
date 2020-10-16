onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {TB - Info}
add wave -noupdate -radix unsigned /tb_arith_encoder_full/counter
add wave -noupdate -radix unsigned /tb_arith_encoder_full/miss_counter_low
add wave -noupdate -radix unsigned /tb_arith_encoder_full/miss_counter_range
add wave -noupdate -divider General
add wave -noupdate -color {Cornflower Blue} -radix decimal /tb_arith_encoder_full/arith_encoder/control/state
add wave -noupdate -color {Cornflower Blue} /tb_arith_encoder_full/arith_encoder/control/clk
add wave -noupdate -color {Cornflower Blue} /tb_arith_encoder_full/arith_encoder/control/reset_ctrl
add wave -noupdate -divider Control
add wave -noupdate /tb_arith_encoder_full/arith_encoder/control/pipeline_reg_1_2
add wave -noupdate /tb_arith_encoder_full/arith_encoder/control/pipeline_reg_final
add wave -noupdate -divider {Stage 1 - Input}
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/FL
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/FH
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/SYMBOL
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/NSYMS
add wave -noupdate -divider {Stage 1 - Outputs}
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/COMP_mux_1
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/lut_u_out
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/lut_v_out
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/UU
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_1/VV
add wave -noupdate -divider {Stage 2 - Inputs}
add wave -noupdate -color {Cornflower Blue} -radix binary /tb_arith_encoder_full/arith_encoder/state_pipeline_2/symbol
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/bool
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/UU
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/VV
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/lut_u
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/lut_v
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/in_low
add wave -noupdate -color {Cornflower Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/in_range
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/in_s
add wave -noupdate -divider {Stage 2 - Inside}
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/RR
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/range_1
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/range_2
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/range_bool
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/range_not_bool
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/low_1
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/low_bool
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/low_not_bool
add wave -noupdate -divider {Stage 2 - Normalize}
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/in_s
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/range
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/low
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/d
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/low_s0
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/low_s8
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/m_s8
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/m_s0
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/c_internal_s0
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/c_internal_s8
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/c_norm_s0
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/s_s0
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/s_s8
add wave -noupdate -color Coral -radix decimal /tb_arith_encoder_full/arith_encoder/state_pipeline_2/s_comp
add wave -noupdate -divider {Stage 2 - Outputs}
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/out_s
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/out_range
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/state_pipeline_2/out_low
add wave -noupdate -divider {General - Output}
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/RANGE_OUTPUT
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/LOW_OUTPUT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {243114 ns} 1} {{Cursor 2} {243126 ns} 1} {{Cursor 3} {243120 ns} 0}
quietly wave cursor active 3
configure wave -namecolwidth 406
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
WaveRestoreZoom {243074 ns} {243148 ns}
