# getRTPPM data
# Fred Shone 3/4/18

# Methods to extract RAG and proportion of train 'late' and 'very late/.cancelled' from RTPPM files
# Files assumed already downloaded and unzipped in parent directory
# Missing data is interpolated if possible (based on last recorded entry)

####################################################
#  Imports
import json
import datetime as dt
import pandas as pd
import sys

####################################################
# Define start and end dates
# Note that start_date = dt.datetime(2018, 2, 25, 22)

start_date = dt.datetime(2018, 2, 25)
end_date = dt.datetime(2018, 3, 27)

####################################################
# Functions


# Get TOC names
def get_names(list_in):
    names_out = []

    for operator in list_in:
        names_out.append(operator["Operator"]["name"])
        # print("N.")
    return names_out


# Get RAG status
def get_rag(names, list_in, t):
    rag_out = []
    rag_dict = {"R": 3, "A": 2, "G": 1, "W": 1}  # Note that "W" denotes missing value

    for operator in list_in:
        temp = operator["Operator"]["PPM"]["rag"]
        rag_out.append(rag_dict[temp])
    rag_out = pd.DataFrame({t: rag_out}, index=names)
    print("R.")
    return rag_out


# Get total trains
def get_total(names_in, list_in, t):
    total_out = []

    for operator in list_in:
        total = int(operator["Operator"]["Total"])
        total_out.append(total)
    total_out = pd.DataFrame({t: total_out}, index=names_in)
    print("T.")
    return total_out


# Get proportion delayed
def get_delayed(names_in, list_in, t):
    delayed_out = []

    for operator in list_in:
        total = int(operator["Operator"]["Total"])
        delayed = int(operator["Operator"]["Late"])
        if total == 0:
            temp = 0
        else:
            temp = delayed
        delayed_out.append(temp)
    delayed_out = pd.DataFrame({t: delayed_out}, index=names_in)
    print("L.")
    return delayed_out


# Get proportion cancelled
def get_cancelled(names_in, list_in, t):
    cancelled_out = []

    for operator in list_in:
        total = int(operator["Operator"]["Total"])
        cancelled = int(operator["Operator"]["CancelVeryLate"])
        if total == 0:
            temp = 0
        else:
            temp = cancelled
        cancelled_out.append(temp)
    cancelled_out = pd.DataFrame({t: cancelled_out}, index=names_in)
    print("C.")
    return cancelled_out


def merge_table(table_one, table_two):
    # if len(table_one) == 0:
    #     return table_two
    # else:
        try:
            table_out = pd.concat([table_one, table_two], axis=1)
            return table_out
        except:
            print('...Cannot merge.\n')
            return table_two


# Construct path for directory
def make_path(t, min_shift):
    t_shifted = t + dt.timedelta(minutes=min_shift)
    folder_ts = str(t_shifted.strftime("%Y-%m-%d"))
    file_ts = str(t_shifted.strftime("%Y%m%d%H%M"))
    return "rtppm-" + folder_ts + "/rtppm-" + file_ts + ".log"


# Open path, note that in the case of (pressumed) missing entries the code will try subsequent minutes up to 5:
def open_path(t, rag_table_in, total_table_in, delayed_table_in, cancelled_table_in):

    try:
        try:
            path = make_path(t, 0)
            print("Accessing: " + path)
            data = json.load(open(path))["RTPPMDataMsgV1"]["RTPPMData"]["OperatorPage"]
        except:

            try:
                path = make_path(t, 1)
                print("Accessing: " + path)
                data = json.load(open(path))["RTPPMDataMsgV1"]["RTPPMData"]["OperatorPage"]
            except:

                try:
                    path = make_path(t, 2)
                    print("Accessing: " + path)
                    data = json.load(open(path))["RTPPMDataMsgV1"]["RTPPMData"]["OperatorPage"]
                except:

                    try:
                        path = make_path(t, 3)
                        print("Accessing: " + path)
                        data = json.load(open(path))["RTPPMDataMsgV1"]["RTPPMData"]["OperatorPage"]
                    except:

                        try:
                            path = make_path(t, 4)
                            print("Accessing: " + path)
                            data = json.load(open(path))["RTPPMDataMsgV1"]["RTPPMData"]["OperatorPage"]
                        except: pass

                        try:
                            path = make_path(t, 5)
                            print("Accessing: " + path)
                            data = json.load(open(path))["RTPPMDataMsgV1"]["RTPPMData"]["OperatorPage"]
                        except: pass

        names = get_names(data)
        temp_rag_table = get_rag(names, data, str(t))
        temp_total_table = get_total(names, data, str(t))
        temp_delayed_table = get_delayed(names, data, str(t))
        temp_cancelled_table = get_cancelled(names, data, str(t))

        # Combine into table
        rag_table_out = merge_table(rag_table_in, temp_rag_table)
        total_table_out = merge_table(total_table_in, temp_total_table)
        delayed_table_out = merge_table(delayed_table_in, temp_delayed_table)
        cancelled_table_out = merge_table(cancelled_table_in, temp_cancelled_table)

        return rag_table_out, total_table_out, delayed_table_out, cancelled_table_out

    except:
        print("WARNING File not found:", sys.exc_info()[0])
        try:
            if len(rag_table_in) > 0:  # Previous data available
                print('Attempting to use previous timestamp')
                temp_rag_table = rag_table_in.iloc[:, -1]
                temp_total_table = total_table_in.iloc[:, -1]
                temp_delayed_table = delayed_table_in.iloc[:, -1]
                temp_cancelled_table = cancelled_table_in.iloc[:, -1]
                print('Updating timestamp')
                temp_rag_table.columns = [str(t)]
                temp_total_table.columns = [str(t)]
                temp_delayed_table.columns = [str(t)]
                temp_cancelled_table.columns = [str(t)]

                print('Adding to table')
                rag_table_out = pd.concat([rag_table_in, temp_rag_table], axis=1)
                total_table_out = pd.concat([total_table_in, temp_total_table], axis=1)
                delayed_table_out = pd.concat([delayed_table_in, temp_delayed_table], axis=1)
                cancelled_table_out = pd.concat([cancelled_table_in, temp_cancelled_table], axis=1)
                print('Using previous entry\n')
                return rag_table_out, total_table_out, delayed_table_out, cancelled_table_out

            else:  # No previous data available, return empty DF
                print('No previous data available, returning empty table')
                return rag_table_in, total_table_in, delayed_table_in, cancelled_table_in

        except:
            print('WARNING No entry recorded')

# Loop through files extracting data


rag_table = pd.DataFrame()
total_table = pd.DataFrame()
delayed_table = pd.DataFrame()
cancelled_table = pd.DataFrame()

time = start_date
delta = dt.timedelta(minutes=15)

while time <= end_date + dt.timedelta(hours=23):
    # Loop through time, access JSON and add data
    rag_table, total_table, delayed_table, cancelled_table = open_path(time, rag_table, total_table, delayed_table, cancelled_table)

    time += delta
    #print("\n")

print(rag_table.shape)
print(total_table.shape)
print(delayed_table.shape)
print(cancelled_table.shape)

# Write to directory
print("Writing tables to drive.")
#rag_table.to_csv("rag_table.csv")
#total_table.to_csv("total_table.csv")
#delayed_table.to_csv("delayed_table_abs.csv")
cancelled_table.to_csv("canc_table_abs.csv")
