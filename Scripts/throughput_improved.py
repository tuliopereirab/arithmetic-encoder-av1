# The main goal of this code is to analyze the throughput rate of the
# architecture.
# The idea is to check the number of symbols encoded in each cycle and guess the
# number of bits being generated.
# The table explaining exactly the relaction between nsyms and bits generated is
# below.
# This script uses N threads for the execution, where N is the number of videos
# being analyzed.

# As the architecture executes one input set per cycle, this script will check
# how many bits are being generate per cycle.
# For that, it was defined an specific number of bits according to the n_syms
# input:
    # nsyms = 2                         : 1 bit
    # nsyms = 3, 4                        : 2 bits
    # nsyms = 5, 6, 7, 8                  : 3 bits
    # nsyms = 9, 10, 11, 12, 13, 14, 15, 16:   : 4 bits
###############################################################################


import csv
import threading
from tqdm import trange, tqdm
import os
import time

#########################################
######## To Check Before Running ########
#########################################
# 1- The main path ('path') that takes to the video main directory;
# 2- The subdirectories ('cqs', 'configs', 'videos');
# 3- The 'target_path' and 'target_fname';
# 4- The organization at the bottom of the code to match with the subdirectories
# arrangement;
# 5- The 'video_names' array must represent the subdirectories arrangement.

##############################
######## SCRIPT CONFIG #######
##############################
# 'path' represents the path that takes to the video datasets
path = "/media/tulio/HD1/y4m_files"
suffix = "-main_data.csv"   # file name suffix: video + suffix
# 'target_path' and 'target_fname' represent (together) the path where the
# output data will be saved.
target_path = "/home/tulio/Desktop/arithmetic-encoder-av1/Scripts/outputs/"
target_fname = "-bool_mercat.csv"
graph_name = "graph_mercat.csv"
# --------------------------------------
#############################
###### JUSTONE = FALSE ######
# Just one runs a range of different bool configurations
# The range starts at (parallel_bools+1) and ends at (parallel_bools+num_repeat)
#############################
###### JUSTONE = TRUE #######
# It will stop after the first round
# Use parallel_bools to set the number of boolean blocks to be considered.
#############################
just_one = False
parallel_bools = 0
num_repeat = 10
# --------------------------------------
cqs = [     # Directory 1
    "cq20",
    "cq32",
    "cq43",
    "cq55"
]
configs = [ # Directory 2
    "allintra",
    "good"
]
videos = [  # Directory 3
    "boat_hdr_amazon_720p",
    "dark720p_120f",
    "KristenAndSara_1280x720_60_120f",
    "Netflix_DrivingPOV_1280x720_60fps_8bit_420_60f",
    "Netflix_RollerCoaster_1280x720_60fps_8bit_420_60f"
]

###################################
####### DO NOT MODIFY BELLOW ######
###################################
to_wait = 0
current_id = -1
videos_executed = 0
#
video_paths = []
video_names = []    # cq, config, video
# Analysis variables
graph_data = []
encoded_bits = []
original_rate = []
parallel_rate = []
total_inputs = []
total_rounds = []

# Semaphores
sem_arrays = threading.BoundedSemaphore(1)
sem_executed = threading.BoundedSemaphore(1)

class color:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
# ----------------------------------------------------------

class run_video(threading.Thread):  # Thread for each video
    def __init__(self, video_id):
        threading.Thread.__init__(self)
        self.video_id = video_id
    def run(self):
        global videos_executed
        analyze_video(self.video_id)
        sem_executed.acquire()
        videos_executed += 1
        sem_executed.release()
        tqdm.write(color.GREEN + "\t\t-> " + str(videos_executed) + "/" +
            str(to_wait) + " -> " + video_names[self.video_id][0] + "/" +
            video_names[self.video_id][1] + "/" + video_names[self.video_id][2]
            + " is done." + color.CYAN + " Total Inputs: " +
            "{:,}".format(total_inputs[self.video_id]) + color.END)

def analyze_video(id):  # Make the video analysis
    global video_names, bool_probability, bool_max_burst, bool_avg_burst
    global total_inputs
    prev_bool = False   # Flag indicating a burst
    bits_counter = 0
    num_rounds = 0    # Counts the total number of rounds (rows)
    num_inputs = 0
    bool_burst = 0
    with open(video_paths[id], "r") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=';')
        for row in csv_reader:
            num_inputs += 1
            if(int(row[0]) == 0):
                if(bool_burst < (parallel_bools-1)):
                    bool_burst += 1
                else:
                    num_rounds += 1
                    bool_burst = 0
                bits_counter += 1
            else:
                bits_counter += analyze_input(int(row[6]), int(row[0]))
                if(bits_counter > 0 and bits_counter < 3):
                    bits_counter = 0
                    num_rounds += 2
                else:
                    num_rounds += 1
    sem_arrays.acquire()
    encoded_bits[id] = bits_counter
    parallel_rate[id] = round(bits_counter/num_rounds, 5)
    original_rate[id] = round(bits_counter/num_inputs, 5)
    total_inputs[id] = num_inputs
    total_rounds[id] = num_rounds
    sem_arrays.release()

