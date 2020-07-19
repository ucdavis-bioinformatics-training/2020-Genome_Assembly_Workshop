from pandas.io.json import json_normalize
import pandas as pd
from ast import literal_eval
import argparse
import numpy as np

# TODO less overlap for the keys and the json merge function??
# TODO check if the sequence order matches across all samples?
# TODO sys.stderr.write
# TODO finish rRNA screen option

parser = argparse.ArgumentParser(description='Script to process json file stats for htsPrepro to csv.',
                                 epilog='For questions or comments, please contact Matt Settles <settles@ucdavis.edu> '
                                        'or Keith Mitchell <kgmitchell@ucdavis.edu\n', add_help=True)
parser.add_argument('-s', '--samples', help="Path to the file 'samples.txt' where each row is the name of a file as "
                                            "follows '01-HTS_Preproc/{SAMPLE}/{SAMPLE}_htsStats.log' OR a list of "
                                            "samples such as --samples=SampleAC1,SampleAC2,SampleAC3. See --sample_"
                                            "is_file to specify this.", required=True)
parser.add_argument('-f', '--samples_is_file', help="True or False for if samples is a file or a list respectively, "
                                                    "Default is True")
parser.add_argument('-t', '--type', help="Select from the following list: [PE, SE, tagseq]", required=True)
parser.add_argument('-o', '--output_dir', help="Output file name and directory if specified.")
parser.add_argument('-r', '--rnascreen', help="Either True or False depending on whether or not RNAscreen was "
                                              "run, default=True")
parser.add_argument('-i', '--input_dir', help="Directory where 01-HTS_Preproc exists, default is current directory. "
                                              "(EX: ../snakemake_tagseq")

options = parser.parse_args()
print(options)

# Get samples from 'samples.txt' file or parse the samples
if options.samples_is_file is None or options.samples_is_file != 'False':
    samples = []
    with open(options.samples, 'r') as samples_file:
        for line in samples_file:
            samples.append(line.strip('\n'))

# or parse the csvs that were passed
else:
    samples = options.samples.split(',')

# check if specific input directory was passed
if options.input_dir:
    filenames = [f'{options.input_dir}/01-HTS_Preproc/{sample}/{sample}_htsStats.log' for sample in samples]

# otherwise use the default
else:
    filenames = [f'01-HTS_Preproc/{sample}/{sample}_htsStats.log' for sample in samples]

print(filenames)


