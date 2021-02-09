import csv


range = []
other = []
print_rate = 1

def check(r, f, gen_count):
    global range
    global other
    if(gen_count > 0):
        i = 0
        while(i < gen_count):
            if((range[i] == r) and (other[i] == f)):
                return gen_count
            i += 1
    range.append(int(r))
    other.append(int(f))
    return gen_count+1

with open("output-files/mult_inputs_2.csv", "r+") as csv_file:
    csv_read = csv.reader(csv_file, delimiter=';')
    counter = 0
    comps = 0
    for row in csv_read:
        comps += 1
        if((comps%print_rate) == 0):
            print("Different combinations: " + str(counter) + "\tComparisons: " + str(comps) +  "\tR: " + row[0] + "\tOther: " + row[1], end='\r')
        counter = check(int(row[0]), int(row[1]), counter)
