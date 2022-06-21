#!/bin/bash


mkdir -p db-bydisk

#INPUT_DATAFILE='logs/asm-data-20220109-074242.csv'
OUTPUT_DATAFILE='db-bydisk/asm-agg-bydisk.csv'

: << 'SORTING'

sort by year, month, day, hour, minute, secont

123456789+123456789+
2022-05-24 19:57:19


         disk name   year      month        day        hour        minute       second
sort -t, -k23,23  -k1.1,1.4n -k1.6,1.7n -k1.9,1.10n -k1.12,1.13n -k1.15,1.16n -k1.18,1.19n


SORTING

./asm-metrics-aggregator.pl  \
	--grouping-cols DISK_NAME \
	--agg-cols READS WRITES READ_TIME WRITE_TIME \
	--display-cols  DISK_NAME DISPLAYTIME ELAPSEDTIME DBNAME DISKGROUP_NAME READS \
		WRITES READ_TIME AVG_READ_TIME WRITE_TIME \
		AVG_WRITE_TIME BYTES_READ BYTES_WRITTEN  \
		-- <( head -1 logs/asm-data-20220524-195521.csv; grep -hv '^DISPLAYTIME'  logs/asm-data*.csv | sort -t, -k23,23 -k1.1,1.4n -k1.6,1.7n -k1.9,1.10n -k1.12,1.13n -k1.15,1.16n -k1.18,1.19n ) \
	> ${OUTPUT_DATAFILE}

echo
echo output: $OUTPUT_DATAFILE
echo

echo now run ./asm-metrics-aggregator_bydisk.sh
echo 