def se_overlap(df):
    # RAW STATS
    df['Raw_Reads'] = df['htsStats1.totalFragmentsInput']
    df['Raw_Bp'] = df['htsStats1.Single_end.SE_bpLen'] + df['htsStats1.Single_end.SE_bpLen']
    df['Raw_SE_PercentQ30'] = (df['htsStats1.Single_end.SE_bQ30'] / df['htsStats1.Single_end.SE_bpLen']) * 100
    df['Raw_Percent_CG'] = ((df['htsStats1.Base_composition.C'] + df['htsStats1.Base_composition.G']) / df[
        'Raw_Bp']) * 100
    df['Raw_Chars_N'] = df['htsStats1.Base_composition.N']

    # PHIX SCREEN
    df['PhiX_IN'] = df['htsSeqScreener1.totalFragmentsInput']
    df['PhiX_Discard'] = df['htsSeqScreener1.Single_end.SE_hits']
    df['PhiX_Percent_Discard'] = (df['PhiX_Discard'] / df['PhiX_IN']) * 100

    if options.rnascreen is None or options.rnascreen != False:
        # rRNA SCREEN
        df['rRNA_IN'] = df['htsSeqScreener2.totalFragmentsInput']
        df['rRNA_Identified'] = df['htsSeqScreener2.Single_end.SE_hits']
        df['rRNA_Percent_Identified'] = (df['rRNA_Identified'] / df['rRNA_IN']) * 100

    # ADAPTER TRIM
    df['AdapterTrimmed_IN'] = df['htsAdapterTrimmer.totalFragmentsInput']
    df['AdapterTrimmed_Reads'] = df['htsAdapterTrimmer.Single_end.SE_adapterTrim']
    df['AdapterTrimmed_Percent_Reads'] = (df['AdapterTrimmed_Reads'] / df['AdapterTrimmed_IN']) * 100
    df['AdapterTrimmed_BP'] = df['htsAdapterTrimmer.Single_end.SE_adapterBpTrim']

    # QWINDOW TRIM
    df['QwindowTrimmed_IN'] = df['htsQWindowTrim.totalFragmentsInput']
    df['QwindowTrimmed_SE_LeftBpTrim'] = df['htsQWindowTrim.Single_end.SE_leftTrim']
    df['QwindowTrimmed_SE_RightBpTrim'] = df['htsQWindowTrim.Single_end.SE_leftTrim']
    df['QwindowTrimmed_Discard'] = df['htsQWindowTrim.Single_end.SE_discarded']

    # N TRIM
    df['NcharTrimmed_IN'] = df['htsNTrimmer.totalFragmentsInput']
    df['NcharTrimmed_SE_LeftBpTrim'] = df['htsNTrimmer.Single_end.SE_leftTrim']
    df['NcharTrimmed_SE_RightBpTrim'] = df['htsNTrimmer.Single_end.SE_rightTrim']
    df['NcharTrimmed_Discard'] = df['htsNTrimmer.Single_end.SE_discarded']

    # POST STATS
    df['Proc_Reads'] = df['htsStats2.totalFragmentsInput']
    df['Proc_Bp'] = df['htsStats2.Single_end.SE_bpLen'] + df['htsStats2.Single_end.SE_bpLen']
    df['Proc_SE_PercentQ30'] = (df['htsStats2.Single_end.SE_bQ30'] / df['htsStats2.Single_end.SE_bpLen']) * 100
    df['Proc_Percent_CG'] = ((df['htsStats2.Base_composition.C']+df['htsStats2.Base_composition.G']) / df['Proc_Bp']) * 100
    df['Proc_Chars_N'] = df['htsStats2.Base_composition.N']

    # FINAL PERCENTS
    df['Final_Percent_Read'] = (df['Proc_Reads'] / df['Raw_Reads']) * 100
    df['Final_Percent_Bp'] = (df['Proc_Bp'] / df['Raw_Bp']) * 100

    return df


