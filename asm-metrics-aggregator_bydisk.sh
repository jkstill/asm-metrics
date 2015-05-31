#!/bin/bash

INPUT_DATAFILE='logs/asm-oravm-data-20150523-172525.csv'
OUTPUT_DATAFILE='logs/asm-oravm-agg-bydisk.csv'

./asm-metrics-aggregator.pl  \
	--grouping-cols DISK_NAME \
	--agg-cols READS WRITES READ_TIME WRITE_TIME \
	--display-cols  DISPLAYTIME ELAPSEDTIME DBNAME DISKGROUP_NAME READS \
		WRITES READ_TIME AVG_READ_TIME WRITE_TIME \
		AVG_WRITE_TIME BYTES_READ BYTES_WRITTEN  \
	-- ${INPUT_DATAFILE}   \
	> ${OUTPUT_DATAFILE}

