# This script combines all columns from a CSV file 1 (csv1) with a target
# column from a CSV file 2 (csv2)

# Requirements:
    # The csv files must be EQUAL in all columns but the target in csv2;
    # The csv files must have the SAME number of rows;

# No checking is done to ensure both files match in data, only column and row
# numbers.

# Configuration
    # The configulation is quite messy, but the idea is to ensure that function
    # 'mixer()' receives data from both files and the target column in csv2.

    # Functions main_loop() and mix_csv() basically open both csv1 and csv2
    # files, get the data from them using get_data(), and send both dataset into
    # mixer() to be mixed.

    # mixer() function will take both datasets + target_column and pass,
    # row-by-row, all data from csv1 and the target_column from csv2.

    # The entire and final_data will then be sent into save_csv() to be stored
    # in a given result according to the definition set in mix_csv()

import csv
import os.path
from tqdm import tqdm

folders = ["MB-Mercat", "MB-objective-2"]
versions = ["", "-LP"]
arcs = ["1-bool", "2-bool", "3-bool"]
files = ["tcf", "power"]
target_column = [4, 4]


main_path = "/home/tulio/Downloads/new_sheets"
dest_path = "/home/tulio/Downloads/new_sheets/Final_Result"

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


def check_paths():
    global main_path, dest_path
    if(main_path[-1] != "/"):
        print(color.YELLOW + "\t-> WARNING: Added '/' to 'main_path'." +
                color.END)
        main_path += "/"
    if(dest_path[-1] != "/"):
        print(color.YELLOW + "\t-> WARNING: Added '/' to 'dest_path'." +
                color.END)
        dest_path += "/"
    status = True
    print(color.HEADER + "-> Path checking..." + color.END)
    for folder in folders:
        for version in versions:
            for arc in arcs:
                for file in files:
                    full_path = main_path + folder + version + "/" + arc
                    if("LP" in version):
                        full_path += "_lp" + "_" + file + ".csv"
                    else:
                        full_path += "_" + file + ".csv"
                    if(os.path.exists(full_path)):
                        print(color.GREEN + "\t-> Exists: " + full_path + color.END)
                    else:
                        status = False
                        print(color.RED + "\t-> ERROR: " + full_path + color.END)
    if(not status):
        print(color.RED + "ERROR: One file not found."+ color.END)
    return status

def get_data(path):
    data = []
    with open(path, "r") as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        for row in csv_reader:
            data.append(row)
    return data

def get_target_col_index(file):
    count = 0
    for i in files:
        if(file != i):
            count += 1
        else:
            break
    return count

def mixer(data1, data2, target_col):
    numrow1 = len(data1)
    numrow2 = len(data2)
    numcol1 = len(data1[0])
    numcol2 = len(data2[0])
    if(numcol2 < target_col):
        print(color.RED + "ERROR: Invalid target column." + color.END)
        return False, []
    if(numrow1 != numrow2):
        print(color.RED + "ERROR: Invalid number of rows." + color.END)
        return False, []
    final_data = []
    status_data = []
    for index in range(numrow1):
        temp_row = []
        for j in data1[index]:
            temp_row.append(j.replace(" ", "").replace(";", ""))
        temp_row.append(data2[index][target_col].replace(" ", "").replace(";", ""))
        status_data.append(status)
        final_data.append(temp_row)
    final_status = True
    for i in status_data:
        if(not i):
            final_status = False
    return final_status, final_data


def mix_csv(folder, arc, file):
    path_v0 = main_path + folder + versions[0] + "/" + arc + "_" + file + ".csv"
    path_v1 = main_path + folder + versions[1] + "/" + arc
    path_v1 += "_lp" + "_" + file + ".csv"
    data_v0 = get_data(path_v0)
    data_v1 = get_data(path_v1)
    target_col_index = get_target_col_index(file)
    return mixer(data_v0, data_v1, target_column[target_col_index])

def save_csv(data, folder, arc, file):
    path = dest_path + folder + "-" + arc + "_" + file + ".csv"
    with open(path, "w") as csv_file:
        csv_writer = csv.writer(csv_file)
        for i in data:
            csv_writer.writerow(i)

def main_loop():
    for folder in tqdm(folders):
        for arc in arcs:
            for file in files:
                status, data = mix_csv(folder, arc, file)
                if(not status):
                    tqdm.write(color.RED + "\tERROR: " + folder + " " + arc +
                            " " + file + color.END)
                else:
                    save_csv(data, folder, arc, file)
                    tqdm.write(color.GREEN + "\tDone: " + folder + " " + arc
                            + " " + file + color.END)

status = check_paths()
if not status:
    quit()
print(color.HEADER + ("-" * 50) + color.END)
main_loop()
