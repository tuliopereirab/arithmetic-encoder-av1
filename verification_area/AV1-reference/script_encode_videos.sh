sudo cmake aom/ -DAOM_TARGET_CPU=generic -DCMAKE_C_FLAGS="-O3 -pg" -DCMAKE_CXX_FLAGS="-O3 -pg"
make

# video 1 - Beauty_1920x1080_120fps_420_8bit_YUV.y4m
echo "Executing video 1 - CQ 55"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=55 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/Beauty_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_55/Beauty_1920x1080_120fps_420_8bit_YUV_cq55_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_55/Beauty_1920x1080_120fps_420_8bit_YUV_cq55_final_bitstream.csv
echo "Executing video 1 - CQ 20"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=20 --limit=120 -o  /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/Beauty_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_20/Beauty_1920x1080_120fps_420_8bit_YUV_cq20_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_20/Beauty_1920x1080_120fps_420_8bit_YUV_cq20_final_bitstream.csv
# # =======================================================
#
#
# # video 2 - Bosphorus_1920x1080_120fps_420_8bit_YUV
echo "Executing video 2 - CQ 20"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=20 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/Bosphorus_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_20/Bosphorus_1920x1080_120fps_420_8bit_YUV_cq20_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_20/Bosphorus_1920x1080_120fps_420_8bit_YUV_cq20_final_bitstream.csv
echo "Executing video 2 - CQ 55"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=55 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/Bosphorus_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_55/Bosphorus_1920x1080_120fps_420_8bit_YUV_cq55_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_55/Bosphorus_1920x1080_120fps_420_8bit_YUV_cq55_final_bitstream.csv
# =======================================================


# video 3 - HoneyBee_1920x1080_120fps_420_8bit_YUV
echo "Executing video 3 - CQ 20"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=20 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/HoneyBee_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_20/HoneyBee_1920x1080_120fps_420_8bit_YUV_cq20_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_20/HoneyBee_1920x1080_120fps_420_8bit_YUV_cq20_final_bitstream.csv
echo "Executing video 3 - CQ 55"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=55 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/HoneyBee_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_55/HoneyBee_1920x1080_120fps_420_8bit_YUV_cq55_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_55/HoneyBee_1920x1080_120fps_420_8bit_YUV_cq55_final_bitstream.csv
# =======================================================


# video 4 - Jockey_1920x1080_120fps_420_8bit_YUV
echo "Executing video 4 - CQ 20"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=20 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/Jockey_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_20/Jockey_1920x1080_120fps_420_8bit_YUV_cq20_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_20/Jockey_1920x1080_120fps_420_8bit_YUV_cq20_final_bitstream.csv
echo "Executing video 4 - CQ 55"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=55 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/Jockey_1920x1080_120fps_420_8bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_55/Jockey_1920x1080_120fps_420_8bit_YUV_cq55_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_55/Jockey_1920x1080_120fps_420_8bit_YUV_cq55_final_bitstream.csv
# =======================================================


# video 5 - ReadySetGo_3840x2160_120fps_420_10bit_YUV
echo "Executing video 5 - CQ 20"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=20 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/ReadySetGo_3840x2160_120fps_420_10bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_20/ReadySetGo_3840x2160_120fps_420_10bit_YUV_cq20_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_20/ReadySetGo_3840x2160_120fps_420_10bit_YUV_cq20_final_bitstream.csv
echo "Executing video 5 - CQ 55"
./aomenc --verbose --psnr --frame-parallel=0 --tile-columns=0 --passes=2 --cpu-used=8 --threads=10 --kf-min-dist=1000 --kf-max-dist=1000 --end-usage=q --lag-in-frames=19 --cq-level=55 --limit=120 -o /media/tulio/HD/y4m_files/video_coded/video_codificado.ivf /media/tulio/HD/y4m_files/ReadySetGo_3840x2160_120fps_420_10bit_YUV.y4m
sync
mv arith_analysis/main_data.csv /media/tulio/HD/y4m_files/generated_files/cq_55/ReadySetGo_3840x2160_120fps_420_10bit_YUV_cq55_main_data.csv
mv arith_analysis/complete_final_bitstream.csv /media/tulio/HD/y4m_files/generated_files/cq_55/ReadySetGo_3840x2160_120fps_420_10bit_YUV_cq55_final_bitstream.csv
# =======================================================

# =======================================================
