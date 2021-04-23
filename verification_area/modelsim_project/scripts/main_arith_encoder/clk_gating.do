onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider General
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/general_clk
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/reset
add wave -noupdate -divider Inputs
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/general_fl
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/general_fh
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/general_symbol
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/general_nsyms
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/general_bool
add wave -noupdate -color Magenta -radix unsigned /tb_arith_encoder_full/arith_encoder/RANGE_OUTPUT
add wave -noupdate -divider {Regs 1-2}
add wave -noupdate -color {Sky Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_lut_u
add wave -noupdate -color {Sky Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_lut_v
add wave -noupdate -color {Sky Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_UU
add wave -noupdate -color {Sky Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_VV
add wave -noupdate -color {Sky Blue} -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_COMP_mux_1
add wave -noupdate -divider {Regs 2-3}
add wave -noupdate -color Red -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_u
add wave -noupdate -color Red -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_v_bool
add wave -noupdate -color Red -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_d
add wave -noupdate -color Red -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_bool_s3
add wave -noupdate -color Red -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_lsb_symbol
add wave -noupdate -color Red -radix unsigned /tb_arith_encoder_full/arith_encoder/reg_COMP_mux_1_s2
add wave -noupdate -divider Outputs
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/LOW_OUTPUT
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/CNT_OUTPUT
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/OUT_BIT_1
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/OUT_BIT_2
add wave -noupdate -color Gold -radix unsigned /tb_arith_encoder_full/arith_encoder/OUT_FLAG_BITSTREAM
add wave -noupdate -divider {Clock Gating}
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/bit_1_clk_gating
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/bit_2_clk_gating
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/boolean_s2_clk_gating
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/boolean_s3_clk_gating_std
add wave -noupdate -radix unsigned /tb_arith_encoder_full/arith_encoder/boolean_s3_clk_gating_bool
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 213
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
WaveRestoreZoom {0 ns} {9769 ns}
