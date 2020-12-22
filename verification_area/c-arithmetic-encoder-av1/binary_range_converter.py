# This script's goal is to convert the range_analyzer_file to binary

import csv

BINARY_WIDTH = 16

decimal_file_bitstream = "output-files/range_analyzer.csv"

binary_file_bitstream = "output-files/binary_range_analyzer.csv"


def padded_bin(i, width):
    s = "{0:b}".format(i)
    return s.zfill(width)

def create_dest_file(dest):
    file = open(dest, "w+")
    file.write("range_in; equation; fl; fh; u; v\n");
    file.close()

def add_to_file(dest, range_in, equation, fl, fh, u, v):
    file = open(dest, "a")
    file.write(range_in + ";" + equation + ";" + fl + ";" + fh + ";" + u + ";" + v + ";" + "\n")
    file.close()


with open(decimal_file_bitstream) as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=';')
    line_counter = 0
    create_dest_file(binary_file_bitstream)
    i = 0
    for row in csv_reader:
        if(i == 0):
            i += 1
        else:
            if(row[3] != "N/A" and row[4] != "N/A"):
                add_to_file(binary_file_bitstream, padded_bin(int(row[0]), 16), row[1], padded_bin(int(row[2]), 16), padded_bin(int(row[3]), 16), padded_bin(int(row[4]), 16), padded_bin(int(row[5]), 16))
            else:
                add_to_file(binary_file_bitstream, padded_bin(int(row[0]), 16), row[1], padded_bin(int(row[2]), 16), "N/A", "N/A", padded_bin(int(row[5]), 16))
