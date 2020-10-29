# This script will be responsible for converting the Decimal output for the final bitstream coming out of the AV1 reference code
# to a binary sequencial file, with all the bits arranged in the same line and representing the decimal numbers

import csv

BINARY_WIDTH = 8

decimal_file_bitstream = "C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/c-arithmetic-encoder-av1/test_1.csv"

binary_file_bitstream = "C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/c-arithmetic-encoder-av1/test_2.csv"


def padded_bin(i, width):
    s = "{0:b}".format(i)
    return s.zfill(width)

def create_dest_file(dest):
    file = open(dest, "w+")
    file.close()

def add_to_file(dest, value):
    file = open(dest, "a")
    file.write(value)
    file.close()


with open(decimal_file_bitstream) as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=';')
    line_counter = 0
    create_dest_file(binary_file_bitstream)
    for row in csv_reader:
        print(row[0])
        add_to_file(binary_file_bitstream, padded_bin(int(row[0]), int(BINARY_WIDTH)))
