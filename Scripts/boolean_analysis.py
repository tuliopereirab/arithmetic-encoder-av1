import csv
import threading
from tqdm import tqdm
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
path = "/media/tulio/HD1/objective-2/Datasets"
suffix = "-main_data.csv"   # file name suffix: video + suffix
# 'target_path' and 'target_fname' represent (together) the path where the
# output data will be saved.
target_path = "/home/tulio/Desktop/arithmetic-encoder-av1/Scripts/outputs/"
target_fname = "bool_analysis.csv"
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
bool_probability = []
bool_max_burst = []
bool_avg_burst = []
total_inputs = []

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
            total_inputs[self.video_id] + color.END)

def analyze_video(id):  # Make the video analysis
    global video_names, bool_probability, bool_max_burst, bool_avg_burst
    global total_inputs
    prev_bool = False   # Flag indicating a burst
    bool_counter = 0    # Counts the number of boolean rounds
    total_rounds = 0    # Counts the total number of rounds (rows)
    max_burst = 0       # Holds the maximum burst
    all_bursts = []     # Stores all bursts for further calculations
    current_burst = 0   # Stores the number of booleans in the current burst
    with open(video_paths[id], "r") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=';')
        for row in csv_reader:
            total_rounds += 1
            if(int(row[0]) == 0):
                bool_counter += 1
                if(prev_bool):
                    current_burst += 1
                else:
                    current_burst = 1
                    prev_bool = True
            else:
                # Ends the current burst once receives bool_flag == 1
                if(prev_bool):
                    if(current_burst > max_burst):
                        max_burst = current_burst
                    all_bursts.append(current_burst)
                    prev_bool = False
                    current_burst = 0
    sem_arrays.acquire()
    bool_probability[id] = str((bool_counter/total_rounds))
    bool_max_burst[id] = str(max_burst)
    bool_avg_burst[id] = str(get_avg(all_bursts))
    total_inputs[id] = "{:,}".format(total_rounds)
    sem_arrays.release()

def get_avg(data):  # Gets the average from an array
    sum = 0
    counter = 0
    for i in data:
        counter += 1
        sum += int(i)
    return round(sum/counter, 5)

def wait_videos(to_wait):   # Waits until all videos within the CQ dir are done
    while(videos_executed < to_wait):
        time.sleep(5)

def to_csv():   # Saves the analyzed data into a CSV file
    with open(target_path + target_fname, "w") as csv_file:
        csv_writer = csv.writer(csv_file, delimiter=',')
        csv_writer.writerow(("CQ", "Config", "Video","Probability","AVG Burst",
            "Max Burst", "Total Inputs"))
        for i in range(0, current_id+1):
            csv_writer.writerow((video_names[i][0], video_names[i][1],
                video_names[i][2], bool_probability[i], bool_avg_burst[i],
                bool_max_burst[i], total_inputs[i]))

# The core analysis below requires the 'path' to have the subdirectories
# according to expected:
    # path/cq/config/video_name-main_data.csv
# Anything different from the presented above will create an error.
to_wait = 0     # The number of videos to wait for
current_id = -1
print(color.HEADER + "Starting analysis..." + color.END)
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
            bool_probability.append(0)
            bool_max_burst.append(0)
            bool_avg_burst.append(0)
            total_inputs.append(0)
            current_id += 1
            thread = run_video(current_id)
            thread.start()
            tqdm.write(color.BLUE + "\t\t-> Started video: " + cq + "/" + config
                + "/" + video + color.END)
    wait_videos(to_wait)
to_csv()
print(color.GREEN + "Done with everything." + color.END)
