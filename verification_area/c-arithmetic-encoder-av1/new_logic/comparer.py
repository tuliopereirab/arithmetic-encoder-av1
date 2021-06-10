# This script goal is to compare the bitstream files generated from the original arithmetic encoder and the new logic (without multipliers)
# For that, it firstly reads both bitstream files (csv files with 8-bit bitstreams in each line and decimal) and converts it into binary code
# Then it compares each bit for each 8-bit bitstream.


import csv
import time
import threading

original_array = []
new_array = []

counter_original = 0
counter_new = 0

# Analysis
matches = 0
mismatches = 0
# --------------------

print_rate = 100
status = [0, 0]

first_path = "/home/tulio/Desktop/arithmetic-encoder-av1/verification_area/c-arithmetic-encoder-av1/output-files/"
original_bitstream_path = first_path + "original_bitstream.csv"
new_bitstream_path = first_path + "new_3_9_28.csv"

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class data_acquirement(threading.Thread):
    def __init__(self, op):
        threading.Thread.__init__(self)
        self.op = op
    def run(self):
        global counter_original, counter_new, status
        if(self.op > 1 or self.op < 0):
            print("ERROR: Operation index (op) invalid.")
            quit()
        else:
            if(self.op == 0):
                print("Reading ORIGINAL file...")
            else:
                print("Reading NEW file...")
            counter = acquire_data(int(self.op))
            if(self.op == 0):
                counter_original = counter
                print("Reading ORIGINAL file completed!")
            else:
                counter_new = counter
                print("Reading NEW file completed!")
            status[self.op] = 1

def analyzer():
    global matches, mismatches
    matches = 0
    mismatches = 0
    print("=============== Running Analysis ===============")
    if(counter_new == counter_original):
        print("\t-> Counters match!")
        max_lines = counter_new
    else:
        print("\t-> ERROR 0: Counters don't match.\tOriginal: " + str(counter_original) + "\tNew: " + str(counter_new))
        if(counter_new < counter_original):
            max_lines = counter_new
        else:
            max_lines = counter_original

    for i in range(0,max_lines):
        if((matches+mismatches) > 0 and ((matches+mismatches)%print_rate) == 0):
            print("\t" + str(round((matches/(matches+mismatches))*100, 5)) + "% of matches. \tMismatches: " + str(mismatches) + " \t Total bits analyzed: " + str(matches+mismatches), end='\r')
        for j in range(0,8):
            if(new_array[i][j] == original_array[i][j]):
                matches += 1
            else:
                mismatches += 1
    print_report()

def print_report():
    print(bcolors.HEADER + "\n=============== Final Report ===============" + bcolors.ENDC)
    if((matches+mismatches) > 0):
        print(bcolors.BOLD + bcolors.OKGREEN + "\t-> Match rate: " + str(round((matches/(matches+mismatches))*100 , 5)) + " %"  + bcolors.ENDC)
    else:
        print("\t-> ERROR: No bitstream analyzed.")
    print(bcolors.OKGREEN + "\t-> Total Matches: " + str(matches))
    print(bcolors.FAIL + "\t-> Total mismatches: " + str(mismatches) + bcolors.ENDC)
    print(bcolors.OKBLUE + "\t-> Counter Original: " + str(counter_original) + "\n\t-> Counter New: " + str(counter_new) + bcolors.ENDC)
    print(bcolors.HEADER + "=============== Done ===============\n" + bcolors.ENDC)




def padded_bin(i, width):
    s = "{0:b}".format(i)
    return s.zfill(width)

def acquire_data(op):
    if(op == 0):
        path = original_bitstream_path
    else:
        path = new_bitstream_path
    with open(path, "r") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=';')
        line_counter = 0
        for row in csv_reader:
            bin_data = padded_bin(int(row[0]), 8)
            if(op == 0):
                original_array.append(bin_data)
            else:
                new_array.append(bin_data)
            line_counter += 1
    return line_counter


status[0] = 0
status[1] = 0
thread_original = data_acquirement(0)
thread_new = data_acquirement(1)
thread_original.start()
thread_new.start()
counter_waiting = 0
while(status[0] != 1 or status[1] != 1):
    counter_waiting += 1
    print("Reading... " + str(counter_waiting), end='\r')
    time.sleep(1)
analyzer()
