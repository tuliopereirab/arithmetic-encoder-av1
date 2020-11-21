# The main goal of this code is to analyze the throughput of the architecture

# As the architecture executes one input set per cycle, this script will check how many bits are being generate per cycle
# For that, it was defined an specific number of bits according to the n_syms input:
    # nsyms = 2                                 : 1 bit
    # nsyms = 3, 4                              : 2 bits
    # nsyms = 5, 6, 7, 8                        : 3 bits
    # nsyms = 9, 10, 11, 12, 13, 14, 15, 16:    : 4 bits


import csv
import sys
import time

import threading


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
        num_bits = 0
        num_cycles = 0
        global general_num_cycles
        global general_num_bits
        with open(self.path_file) as video_file:
            video_reader = csv.reader(video_file, delimiter=';')
            for row in video_reader:
                num_cycles += 1
                num_bits += analyze_input(int(row[6]), int(row[0]))
                sem_var.acquire()
                general_num_bits += analyze_input(int(row[6]), int(row[0]))
                general_num_cycles += 1
                sem_var.release()
                # print(self.name + " -> " + str(num_cycles), end = '\r')
                if(analyze_input(int(row[6]), int(row[0])) < 0):
                    print("Error, thread " + str(threadID) + " stopped.")
                    sys.exit()
            sem_file.acquire()
            save_file(self.video_name, self.cq_def, num_bits, num_cycles)
            sem_file.release()
            print("\n================\n -> " + self.name + " is done\n -> Video: " + self.video_name + " - " + self.cq_def + "\n================\n")

def video_name(option):
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
    # elif(option == 5):
    #     return "Beauty 1920x1080 120fps 420 8bit YUV"

def save_file(video_name, cq_def, num_bits, num_cycles):
    file_path_save = "/media/tulio/HD1/y4m_files/generated_files/" + cq_def + "_statistics"
    file = open(file_path_save, "a")
    file.write("Video: " + str(video_name) + "\n")
    file.write("Total bits: " + str(num_bits) + "\nTotal Cycles: " + str(num_cycles) + "\nBits/cycle: " + str(check_final_data(num_bits, num_cycles)))
    file.write("\n==============================================\n")
    file.close()


def get_path_file(option, cq_def):
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
    # elif(option == 5):
    #     return "Beauty_1920x1080_120fps_420_8bit_YUV_cq20_main_data.csv"


def analyze_input(nsyms, bool):
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
    return bits/cycles


my_threads = []
counter = 0

f = open("/media/tulio/HD1/y4m_files/generated_files/cq55_statistics", "w+")
f.close()
f = open("/media/tulio/HD1/y4m_files/generated_files/cq20_statistics", "w+")
f.close()
for i in range(0,5):
    for j in range(0,2):
        if(j == 0):
            cq_def = "cq20"
            path_video_file = "/media/tulio/HD1/y4m_files/generated_files/cq_20/" + get_path_file(i, cq_def)
        else:
            cq_def = "cq55"
            path_video_file = "/media/tulio/HD1/y4m_files/generated_files/cq_55/" + get_path_file(i, cq_def)
        thread = myThread(counter, "Thread " + str(counter), path_video_file, video_name(i), cq_def)
        thread.start()
        my_threads.append(thread)
        counter += 1

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
print("\n   ====================")
print("\t-> Total cycles: " + str(general_num_cycles))
print("\t-> Total bits: " + str(general_num_bits))
print("\t-> Bits per cycles: " + str(check_final_data(general_num_bits, general_num_cycles)))
print("====================")
