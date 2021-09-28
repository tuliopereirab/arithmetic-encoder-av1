# This script basically runs a simulations for each of the datasets configured here
# However, this script always runs the same Modelsim testbench
# For that, a target_path/target_file-bitstream.csv and a target_path/target_file-main_data.csv are defined and
     # for each round of execution, a different dataset is moved into this target directory

# Configurations
# set_dataset options: "mercat" or "objective"
set arc_version 2
set set_dataset "mercat"
set dump_vcd 0
set final_bitstream "bitstream.csv"
set final_main "main_data.csv"

# Dumpfile
set dump_path "/home/vcds"
set dump_name "dump.vcd"

# Target Stuff
set target_path "/home/datasets/target"
set target_name "target"

# Counter
set counter 0

# Start the right simulation according to Arc Version
if { $arc_version == 1 } {
    puts "Set architecture version 1-bool."
    do DUT_ent_enc/start_dut_1-bool.do
} elseif { $arc_version == 2 } {
    puts "Set architecture version 2-bool."
    do DUT_ent_enc/start_dut_2-bool.do
} elseif { $arc_version == 3 } {
    puts "Set architecture version 3-bool."
    do DUT_ent_enc/start_dut_3-bool.do
} else {
    puts "Set architecture version 4-bool."
    do DUT_ent_enc/start_dut_4-bool.do
}

if {$set_dataset == "mercat"} {
    puts "Using Mercat dataset"
    set datasets_path "/media/tulio/y4m_files/generated_files"
    set cqs "Reduced_Datasets"
    set configs [list cq20 cq55]
    set videos [list Beauty_1920x1080_120fps_420_8bit_YUV Bosphorus_1920x1080_120fps_420_8bit_YUV HoneyBee_1920x1080_120fps_420_8bit_YUV Jockey_1920x1080_120fps_420_8bit_YUV ReadySetGo_3840x2160_120fps_420_10bit_YUV YachtRide_3840x2160_120fps_420_10bit_YUV]
} else {
    puts "Using Objective-2 dataset"
    set datasets_path "/media/tulio/objective-2/Reduced_Datasets"
    set cqs [list cq20 cq32 cq43 cq55]
    set configs [list allintra good]
    set videos [list boat_hdr_amazon_720p dark720p_120f Netflix_RollerCoaster_1280x720_60fps_8bit_420_60f Netflix_DrivingPOV_1280x720_60fps_8bit_420_60f KristenAndSara_1280x720_60_120f]
}
foreach cq $cqs {
     foreach config $configs {
          foreach video $videos {
               file delete ?-force? ?--? ${target_path}/${target_name}-${final_main}
               file delete ?-force? ?--? ${target_path}/${target_name}-${final_bitstream}
               incr counter
               puts "====================="
               puts "$counter -> Video: ${video}, Config: ${config}, CQ: ${cq}"
               file copy -force ${datasets_path}/${cq}/${config}/${video}-${final_main} ${target_path}/
               file copy -force ${datasets_path}/${cq}/${config}/${video}-${final_bitstream} ${target_path}/
               file rename -force ${target_path}/${video}-${final_main} ${target_path}/${target_name}-${final_main}
               file rename -force ${target_path}/${video}-${final_bitstream} ${target_path}/${target_name}-${final_bitstream}
               puts "Running simulation..."
               do run.do
               if {$dump_vcd == 1} {
                    file rename -force ${dump_path}/${dump_name} ${dump_path}/${video}_${config}_${cq}.vcd
               }
               puts "Done."
          }
     }
}
