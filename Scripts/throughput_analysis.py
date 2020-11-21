# The main goal of this code is to analyze the throughput rate of the architecture
# The idea is to check the number of symbols encoded in each cycle and guess the number of bits being generated
# The table explaining exactly the relaction between nsyms and bits generated is below
# This script uses N threads for the execution, where N is the number of videos being analyzed

# As the architecture executes one input set per cycle, this script will check how many bits are being generate per cycle
# For that, it was defined an specific number of bits according to the n_syms input:
# nsyms = 2                                 : 1 bit
# nsyms = 3, 4                              : 2 bits
# nsyms = 5, 6, 7, 8                        : 3 bits
# nsyms = 9, 10, 11, 12, 13, 14, 15, 16:    : 4 bits

# ===================================================
# How to run:
    # At first, it's necesasry to define the number of videos (num_videos)
    # At second, it's necessary to define the path taking to the cq_20 and cq_55 folders
    # At third, edit the functions get_path_file and video_name
        # For get_path_file, update the name of the video file (the one generated with the AV1's reference software)
            # It is necessary to change the original aom/aom_dsp/entenc.c file and add the modified one available on this project
                # The path for the modified file is: /arithmetic-encoder-av1/verification_area/AV1-reference
                # In the same folder there is also a script .sh that helps with the execution generation of the files
        # On the second function, just update the name of the videos that are being analyzed
            # As the video_name function will be used only to present the video, the name can be anyone
    # And that's it. After doing everything, it is possible to execute the script and expected to get the statistics saved into files
# ===================================================


import csv
import sys
import time

import threading

num_videos = 6  # set the number of videos to be analyzed with this script
main_path_files = "/media/tulio/HD/y4m_files/generated_files/"     # set the main path
                                                                    # In this path, it must be possible to find the folders cq_55 and cq_20

general_num_bits = 0
general_num_cycles = 0

sem_var = threading.BoundedSemaphore(1)
sem_file = threading.BoundedSemaphore(1)

class myThread (threading.Thread):
    def __init__(self, threadID,name,path_file,video_name, cq_def):
        threading.Thread.__init__(self)
        self.threadID = threadID
        self.name = name
        self.path_file = path_file
        self.video_name = video_name
        self.cq_def = cq_def
    def run(self):
        # Here is where the magic happens
        # The video files will be analyzed here
        # The statistics will be updated here and all other functions will be called from here
        # For saving data into the global variables, this code uses semaphores
        # At the end of execution, each thread prints its ID (name) and the name of the video
        num_bits = 0
        num_cycles = 0
        temp_add_bits = 0
        global general_num_cycles
        global general_num_bits
        with open(self.path_file) as video_file:
            video_reader = csv.reader(video_file, delimiter=';')
            for row in video_reader:
                num_cycles += 1
                temp_add_bits = analyze_input(int(row[6]), int(row[0]))
                num_bits += temp_add_bits
                sem_var.acquire()
                general_num_bits += temp_add_bits
                general_num_cycles += 1
                sem_var.release()
                # print(self.name + " -> " + str(num_cycles), end = '\r')
                if(temp_add_bits < 0):
                    print("Error, thread " + str(threadID) + " stopped.")
                    sys.exit()
            sem_file.acquire()
            save_file(self.video_name, self.cq_def, num_bits, num_cycles)
            sem_file.release()
            print("\n================\n -> " + self.name + " is done\n -> Video: " + self.video_name + " - " + self.cq_def + "\n================\n")


def save_file(video_name, cq_def, num_bits, num_cycles):
    # This function adds to the statistics file the statistics related to the video
    # Every time a thread is done with the analysis, this function is called
    # The thread will then send the final data (num bits and num cycle) and this function will add to the right file
    # This function is also used to write into the final statistics file
    file_path_save = main_path_files + "statistics/" + cq_def + "_statistics"
    file = open(file_path_save, "a")
    file.write("Video: " + str(video_name) + " - " + str(cq_def) + "\n")
    file.write("Total bits: " + str(num_bits) + "\nTotal Cycles: " + str(num_cycles) + "\nBits/cycle: " + str(check_final_data(num_bits, num_cycles)))
    file.write("\n==============================================\n")
    file.close()