def SE_process(file_list):
    json_total = ''
    apps = ["hts_Stats", "hts_SeqScreener", "hts_AdapterTrimmer", "hts_QWindowTrim", "hts_NTrimmer",
            "hts_CutTrim", ]
    check_apps = ["htsStats1", "htsSeqScreener1", "htsSeqScreener2", "htsAdapterTrimmer", "htsCutTrim",
                  "htsQWindowTrim", "htsNTrimmer", "htsStats2", ]

    # MERGE JSON FILES
    for fname in file_list:
        stats_dup = iter(['1', '2', ])  # pre stats and post stats
        screen_dup = iter(['1', '2', ])  # Phix screen and seq screen

        with open(fname) as infile:
            for line in infile:
                if any(app in line for app in apps):
                    split_line = line.split('_')

                    # RENAME DUPLICATES IF STATS OR SCREEN
                    if "hts_Stats" in line:
                        rejoin_line = split_line[:-1] + [next(stats_dup) + '": {\n']
                    elif "hts_SeqScreen" in line:
                        rejoin_line = split_line[:-1] + [next(screen_dup) + '": {\n']
                    else:
                        rejoin_line = split_line[:-1] + ['": {\n']
                    json_total += ''.join(rejoin_line)
                else:
                    json_total += line
            json_total = json_total.rstrip()
            json_total += ","

    # LOAD JSONS MERGED INTO PANDAS DATAFRAME
    data = [i for i in literal_eval(json_total)]
    df = pd.DataFrame.from_dict(json_normalize(data), orient='columns')

    keys = [
        # RAW STATS
        "Raw_Reads", "Raw_Bp", "Raw_SE_PercentQ30", "Raw_Percent_CG", "Raw_Chars_N",
        # PHIX SCREEN
        "PhiX_IN", "PhiX_Discard", "PhiX_Percent_Discard",
        # TODO only on condition
        # rRNA SCREEN
        "rRNA_IN", "rRNA_Identified", "rRNA_Percent_Identified",
        # ADAPTER TRIM
        "AdapterTrimmed_IN", "AdapterTrimmed_Reads", "AdapterTrimmed_Percent_Reads", "AdapterTrimmed_BP",
        # QWINDOW TRIM
        "QwindowTrimmed_IN", "QwindowTrimmed_SE_LeftBpTrim", "QwindowTrimmed_SE_RightBpTrim", "QwindowTrimmed_Discard",
        # NCHAR
        "NcharTrimmed_IN", "NcharTrimmed_SE_LeftBpTrim", "NcharTrimmed_SE_RightBpTrim", "NcharTrimmed_Discard",
        # CUT TRIM
        "MinLen_IN", "MinLen_Discard",
        # POST STATS
        "Proc_Reads", "Proc_Bp", "Proc_SE_PercentQ30", "Proc_Percent_CG", "Proc_Chars_N",
        "Final_Percent_Read", "Final_Percent_Bp"
    ]

    print(df.columns)

    # CUT TRIM
    print("Cut trim")
    df['MinLen_IN'] = df["htsCutTrim.totalFragmentsInput"]
    df['MinLen_Discard'] = df["htsCutTrim.Single_end.SE_discarded"]

    print("Overlap")

    df = se_overlap(df)

    return df, keys


def tagseq_process(file_list):
    json_total = ''
    apps = ["hts_Stats", "hts_SeqScreener", "hts_AdapterTrimmer", "hts_QWindowTrim", "hts_NTrimmer",
            "hts_CutTrim", ]
    check_apps = ["htsStats1", "htsSeqScreener1", "htsSeqScreener2", "htsAdapterTrimmer", "htsCutTrim1",
                  "htsQWindowTrim", "htsNTrimmer", "htsCutTrim2", "htsStats2", ]

    # MERGE JSON FILES
    for fname in file_list:
        stats_dup = iter(['1', '2', ])  # pre stats and post stats
        screen_dup = iter(['1', '2', ])  # Phix screen and seq screen
        cut_dup = iter(['1', '2', ])  # CutTrim screen and seq screen

        with open(fname) as infile:
            for line in infile:
                if any(app in line for app in apps):
                    split_line = line.split('_')

                    # RENAME DUPLICATES IF STATS OR SCREEN
                    if "hts_Stats" in line:
                        rejoin_line = split_line[:-1] + [next(stats_dup) + '": {\n']
                    elif "hts_SeqScreen" in line:
                        rejoin_line = split_line[:-1] + [next(screen_dup) + '": {\n']
                    elif "hts_CutTrim" in line:
                        rejoin_line = split_line[:-1] + [next(cut_dup) + '": {\n']
                    else:
                        rejoin_line = split_line[:-1] + ['": {\n']
                    json_total += ''.join(rejoin_line)
                else:
                    json_total += line
            json_total = json_total.rstrip()
            json_total += ","

    # LOAD JSONS MERGED INTO PANDAS DATAFRAME
    data = [i for i in literal_eval(json_total)]
    df = pd.DataFrame.from_dict(json_normalize(data), orient='columns')

    keys = [
        # RAW STATS
        "Raw_Reads", "Raw_Bp", "Raw_SE_PercentQ30", "Raw_Percent_CG", "Raw_Chars_N",
        # PHIX SCREEN
        "PhiX_IN", "PhiX_Discard", "PhiX_Percent_Discard",
        #TODO only on condition
        # rRNA SCREEN
        "rRNA_IN", "rRNA_Identified", "rRNA_Percent_Identified",
        # ADAPTER TRIM
        "AdapterTrimmed_IN", "AdapterTrimmed_Reads", "AdapterTrimmed_Percent_Reads", "AdapterTrimmed_BP",
        # CUT TRIM HARD
        "HardTrim_IN", "HardTrim_SE_LeftBpTrim", "HardTrim_Discard",
        # QWINDOW TRIM
        "QwindowTrimmed_IN", "QwindowTrimmed_SE_LeftBpTrim", "QwindowTrimmed_SE_RightBpTrim", "QwindowTrimmed_Discard",
        # NCHAR
        "NcharTrimmed_IN", "NcharTrimmed_SE_LeftBpTrim", "NcharTrimmed_SE_RightBpTrim", "NcharTrimmed_Discard",
        # CUT TRIM
        "MinLen_IN", "MinLen_Discard",
        # POST STATS
        "Proc_Reads", "Proc_Bp", "Proc_SE_PercentQ30", "Proc_Percent_CG", "Proc_Chars_N",
        "Final_Percent_Read", "Final_Percent_Bp"
    ]


    # CUT TRIM HARD
    df['HardTrim_IN'] = df["htsCutTrim1.totalFragmentsInput"]
    df['HardTrim_SE_LeftBpTrim'] = df["htsCutTrim1.Single_end.SE_leftTrim"]
    df['HardTrim_Discard'] = df["htsCutTrim1.Single_end.SE_discarded"]

    # CUT TRIM
    df['MinLen_IN'] = df["htsCutTrim2.totalFragmentsInput"]
    df['MinLen_Discard'] = df["htsCutTrim2.Single_end.SE_discarded"]

    df = se_overlap(df)

    return df, keys


