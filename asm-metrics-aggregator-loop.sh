#!/bin/bash

mkdir -p output 

for INPUT_DATAFILE in logs/asm-data*.csv
do

	#datestamp=$(echo $INPUT_DATAFILE|cut -d- -f3)
	OUTPUT_DATAFILE=$(echo $INPUT_DATAFILE | cut -f1-2 | sed -e 's/logs\//output\//' )

	echo working on $OUTPUT_DATAFILE

asm-metrics-aggregator.pl  \
	--grouping-cols DISKGROUP_NAME \
	--agg-cols READS WRITES READ_TIME WRITE_TIME BYTES_READ BYTES_WRITTEN READ_ERRS WRITE_ERRS\
	--display-cols  DISPLAYTIME ELAPSEDTIME DISKGROUP_NAME READS \
		WRITES READ_TIME WRITE_TIME \
		 BYTES_READ BYTES_WRITTEN  \
	-- ${INPUT_DATAFILE}   \
	> ${OUTPUT_DATAFILE}


done