def video_name(option):
    # This function basically returns the name of the video
    if(option == 0):
        return "Beauty 1920x1080 120fps 420 8bit YUV"
    elif(option == 1):
        return "Bosphorus 1920x1080 120fps 420 8bit YUV"
    elif(option == 2):
        return "HoneyBee 1920x1080 120fps 420 8bit YUV"
    elif(option == 3):
        return "Jockey 1920x1080 120fps 420 8bit YUV"
    elif(option == 4):
        return "ReadySetGo 3840x2160 120fps 420 10bit YUV"
    elif(option == 5):
        return "YachtRide 3840x2160 120fps 420 10bit YUV"

def get_path_file(option, cq_def):
    # Here is being centralized all the video paths in order to facilitate the access when other functions need
    # All new videos must be added here before analyze
    #print("Analyzing video: " + video_name(option))
    if(option == 0):
        return "Beauty_1920x1080_120fps_420_8bit_YUV_" + cq_def + "_main_data.csv"
    elif(option == 1):
        return "Bosphorus_1920x1080_120fps_420_8bit_YUV_" + cq_def + "_main_data.csv"
    elif(option == 2):
        return "HoneyBee_1920x1080_120fps_420_8bit_YUV_" + cq_def + "_main_data.csv"
    elif(option == 3):
        return "Jockey_1920x1080_120fps_420_8bit_YUV_" + cq_def + "_main_data.csv"
    elif(option == 4):
        return "ReadySetGo_3840x2160_120fps_420_10bit_YUV_" + cq_def + "_main_data.csv"
    elif(option == 5):
        return "YachtRide_3840x2160_120fps_420_10bit_YUV_" + cq_def + "_main_data.csv"


def analyze_input(nsyms, bool):
    # This function's goal is to set the right number of bits according to the input values
    if((bool == 0) or (nsyms <= 2)):        # using function bool, which means that there are only 2 symbols
        return 1
    elif((bool == 1) and (nsyms > 2) and (nsyms <= 4)):
        return 2
    elif((bool == 1) and (nsyms > 4) and (nsyms <= 8)):
        return 3
    elif((bool == 1) and (nsyms > 8) and (nsyms <= 16)):
        return 4
    else:
        return -1

def check_final_data(bits, cycles):
    # This function basically returns the rate bits/cycle
    return bits/cycles



# ===============================
# Below this point is the main part of the code
# Here is where the files are created (or overwritten in order to delete all other data the can be inside)
# The threads are also created here and each one of them receives the right video to analyze
# Also, this part of the code prints the total number of bits and cycles already analyze by all threads
    # This print happens according to a pre-defined interval time
# At last, this code also shows the overall statistics for all videos executed and calls the save_file function


my_threads = []
counter = 0

# reset the output files (create new empty files)
f = open(main_path_files + "statistics/cq55_statistics", "w+")
f.close()
f = open(main_path_files + "statistics/cq20_statistics", "w+")
f.close()
f = open(main_path_files + "statistics/final_statistics", "w+")
f.close()

# run for the correct number of videos available
for i in range(0,num_videos):
    for j in range(0,2):
        if(j == 0):
            cq_def = "cq20"
            path_video_file = main_path_files + "cq_20/" + get_path_file(i, cq_def)
        else:
            cq_def = "cq55"
            path_video_file = main_path_files + "cq_55/" + get_path_file(i, cq_def)
        thread = myThread(counter, "Thread " + str(counter), path_video_file, video_name(i), cq_def)
        thread.start()
        my_threads.append(thread)
        counter += 1


# Always when there's at least one thread running, the script will print the total cycles and total bits
something_running = 1
while(something_running == 1):
    time.sleep(.05)
    something_running = 0
    num_alive = 0
    for t in my_threads:
        if t.is_alive():
            num_alive += 1
            something_running = 1
    # print("General cycles: " + str(general_num_cycles), end = '\r')
    if(general_num_cycles > 0):
        print("Threads alive: " + str(num_alive) + " -> Total cycles: " + str(general_num_cycles) + "\t\t\t Total Bits: " + str(general_num_bits) + "\t\t\t Bits/Cycle: " + str(check_final_data(general_num_bits, general_num_cycles)) + " ", end = '\r')

# Final print showing the overall statistics
# These statistics are related to all videos analyzed during the execution
# Each thread updates the total number of bits and cycles when necessary
print("\n   ====================")
print("\t-> Total cycles: " + str(general_num_cycles))
print("\t-> Total bits: " + str(general_num_bits))
print("\t-> Bits per cycles: " + str(check_final_data(general_num_bits, general_num_cycles)))
print("====================")
sem_file.acquire()
save_file("Final", "final", general_num_bits, general_num_cycles)
sem_file.release()
