# This script is able to generate the simulation files.
# Basically, a simulation file consists in several inputs and outputs, all in binary.
# The data inside a simulation file comes directly from the reference software for the AV1.

# In the first version of this generator, the output file will be composed by the following data:
    # Inputs:
        # FL
        # FH
        # Symbol (s)
        # Number of Symbols (nsyms)
    # Outputs:
        # Range
        # Low
# The Output data will be used to allow the system to find codification mistakes.
# Both output values will consider the numbers after the normalization.
# The width for the binary numbers in the simulation file will be exactly the same supported by the architecture.
    # 16 bits for FL and FH;
    # 4 bits for Symbol (s)
    # 5 bits for Number of Symbols (nsyms)
    # 16 bits for output range
    # 24 bits for output low

# The file created will have the format of CSV file.

# REQUIREMENTS FOR THE INPUT FILE FORMAT
    # Must be a CSV file;
    # May or may not have the column names (if so, the names won't be transfered to the output file);
    # The columns must to follow exactly the order below:
        # FL; FH; S; NSYMS; OUTPUT_LOW; OUTPUT_RANGE
    # The column separator MUST be a ;



import csv

original_file_path = "C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/decimal-csv-files/miss-video_10-rows.csv"
                                # Variable must to have a full valid path including the file name and format.
                                # The file format MUST be CSV.
                                # The first line can be filled with the column names or data.
destination_file_path = "C:/Users/Tulio/Desktop/arithmetic_encoder_av1/verification_area/simulation_data/miss-video_10-rows.csv"
                                # The destination path MUST include the file name and format.
                                # It's recommended to use the file format as CSV and specify in the path.
                                # This script will generate a CSV file with or without the .csv at the end of the name.

def padded_bin(i, width):
    s = "{0:b}".format(i)
    return s.zfill(width)

def create_dest_file(dest):
    file = open(dest, "w")
    file.close()

def add_to_file(dest, row):
    file = open(dest, "a")
    counter_column = 0
    for i in row:
        if(counter_column == 5):
            file.write(i + ";\n")
        else:
            file.write(i + ";")
        counter_column += 1
    file.close()

def convert_row(row):
    counter_column = 0
    for i in row:
        if((counter_column == 0) or (counter_column == 1) or (counter_column == 5)):       # FL, FH or output range
            row[counter_column] = padded_bin(int(i), 16)
        elif(counter_column == 2):                               # Symbol
            row[counter_column] = padded_bin(int(i), 4)
        elif(counter_column == 3):                               # Number of symbols (nsyms)
            row[counter_column] = padded_bin(int(i), 5)
        else:                                       # output low
            row[counter_column] = padded_bin(int(i), 24)
        counter_column += 1
    return row

with open(original_file_path) as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=';')
    line_counter = 0
    create_dest_file(destination_file_path)
    new_row = []
    for row in csv_reader:
        if(line_counter == 0):
            line_counter += 1
            if row[0].isnumeric():
                new_row = convert_row(row)
                add_to_file(destination_file_path, new_row)
        else:
            line_counter += 1
            new_row = convert_row(row)
            add_to_file(destination_file_path, new_row)
