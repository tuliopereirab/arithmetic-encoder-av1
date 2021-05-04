import csv
import platform
from os import listdir
from os.path import isfile, join


linux_path_folder = "/home/tulio/Desktop/lp_analysis/input_data/cq_55"
onlyfiles = [f for f in listdir(linux_path_folder) if isfile(join(linux_path_folder, f))]


windows_path = ""

# Variables for analysis
total = 0
boolean_counter = 0

for i in onlyfiles:
    if(platform.system() == "Windows"):
        path = windows_path
    else:
        path = linux_path_folder + "/" + i

    print("File: " + i)

    with open(path, "r+") as file:
        fread = csv.reader(file, delimiter=';')
        for row in fread:
            total += 1
            if(row[0] == '0'):
                boolean_counter += 1
            if((total % 100000) == 0):
                print("Boolean: " + str(round((boolean_counter/total)*100,2)) + "%\tTotal: " + str(total), end='\r')
    print("\n-------------\nFinal:\n\t-> % Boolean: " + str(round((boolean_counter/total)*100,2)) + "%\n\t-> General Total: " + str(total) + "\n\t-> Total Boolean: " + str(boolean_counter))
    print("================================")
