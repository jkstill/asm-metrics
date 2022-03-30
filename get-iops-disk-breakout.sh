#!/usr/bin/env bash

# for use with asm-metrics CSV files created by the diskgroup-breakout script

#$  getcol.sh -f set-03/asm-data-20200801-084753.csv  -g| awk -F: '{ printf("[%s]=%d\n", $2,$1) }' | tr -d ' '

declare -A allFields=(
	[DATE]=1
	[TIME]=2
	[ELAPSEDTIME]=3
	[DISKGROUP_NAME]=4
	[AVG_READ_TIME]=5
	[AVG_WRITE_TIME]=6
	[READS]=7
	[WRITES]=8
	[READ_TIME]=9
	[WRITE_TIME]=10
	[BYTES_READ]=11
	[BYTES_WRITTEN]=12
	[READ_ERRS]=13
	[WRITE_ERRS]=14
)

declare cutFields

for field in DATE TIME ELAPSEDTIME DISKGROUP_NAME READS WRITES BYTES_READ BYTES_WRITTEN
do
	cutFields=$cutFields','${allFields[$field]}
done

cutFields=${cutFields:1}

echo
echo cutFields: $cutFields
echo

#for dataSet in set-0{1,3}
for dataSet in asm-metrics-set-01 asm-metrics-set-02 
do
	echo "###################################"
	echo "## data set: $dataSet"
	echo "###################################"

	#cut -d, -f$cutFields <( tail -q -n+2 $dataSet/asm*.csv | head -20000 -q ) | ./get-iops-disk-breakout.pl
	cut -d, -f$cutFields <( tail -q -n+2 $dataSet/diskgroup-breakout/*.csv ) | ./get-iops-disk-breakout.pl

	echo

done




