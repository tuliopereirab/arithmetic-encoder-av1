# The main goal of this code is to analyze the throughput of the architecture

# As the architecture executes one input set per cycle, this script will check how many bits are being generate per cycle
# For that, it was defined an specific number of bits according to the n_syms input:
    # nsyms = 2                                 : 1 bit
    # nsyms = 3, 4                              : 2 bits
    # nsyms = 5, 6, 7, 8                        : 3 bits
    # nsyms = 9, 10, 11, 12, 13, 14, 15, 16:    : 4 bits


import csv
import sys

num_bits = 0
num_cycles = 0

def video_name(option):
    if(option == 1):
        return "HoneyBee 1920x1080 120fps 420 8bit YUV YUV"
    elif(option == 2):
        return "Miss America 150 frames 176x144"

def get_path_file(option):
    print("Analyzing video: " + video_name(option))
    if(option == 1):
        return "/media/tulio/HD/simulation_data_bitstream/HoneyBee_1920x1080_120fps_420_8bit_YUV_YUV_main_data.csv"
    elif(option == 2):
        return "/media/tulio/HD/simulation_data_bitstream/miss-america_150frames_176x144_main_data.csv"


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


path_video_file = get_path_file(2)

with open(path_video_file) as video_file:
    video_reader = csv.reader(video_file, delimiter=';')
    num_bits = 0
    num_cycles = 0
    for row in video_reader:
        num_cycles += 1
        num_bits += analyze_input(int(row[6]), int(row[0]))
        print("Number of cycles: " + str(num_cycles) + "\t\t\tNumber of Bits: " + str(num_bits), end = '\r')
        if(analyze_input(int(row[6]), int(row[0])) < 0):
            print("Error, system stopped.")
            sys.exit()
    print("\n   ====================")
    print("Final data: " + video_name(2))
    print("\t-> Total cycles: " + str(num_cycles))
    print("\t-> Total bits: " + str(num_bits))
    print("\t-> Bits per cycles: " + str(check_final_data(num_bits, num_cycles)))
    print("====================")
