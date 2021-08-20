# This script basically runs a simulations for each of the datasets configured here
# However, this script always runs the same Modelsim testbench
# For that, a target_path/target_file-bitstream.csv and a target_path/target_file-main_data.csv are defined and
     # for each round of execution, a different dataset is moved into this target directory

# Configurations
set datasets_path "/home/datasets/Reduced_Datasets"
set cqs [list cq20 cq32 cq43 cq55]
set configs [list allintra good]
set videos [list boat_hdr_amazon_720p dark720p_120f Netflix_RollerCoaster_1280x720_60fps_8bit_420_60f Netflix_DrivingPOV_1280x720_60fps_8bit_420_60f KristenAndSara_1280x720_60_120f]
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

# Start the simulation
do start_dut.do

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
               file rename -force ${dump_path}/${dump_name} ${dump_path}/${video}_${config}_${cq}.vcd
               puts "Done."
          }
     }
}
