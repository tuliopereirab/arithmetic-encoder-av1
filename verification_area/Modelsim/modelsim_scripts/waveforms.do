onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Inputs
add wave -noupdate /tb_arith_encoder/arith_encoder/general_clk
add wave -noupdate /tb_arith_encoder/arith_encoder/reset
add wave -noupdate /tb_arith_encoder/arith_encoder/general_fl
add wave -noupdate /tb_arith_encoder/arith_encoder/general_fh
add wave -noupdate /tb_arith_encoder/arith_encoder/general_symbol
add wave -noupdate /tb_arith_encoder/arith_encoder/general_nsyms
add wave -noupdate -divider {Stage 1-2}
add wave -noupdate /tb_arith_encoder/arith_encoder/reg_UU
add wave -noupdate /tb_arith_encoder/arith_encoder/reg_VV
add wave -noupdate /tb_arith_encoder/arith_encoder/reg_COMP_mux_1
add wave -noupdate -divider {Stage 2-3}
add wave -noupdate /tb_arith_encoder/arith_encoder/reg_Range_s2
add wave -noupdate /tb_arith_encoder/arith_encoder/reg_Low_s2
add wave -noupdate -divider Outputs
add wave -noupdate /tb_arith_encoder/arith_encoder/RANGE_OUTPUT
add wave -noupdate /tb_arith_encoder/arith_encoder/LOW_OUTPUT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 310
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
WaveRestoreZoom {0 ns} {95 ns}
