import csv

comp_file_path = "/home/tulio/Desktop/arithmetic-encoder-av1/verification_area/c-arithmetic-encoder-av1/output-files/original_bitstream.csv"
counter_comp = 0
comp_data = []

counter_ref = 0
ref_data = []
ref_file_path = "/media/tulio/HD1/y4m_files/generated_files/cq_20/Bosphorus_1920x1080_120fps_420_8bit_YUV_cq20_final_bitstream.csv"

with open(ref_file_path, "r") as ref_file:
    print("Starting with Ref File")
    ref_reader = csv.reader(ref_file, delimiter=';')
    for row in ref_reader:
        ref_data.append(row[0])
        counter_ref += 1
        print("\t-> Ref Counter = " + str(counter_ref), end='\r')
with open(comp_file_path, "r") as comp_file:
    print("\nStarting with Comp File")
    comp_reader = csv.reader(comp_file, delimiter=';')
    for row in comp_reader:
        comp_data.append(row[0])
        counter_comp += 1
        print("\t-> Comp Counter = " + str(counter_comp), end='\r')

print("\n----------------------------------")
if(counter_comp != counter_ref):
    print("\nCounters don't match!")
    print("\t-> Ref: " + str(counter_ref) + "\n\t-> Comp: " + str(counter_comp))
else:
    for i in range(0,counter_comp):
        if(comp_data[i] != ref_data[i]):
            print("\nData doesn't match!")
            print("\t-> i = " + str(i))
            print("\t-> Ref: " + str(ref_data[i]) + "\n\t-> Comp: " + str(comp_data[i]))
            quit()
    print("Files match!")
