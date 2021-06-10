import csv
import threading
import time

comp_file_path = "/home/tulio/Desktop/arithmetic-encoder-av1/verification_area/c-arithmetic-encoder-av1/output-files/original_bitstream.csv"
counter_comp = 0
comp_data = []

counter_ref = 0
ref_data = []
ref_file_path = "/media/tulio/HD1/y4m_files/generated_files/cq_20/Bosphorus_1920x1080_120fps_420_8bit_YUV_cq20_final_bitstream.csv"

monitor_off = 0

status = [0, 0]

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

class monitor(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
    def run(self):
        global monitor_off
        print("Reading files...")
        while(status[0] != 1 and status[1] != 1):
            print("\tRef: " + str(counter_ref) + ", Comp: " + str(counter_comp), end='\r')
        monitor_off = 1


class read_files(threading.Thread):
    def __init__(self, op):
        threading.Thread.__init__(self)
        self.op = op
    def run(self):
        global comp_data, ref_data, counter_comp, counter_ref
        if(self.op == 1):
            # Read the Comp File
            with open(ref_file_path, "r") as ref_file:
                ref_reader = csv.reader(ref_file, delimiter=';')
                for row in ref_reader:
                    ref_data.append(row[0])
                    counter_ref += 1
            status[1] = 1
        else:
            # Read the Ref File
            with open(comp_file_path, "r") as comp_file:
                comp_reader = csv.reader(comp_file, delimiter=';')
                for row in comp_reader:
                    comp_data.append(row[0])
                    counter_comp += 1
            status[0] = 1

thread_ref = read_files(0)
thread_comp = read_files(1)
monitor_off = 0
thread_monitor = monitor()
thread_monitor.start()
thread_ref.start()
thread_comp.start()

while(monitor_off != 1):
    time.sleep(1)
print("\n\t-> Done reading files.")
print(bcolors.HEADER + bcolors.BOLD + "\n----------------------------------" + bcolors.ENDC)
if(counter_comp != counter_ref):
    print(bcolors.FAIL + bcolors.BOLD + "\nCounters don't match!")
    print("\t-> Ref: " + str(counter_ref) + "\n\t-> Comp: " + str(counter_comp)  + bcolors.ENDC)
else:
    for i in range(0,counter_comp):
        if(comp_data[i] != ref_data[i]):
            print(bcolors.FAIL + bcolors.BOLD + "\nData doesn't match!")
            print("\t-> i = " + str(i))
            print("\t-> Ref: " + str(ref_data[i]) + "\n\t-> Comp: " + str(comp_data[i]) + bcolors.ENDC)
            quit()

    print(bcolors.OKGREEN + bcolors.BOLD + "\t\tFiles match!" + bcolors.ENDC)
    print(bcolors.HEADER + bcolors.BOLD + "----------------------------------" + bcolors.ENDC)