def analyze_input(nsyms, bool):
   # This function's goal is to set the right number of bits according to the input values
   if((bool == 0) or (nsyms <= 2)):      # using function bool, which means that there are only 2 symbols
      return 1
   elif((bool == 1) and (nsyms > 2) and (nsyms <= 4)):
      return 2
   elif((bool == 1) and (nsyms > 4) and (nsyms <= 8)):
      return 3
   elif((bool == 1) and (nsyms > 8) and (nsyms <= 16)):
      return 4
   else:
      return -1

def get_avg(data):  # Gets the average from an array
    sum = 0
    counter = 0
    for i in data:
        counter += 1
        sum += int(i)
    return sum/counter

def wait_videos(to_wait):   # Waits until all videos within the CQ dir are done
    while(videos_executed < to_wait):
        time.sleep(1)

def to_csv():   # Saves the analyzed data into a CSV file
    with open(target_path + str(parallel_bools) + target_fname, "w") as csv_file:
        csv_writer = csv.writer(csv_file, delimiter=',')
        csv_writer.writerow(("CQ", "Config", "Video","Total Bits",
            "Total Inputs", "Total Rounds", "Parallel Rate", "Original Rate"))
        for i in range(0, current_id+1):
            csv_writer.writerow((video_names[i][0], video_names[i][1],
                video_names[i][2], encoded_bits[i], total_inputs[i],
                total_rounds[i], parallel_rate[i], original_rate[i]))

def csv_graph():
    with open(target_path + graph_name, "w") as csv_file:
        csv_writer = csv.writer(csv_file, delimiter=',')
        csv_writer.writerow(("Parallel Bools","AVG Bits Encoded",
                            "AVG Total Inputs", "AVG Total Rounds",
                            "AVG Parallel Rate", "AVG Original Rate"))
        for i in graph_data:
            csv_writer.writerow(i)

# The core analysis below requires the 'path' to have the subdirectories
# according to expected:
    # path/cq/config/video_name-main_data.csv
# Anything different from the presented above will create an error.
print(color.HEADER + "Starting analysis..." + color.END)
for var in trange(num_repeat, desc='Parallel Bool'):
    to_wait = 0     # The number of videos to wait for
    videos_executed = 0
    current_id = -1
    if(not just_one):
        parallel_bools += 1
    encoded_bits = []
    parallel_rate = []
    original_rate = []
    total_inputs = []
    total_rounds = []
    for cq in tqdm(cqs, desc='CQs'):    # Looking at the first directory
        to_wait += len(videos) * len(configs)
        tqdm.write(color.YELLOW + "\t-> " + cq + color.CYAN +
            " -> Waiting for " + str(to_wait) + " of the current " +
            str(videos_executed) + " executed." + color.END)
        for config in configs:  # Looking at second directory
            for video in videos:    # Using the video names as file name
                temp_path = path + "/" + cq + "/" + config + "/"
                temp_path += video + suffix
                video_paths.append(temp_path)
                video_names.append((cq, config, video))
                ################################
                # Starting Analysis ############
                ################################
                encoded_bits.append(0)
                original_rate.append(0)
                parallel_rate.append(0)
                total_inputs.append(0)
                total_rounds.append(0)
                current_id += 1
                thread = run_video(current_id)
                thread.start()
                tqdm.write(color.BLUE + "\t\t-> Started video: " + cq + "/" + config
                    + "/" + video + color.END)
        wait_videos(to_wait)
    to_csv()
    if(just_one):
        print(color.GREEN + "Done with everything." + color.END)
        quit()
    graph_data.append((str(parallel_bools),
                    str(sum(encoded_bits)/len(encoded_bits)),
                    str(sum(total_inputs)/len(total_inputs)),
                    str(sum(total_rounds)/len(total_rounds)),
                    str(sum(parallel_rate)/len(parallel_rate)),
                    str(sum(original_rate)/len(original_rate))))
csv_graph()
print(color.GREEN + "Done with everything." + color.END)
