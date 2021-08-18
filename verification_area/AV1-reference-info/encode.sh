#!/bin/bash

# Colors
red='\e[0;31m'
boldRed='\e[1;31m'
green='\e[0;32m'
boldGreen='\e[1;32m'
yellow='\e[0;33m'
boldYellow='\e[1;33m'
pink='\e[0;35m'
nc='\e[0m'

# Paths
videos_path='/media/tulio/HD1/objective-2/Videos'
video_coded_dest='/media/tulio/HD1/objective-2/Videos_Coded'
dataset_origin='/home/tulio/av1/arith_analysis'
dataset_dest='/media/tulio/HD1/objective-2/Datasets'
folders='allintra good'

# Command
cmd_first='--verbose --psnr'
cmd_second='--frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=4  --threads=4 --end-usage=q --lag-in-frames=0 --cq-level=20 --limit=60 -o'
coded_extension='.webm'

clear

sudo cmake aom/ -DAOM_TARGET_CPU=generic -DCMAKE_C_FLAGS="-O3 -pg" -DCMAKE_CXX_FLAGS="-O3 -pg"
sudo make

for folder in $folders
do	
	echo -e "${yellow}==========================================================${nc}"
	echo -e "${pink}Running $folder...${nc}"
	for j in $videos_path/*
	do
		video_name=$(echo $j | cut -f 1 -d '.')
		video_name=$(echo $video_name | cut -f 7 -d '/')
		echo -e "${yellow}Video: ${boldYellow}$video_name${nc}"

		./aomenc $cmd_first --$folder $cmd_second $video_coded_dest/$video_name.$coded_extension $j 
		
		mv $dataset_origin/main_data.csv $dataset_dest/$folder/$video_name-main_data.csv
		mv $dataset_origin/complete_final_bitstream.csv $dataset_dest/$folder/$video_name-bitstream.csv

		echo -e "${green}Done with video: ${boldGreen}$video_name${nc}"
		echo -e "${yellow}--------------${nc}"
	done
done
