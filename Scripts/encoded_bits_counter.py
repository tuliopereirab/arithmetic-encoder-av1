import csv
import threading
from tqdm import tqdm
import os.path
# This script counts the number of bits encoded during the simulation.
# Problems with the power estimation:
    # It takes into consideration only the number of rounds,
    # With different throughput/cycle, the number of bits encoded variate

# Number of bits is estimated according to the following rule:
# nsyms = 2                                 : 1 bit
# nsyms = 3, 4                              : 2 bits
# nsyms = 5, 6, 7, 8                        : 3 bits
# nsyms = 9, 10, 11, 12, 13, 14, 15, 16:    : 4 bits

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

# Configuration Variables
# arcs: 0 -> original, 1 -> 1-bool, 2 -> 2-bool, 3-> 3-bool
arcs = [0, 1, 2, 3]
path_to_videos = "/media/tulio/HD1/objective-2/Reduced_Datasets"
cqs = [
    "cq20",
    "cq32",
    "cq43",
    "cq55"
]
configs = [
    "allintra",
    "good"
]
videos = [
    "boat_hdr_amazon_720p",
    "dark720p_120f",
    "KristenAndSara_1280x720_60_120f",
    "Netflix_DrivingPOV_1280x720_60fps_8bit_420_60f",
    "Netflix_RollerCoaster_1280x720_60fps_8bit_420_60f"
]

path_to_dest = "/home/tulio/Desktop/arithmetic-encoder-av1/Scripts/outputs"
output_fname = "obj-2"

period_ns = 2.5 # in nanosseconds according to testbench
sim_time_us = 100   # in microsseconds according to flow

# Non-changeble Variables
suffix = "-main_data.csv"
col_nsyms = 6
col_bool = 0

def get_bits(in_nsyms, in_bool):
    # Returns the number of bits according to nsyms and bool_flag
    bool = int(in_bool)
    nsyms = int(in_nsyms)
    if((bool == 0) or (nsyms <= 2)):
       return 1
    elif((bool == 1) and (nsyms > 2) and (nsyms <= 4)):
       return 2
    elif((bool == 1) and (nsyms > 4) and (nsyms <= 8)):
       return 3
    elif((bool == 1) and (nsyms > 8) and (nsyms <= 16)):
       return 4
    else:
       return -1

def get_arc_name(arc):
    # Returns the name of the architecture
    if(arc == 0):
        return "original"
    elif(arc == 1):
        return "1-bool"
    elif(arc == 2):
        return "2-bool"
    else:
        return "3-bool"

def get_arc_bool(arc):
    # Return how many parallel bools the architecture has
    if(arc == 0):
        return 1
    elif(arc == 1):
        return 1
    elif(arc == 2):
        return 2
    else:
        return 3

def create_paths():
    global path_to_videos
    all_paths = []  # cq, config, video
    if(path_to_videos[-1] != "/"):
        print(color.YELLOW + "Warning: Added '/' into path to videos." +
                color.END)
        path_to_videos += "/"
    print(color.HEADER + "Creating paths..." + color.END)
    for cq in tqdm(cqs):
        for config in configs:
            for video in videos:
                temp_path = path_to_videos + cq + "/" + config + "/" + video
                temp_path += suffix
                if(os.path.exists(temp_path)):
                    all_paths.append((cq, config, video, temp_path))
                    tqdm.write(color.GREEN + "\tValid path: " + temp_path +
                                color.END)
                else:
                    tqdm.write(color.YELLOW + "\tInvalid path: " + temp_path +
                                color.END)
    print(color.HEADER + "Found " + str(len(all_paths)) + " valid paths." +
            color.END)
    return all_paths

def create_csv(arc, data):
    global path_to_dest
    if(path_to_dest[-1] != "/"):
        print(color.YELLOW + "WARNING: Added '/' into path to destination" +
                color.END)
        path_to_dest += "/"
    full_path = path_to_dest + output_fname + "_" + arc + ".csv"
    print(color.HEADER + "Saving data into " + full_path + color.END)
    with open(full_path, "w") as csv_file:
        csv_writer = csv.writer(csv_file)
        for i in data:
            csv_writer.writerow(i)

def analyze_video(arc, total, path):
    rounds = 0
    bits = 0
    bool_burst = 0
    with open(path, "r") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=';')
        for row in csv_reader:
            if(rounds >= total):
                break
            else:
                if(int(row[col_bool]) == 1): # CDF Operation
                    if(bool_burst > 0):
                        rounds += 1
                        bool_burst = 0
                    rounds += 1
                    bits += get_bits(row[col_nsyms], row[col_bool])
                else:   # Boolean Operation
                    bits += get_bits(row[col_nsyms], row[col_bool])
                    bool_burst += 1
                    if(bool_burst >= get_arc_bool(arc)):
                        rounds += 1
                        bool_burst = 0
    if(rounds < total):
        status = False
    else:
        status = True
    return status, rounds, bits

def run_simulation(arc, paths):
    data = []
    total_rounds = (sim_time_us*1000)/period_ns
    for path in tqdm(paths):
        status, rounds, bits = analyze_video(arc, total_rounds, path[3])
        # Status will indicate if no problem occurred during the analysis
        # Possible problems:
            # Less rounds in the file than the necessary
        data.append((path[0], path[1], path[2], bits, rounds))
        if(not status):
            tqdm.write(color.RED + "\tERROR: problem with file " + path[3] +
                        color.END)
        else:
            tqdm.write(color.GREEN + "\tSuccessfully done with " + path[3] +
                        color.END)
    return data

def top_function():
    paths = create_paths()
    print(color.HEADER + ("-" * 50) + color.END)
    for arc in arcs:
        print(color.HEADER + "Running analyzes for architecture " +
                get_arc_name(arc) + color.END)
        results = run_simulation(arc, paths)
        create_csv(get_arc_name(arc), results)
        print(color.HEADER + ("-" * 50) + color.END)

top_function()
