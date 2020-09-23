BINARY_WIDTH = 16       # change this value will change the number of bits generated in each memory position


def padded_bin(i, width):
    s = "{0:b}".format(i)
    return s.zfill(width)

def mif_creation(lut):
    if (lut == 1):  # lut_u
        file = open("lut_u.mif", "w")
    else:
        file = open("lut_v.mif", "w")
    file.write("WIDTH=8;\nDEPTH=256;\n\nADDRESS_RADIX=UNS.\nDATA_RADIX=BIN;\n\nCONTENT BEGIN\n")
    file.close()

def mem_creation(lut):              # just add the numbers sequentialy
    if (lut == 1):  # lut_u
        file = open("lut_u.mem", "w")
    else:
        file = open("lut_v.mem", "w")
    file.close()

def mif_insertion(lut, index, bin):
    if (lut == 1):  # lut_u
        file = open("lut_u.mif", "a")
    else:
        file = open("lut_v.mif", "a")
    file.write("\t" + str(index) + "\t:\t" + bin + ";\n")
    if(index == 255):
        file.write("END;\n")
    file.close()

def mem_insertion(lut, hex_value):
    if (lut == 1):  # lut_u
        file = open("lut_u.mem", "a")
    else:
        file = open("lut_v.mem", "a")
    file.write(hex_value + "\n")
    file.close()

def lut_u():
    count = -1
    mem_creation(1)
    mif_creation(1)        # creating file U
    for N in range(0,16):
        for s in range(0,16):
            value = 6 * (N - (s - 1))
            if(s > N):
                value = 0
            bin_value = padded_bin(value, BINARY_WIDTH)
            hex_value = format(value, 'x')
            count += 1
            print(str(N) + "," + str(s) + " -> " + str(value) + " - " + bin_value)
            mem_insertion(1, hex_value)
            mif_insertion(1, count, bin_value)

def lut_v():
    count = -1
    mem_creation(2)
    mif_creation(2)        # creating file V
    for N in range(0,16):
        for s in range(0,16):
            value = 6 * (N - (s + 0))
            if(s > N):
                value = 0
            bin_value = padded_bin(value, BINARY_WIDTH)
            hex_value = format(value, 'x')
            count += 1
            print("-> " + str(count) + " " + str(N) + "," + str(s) + " -> " + str(value) + " - " + bin_value)
            mem_insertion(2, hex_value)
            mif_insertion(2, count, bin_value)

lut_u()
lut_v()
