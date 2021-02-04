import csv
import random

flag_file_creation = 1  # this flag is used to create a new file or reset an existing one to avoid saving 2 frames in the same file
                        # It starts with one identifying that it is necessary to create a new file
print_interval_searching = 100      # this value will be used in an IF statement with the equation: if((line_counter % print_internal) == 0): print
print_interval_saving = 10      # Saving process is slower than searching, therefore it isn't required to wait long until print

TARGET_FRAME = 5        # choose a frame to be saved in another file. This variable must be set as a number within range 1-120
                        # The first frame of the video will always be expressed by 1 and the last one will variate
                        # If TARGET_FRAME presents a number greater than max. frames, no frame will be saved and an error message will be shown

VIDEO_NAME = "Beauty_1920x1080_120fps_420_8bit_YUV_cq55_main_data"             # Fill up this variable with the file name of the video target
                            # This variable will also be used to compose the output file's name
                            # Output file's name: NEW_FILE = VIDEO_NAME + "_" + str(TARGET_FRAME)

ORIGINAL_FILE_PATH = "F:/y4m_files/generated_files/cq_55"       # Path that takes to the folder of the original file
                                                                # The full path for the video file is: ORIGINAL_FILE_PATH + "/" + VIDEO_NAME
DEST_FILE_PATH = "F:/y4m_files/generated_files/cq_55/1-frame_files"         # This variables will identify the destination path for the video file created
                                                                            # The full path will be: DEST_FILE_PATH + "/" + NEW_FILE


def check_reset(last_range, current_range, current_low):
    if((last_range != current_range) and (int(current_range) == 32768) and (int(current_low) == 0)):
        return 1
    else:
        return 0

def save_file(row):
    global flag_file_creation
    if(flag_file_creation):
        flag_file_creation = 0
        with open(DEST_FILE_PATH + "/" + VIDEO_NAME + "_" + str(TARGET_FRAME) + ".csv", "w+", newline='') as dest_file:
            dest_writer = csv.writer(dest_file, delimiter=";")
            dest_writer.writerow(row)
    else:
        with open(DEST_FILE_PATH + "/" + VIDEO_NAME + "_" + str(TARGET_FRAME) + ".csv", "a+", newline='') as dest_file:
            dest_writer = csv.writer(dest_file, delimiter=";")
            dest_writer.writerow(row)




with open(ORIGINAL_FILE_PATH + "/" + VIDEO_NAME + ".csv", "r+") as org_file:
    flag_file_creation = 1
    org_reader = csv.reader(org_file, delimiter=";")
    frames_counter = 0      # Starts with zero because the first
    line_counter = 0
    prev_range = 0
    TARGET_FRAME = random.randrange(1,120)
    print("Looking for frame " + str(TARGET_FRAME))
    for row in org_reader:
        if(frames_counter < TARGET_FRAME):
            if((line_counter % print_interval_searching) == 0):
                print("Frame counter: " + str(frames_counter) + "\tLine: " + str(line_counter), end='\r')
            line_counter += 1
            if(check_reset(prev_range, row[1], row[2]) == 1):
                print("Reset")
                line_counter = 0
                frames_counter += 1
                if(frames_counter == TARGET_FRAME):     # The line that detects the reset is also the first line of the frame
                    save_file(row)
                    line_counter += 1
        else:
            line_counter += 1
            if((line_counter % print_interval_saving) == 0):
                print("Saving frame: " + str(frames_counter) + "\tLine: " + str(line_counter), end='\r')
            if(check_reset(prev_range, row[1], row[2]) != 1):
                save_file(row)
            else:
                quit()
        prev_range = row[9]
