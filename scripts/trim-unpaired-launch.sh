#!/usr/bin/env bash
#
# runs singularity fastqc.img trim_galore to trim adapters and low quality bases
#

set -u
source ./config.sh
export CWD="$PWD"
#batches of N
export STEP_SIZE=10

PROG=`basename $0 ".sh"`
STDOUT_DIR="$CWD/pbs_logs/$PROG"

init_dir "$STDOUT_DIR" 

mkdir -p $TRIMMED_DIR
mkdir -p $TRMD_CANC
mkdir -p $TRMD_CONT

cd $PRJ_DIR

export DNALIST="unpaired_fastq_file_list"

find $DL_CANCER $DL_CONTROL -iname "*unpaired.fastq.gz" > $DNALIST

export TODO="unpaired_files_todo"

if [ -e $TODO ]; then
    rm $TODO
fi

echo "Checking if trimming has already been done for dna"
while read FASTQ; do

    if [[ $FASTQ =~ "cancer" ]]; then
    
        if [ ! -e "$TRMD_CANC/$(basename $FASTQ _unpaired.fastq.gz)_trimmed.fq.gz" ]; then
            echo $FASTQ >> $TODO
        fi

    else
        
        if [ ! -e "$TRMD_CONT/$(basename $FASTQ _unpaired.fastq.gz)_trimmed.fq.gz" ]; then
            echo $FASTQ >> $TODO
        fi

    fi

done < $DNALIST

NUM_FILES=$(lc $TODO)

echo Found \"$NUM_FILES\" files in \"$PRJ_DIR\" to work on

JOB=$(qsub -J 1-$NUM_FILES:$STEP_SIZE -V -N trimgalore -j oe -o "$STDOUT_DIR" $WORKER_DIR/trim-unpaired.sh)

if [ $? -eq 0 ]; then
  echo Submitted job \"$JOB\" for you in steps of \"$STEP_SIZE.\" grep me no patterns and I will tell you no lines.
else
  echo -e "\nError submitting job\n$JOB\n"
fi