def PE_process(file_list):
    json_total = ''
    apps = ["hts_Stats", "hts_SeqScreener", "hts_SuperDeduper", "hts_AdapterTrimmer", "hts_QWindowTrim", "hts_NTrimmer",
            "hts_CutTrim", ]

    check_apps = ["htsStats1", "htsStats2", "htsSeqScreener1", "htsSeqScreener2", "htsSuperDeduper", "htsAdapterTrimmer",
                  "htsQWindowTrim", "htsNTrimmer", "htsCutTrim", ]

    # MERGE JSON FILES
    for fname in file_list:
        stats_dup = iter(['1', '2', ])  # pre stats and post stats
        screen_dup = iter(['1', '2', ])  # Phix screen and seq screen
        with open(fname) as infile:
            for line in infile:
                if any(app in line for app in apps):
                    split_line = line.split('_')

                    # RENAME DUPLICATES IF STATS OR SCREEN
                    if "hts_Stats" in line:
                        rejoin_line = split_line[:-1] + [next(stats_dup) + '": {\n']
                    elif "hts_SeqScreen" in line:
                        rejoin_line = split_line[:-1] + [next(screen_dup) + '": {\n']
                    else:
                        rejoin_line = split_line[:-1] + ['": {\n']
                    json_total += ''.join(rejoin_line)
                else:
                    json_total += line
            json_total = json_total.rstrip()
            json_total += ","

    # LOAD JSONS MERGED INTO PANDAS DATAFRAME
    data = [i for i in literal_eval(json_total)]
    df = pd.DataFrame.from_dict(json_normalize(data), orient='columns')

    keys = [
        # RAW STATS
        "Raw_Reads", "Raw_Bp", "Raw_R1_PercentQ30", "Raw_R2_PercentQ30", "Raw_Percent_CG", "Raw_Chars_N",
        # PHIX SCREEN
        "PhiX_IN", "PhiX_Discard", "PhiX_Percent_Discard",
        #TODO only in keys if options.rnascreen
        # rRNA SCREEN
        "rRNA_IN", "rRNA_Identified", "rRNA_Percent_Identified",
        # SUPER DEDUPER
        "SuperDeduper_IN", "SuperDeduper_Ignored", "SuperDeduper_Duplicate", "SuperDeduper_Percent_Duplicate",
        # ADAPTER TRIM
        "AdapterTrimmed_IN", "AdapterTrimmed_Reads", "AdapterTrimmed_Percent_Reads", "AdapterTrimmed_BP",
        # QWINDOW TRIM
        "QwindowTrimmed_IN", "QwindowTrimmed_R1_LeftBpTrim", "QwindowTrimmed_R1_RightBpTrim", "QwindowTrimmed_R2_LeftBpTrim", "QwindowTrimmed_R2_RightBpTrim", "QwindowTrimmed_Discard",
        # NCHAR
        "NcharTrimmed_IN", "NcharTrimmed_R1_LeftBpTrim", "NcharTrimmed_R1_RightBpTrim", "NcharTrimmed_R2_LeftBpTrim", "NcharTrimmed_R2_RightBpTrim", "NcharTrimmed_Discard",
        # CUT TRIM
        "MinLen_IN", "MinLen_Discard",
        # POST STATS
        "Proc_Reads", "Proc_Bp", "Proc_R1_PercentQ30", "Proc_R2_PercentQ30", "Proc_Percent_CG", "Proc_Chars_N",
        "Final_Percent_Read", "Final_Percent_Bp"
    ]

    # RAW STATS
    df['Raw_Reads'] = df['htsStats1.totalFragmentsInput']
    df['Raw_Bp'] = df['htsStats1.Paired_end.R1_bpLen'] + df['htsStats1.Paired_end.R2_bpLen']
    df['Raw_R1_PercentQ30'] = (df['htsStats1.Paired_end.R1_bQ30'] / df['htsStats1.Paired_end.R1_bpLen']) * 100
    df['Raw_R2_PercentQ30'] = (df['htsStats1.Paired_end.R2_bQ30'] / df['htsStats1.Paired_end.R2_bpLen']) * 100
    df['Raw_Percent_CG'] = ((df['htsStats1.Base_composition.C']+df['htsStats1.Base_composition.G'])/df['Raw_Bp']) * 100
    df['Raw_Chars_N'] = df['htsStats1.Base_composition.N']

    # PHIX SCREEN
    df['PhiX_IN'] = df['htsSeqScreener1.totalFragmentsInput']
    df['PhiX_Discard'] = df['htsSeqScreener1.Paired_end.PE_hits']
    df['PhiX_Percent_Discard'] = (df['PhiX_Discard'] / df['PhiX_IN']) * 100

    if options.rnascreen is None or options.rnascreen != False:
        # rRNA SCREEN
        df['rRNA_IN'] = df['htsSeqScreener2.totalFragmentsInput']
        df['rRNA_Identified'] = df['htsSeqScreener2.Paired_end.PE_hits']
        df['rRNA_Percent_Identified'] = (df['rRNA_Identified'] / df['rRNA_IN']) * 100

    # ADAPTER TRIM
    df['AdapterTrimmed_IN'] = df['htsAdapterTrimmer.totalFragmentsInput']
    df['AdapterTrimmed_Reads'] = df['htsAdapterTrimmer.Paired_end.PE_adapterTrim']
    df['AdapterTrimmed_Percent_Reads'] = (df['AdapterTrimmed_Reads'] / df['AdapterTrimmed_IN']) * 100
    df['AdapterTrimmed_BP'] = df['htsAdapterTrimmer.Paired_end.PE_adapterBpTrim']

    # QWINDOW TRIM
    df['QwindowTrimmed_IN'] = df['htsQWindowTrim.totalFragmentsInput']
    df['QwindowTrimmed_R1_LeftBpTrim'] = df['htsQWindowTrim.Paired_end.R1_leftTrim']
    df['QwindowTrimmed_R2_LeftBpTrim'] = df['htsQWindowTrim.Paired_end.R2_leftTrim']
    df['QwindowTrimmed_R1_RightBpTrim'] = df['htsQWindowTrim.Paired_end.R1_rightTrim']
    df['QwindowTrimmed_R2_RightBpTrim'] = df['htsQWindowTrim.Paired_end.R2_rightTrim']
    df['QwindowTrimmed_Discard'] = df['htsQWindowTrim.Paired_end.PE_discarded']

    # N TRIM
    df['NcharTrimmed_IN'] = df['htsNTrimmer.totalFragmentsInput']
    df['NcharTrimmed_R1_LeftBpTrim'] = df['htsNTrimmer.Paired_end.R1_leftTrim']
    df['NcharTrimmed_R1_RightBpTrim'] = df['htsNTrimmer.Paired_end.R1_rightTrim']
    df['NcharTrimmed_R2_LeftBpTrim'] = df['htsNTrimmer.Paired_end.R2_leftTrim']
    df['NcharTrimmed_R2_RightBpTrim'] = df['htsNTrimmer.Paired_end.R2_rightTrim']
    df['NcharTrimmed_Discard'] = df['htsNTrimmer.Paired_end.PE_discarded']

    # POST STATS
    df['Proc_Reads'] = df['htsStats2.totalFragmentsInput']
    df['Proc_Bp'] = df['htsStats2.Paired_end.R1_bpLen'] + df['htsStats2.Paired_end.R2_bpLen']
    df['Proc_R1_PercentQ30'] = (df['htsStats2.Paired_end.R1_bQ30'] / df['htsStats2.Paired_end.R1_bpLen']) * 100
    df['Proc_R2_PercentQ30'] = (df['htsStats2.Paired_end.R2_bQ30'] / df['htsStats2.Paired_end.R2_bpLen']) * 100
    df['Proc_Percent_CG'] = ((df['htsStats2.Base_composition.C']+df['htsStats2.Base_composition.G'])/df['Proc_Bp']) * 100
    df['Proc_Chars_N'] = df['htsStats2.Base_composition.N']

    # FINAL PERCENTS
    df['Final_Percent_Read'] = (df['Proc_Reads'] / df['Raw_Reads']) * 100
    df['Final_Percent_Bp'] = (df['Proc_Bp'] / df['Raw_Bp']) * 100

    # SUPER DEDUPER
    df['SuperDeduper_IN'] = df['htsSuperDeduper.totalFragmentsInput']
    df['SuperDeduper_Ignored'] = df['htsSuperDeduper.ignored']
    df['SuperDeduper_Duplicate'] = df['htsSuperDeduper.duplicate']
    df['SuperDeduper_Percent_Duplicate'] = (df['SuperDeduper_Duplicate']/df['SuperDeduper_IN']) * 100

    # CUT TRIM
    df['MinLen_IN'] = df["htsCutTrim.totalFragmentsInput"]
    df['MinLen_Discard'] = df["htsCutTrim.Paired_end.PE_discarded"]

    return df, keys


# check the type and process the stats relevant to that type
if options.type == 'PE':
    print("Paired End Processing")
    df, keys = PE_process(filenames)
elif options.type == 'tagseq':
    print("Tagseq Processing")
    df, keys = tagseq_process(filenames)
elif options.type == 'SE':
    print("Single End Processing")
    df, keys = SE_process(filenames)
    print("Done: Single End Processing")
else:
    sys.exit("CONFIGURATION ERROR: type not found. Please select from ['tagseq', 'PE', 'SE']. Default = PE")

# for label in keys:
#     if label in list(df):
#         continue
#     else:
#         print("Not found: ", label)


df.to_csv(f"{options.output_dir}/summary_hts_{options.type}.txt", columns=keys, index=samples)
