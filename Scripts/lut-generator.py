import os

BINARY_WIDTH = 16       # change this value will change the number of bits generated in each memory position
file_type = 2             # define the type of file to be generated
                        # 1- for .mif; 2- verilog; 3- for .mem

def padded_bin(i, width):
    s = "{0:b}".format(i)
    return s.zfill(width)

def verilog_file_creation(lut):
    if not os.path.exists("../lut/"):
        os.makedirs("../lut/")
    if(lut == 1):
        file = open("../lut/lut_u.v", "w+")
    else:
        file = open("../lut/lut_v.v", "w+")
    file.close()

def verilog_file(lut, index, value):
    if(lut == 1):
        file = open("../lut/lut_u.v", "a+")
    else:
        file = open("../lut/lut_v.v", "a+")
    file.write("(addr == " + str(index) + ") ? 16'd" + str(value) + " : \n")
    file.close()

def verilog_file_final(lut):
    if(lut == 1):
        file = open("../lut/lut_u.v", "a+")
    else:
        file = open("../lut/lut_v.v", "a+")
    file.write("16'd0;")
    file.close()

def mif_creation(lut):
    if not os.path.exists("../lut/"):
        os.makedirs("../lut/")
    if (lut == 1):  # lut_u
        file = open("../lut/lut_u.mif", "w+")
    else:
        file = open("../lut/lut_v.mif", "w+")
    file.write("WIDTH=8;\nDEPTH=256;\n\nADDRESS_RADIX=UNS.\nDATA_RADIX=BIN;\n\nCONTENT BEGIN\n")
    file.close()

def mem_creation(lut):              # just add the numbers sequentialy
    if not os.path.exists("../lut/"):
        os.makedirs("../lut/")
    if (lut == 1):  # lut_u
        file = open("../lut/lut_u.mem", "w+")
    else:
        file = open("../lut/lut_v.mem", "w+")
    file.close()

def mif_insertion(lut, index, bin):
    if (lut == 1):  # lut_u
        file = open("../lut/lut_u.mif", "a+")
    else:
        file = open("../lut/lut_v.mif", "a+")
    file.write("\t" + str(index) + "\t:\t" + bin + ";\n")
    if(index == 255):
        file.write("END;\n")
    file.close()

def mem_insertion(lut, hex_value):
    if (lut == 1):  # lut_u
        file = open("../lut/lut_u.mem", "a")
    else:
        file = open("../lut/lut_v.mem", "a")
    file.write(hex_value + "\n")
    file.close()

def lut_u(def_file):
    count = -1
    if(def_file == 1):
        mif_creation(1)        # creating file U
    elif(def_file == 2):
        verilog_file_creation(1)
    else:
        mem_creation(1)
    for N in range(0,16):
        for s in range(0,16):
            value = 4 * (N - (s - 1))
            if(s > N):
                value = 0
            bin_value = padded_bin(value, BINARY_WIDTH)
            hex_value = format(value, 'x')
            count += 1
            #print(str(N) + "," + str(s) + " -> " + str(value) + " - " + bin_value)
            if(def_file == 1):
                mif_insertion(1, count, bin_value)
            elif(def_file == 2):
                if(value != 0):
                    verilog_file(1, count, value)
            else:
                mem_insertion(1, hex_value)
    verilog_file_final(1)
    if(def_file == 1):
        print("Mif file U created.")
    elif(def_file == 2):
        print("Verilog file V created.")
    else:
        print("Mem file U created.")

def lut_v(def_file):
    count = -1
    if(def_file == 1):
        mif_creation(2)        # creating file V
    elif(def_file == 2):
        verilog_file_creation(2)
    else:
        mem_creation(2)
    for N in range(0,16):
        for s in range(0,16):
            value = 4 * (N - (s + 0))
            if(s > N):
                value = 0
            bin_value = padded_bin(value, BINARY_WIDTH)
            hex_value = format(value, 'x')
            count += 1
            #print("-> " + str(count) + " " + str(N) + "," + str(s) + " -> " + str(value) + " - " + bin_value)
            if(def_file == 1):
                mif_insertion(2, count, bin_value)
            elif(def_file == 2):
                if(value != 0):
                    verilog_file(2, count, value)
            else:
                mem_insertion(2, hex_value)
    verilog_file_final(2)
    if(def_file == 1):
        print("Mif file V created.")
    elif(def_file == 2):
        print("Verilog file V created.")
    else:
        print("Mem file V created.")

lut_u(file_type)
lut_v(file_type)
