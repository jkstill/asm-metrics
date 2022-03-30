#!/usr/bin/env bash

# for use on raw asm-metrics CSV files

#$  getcol.sh -f set-03/asm-data-20200801-084753.csv  -g| awk -F: '{ printf("[%s]=%d\n", $2,$1) }' | tr -d ' '

declare -A allFields=(
	[DISPLAYTIME]=1
	[SNAPTIME]=2
	[ELAPSEDTIME]=3
	[INSTNAME]=4
	[DBNAME]=5
	[GROUP_NUMBER]=6
	[DISK_NUMBER]=7
	[DISKGROUP_NAME]=8
	[READS]=9
	[WRITES]=10
	[READ_TIME]=11
	[AVG_READ_TIME]=12
	[WRITE_TIME]=13
	[AVG_WRITE_TIME]=14
	[BYTES_READ]=15
	[BYTES_WRITTEN]=16
	[COLD_BYTES_READ]=17
	[COLD_BYTES_WRITTEN]=18
	[COLD_READS]=19
	[COLD_USED_MB]=20
	[COLD_WRITES]=21
	[CREATE_DATE]=22
	[DISK_NAME]=23
	[FAILGROUP]=24
	[FAILGROUP_TYPE]=25
	[FREE_MB]=26
	[HEADER_STATUS]=27
	[HOT_BYTES_READ]=28
	[HOT_BYTES_WRITTEN]=29
	[HOT_READS]=30
	[HOT_USED_MB]=31
	[HOT_WRITES]=32
	[LABEL]=33
	[MOUNT_DATE]=34
	[OS_MB]=35
	[PATH]=36
	[PREFERRED_READ]=37
	[PRODUCT]=38
	[READ_ERRS]=39
	[REDUNDANCY]=40
	[REPAIR_TIMER]=41
	[SECTOR_SIZE]=42
	[TOTAL_MB]=43
	[UDID]=44
	[VOTING_FILE]=45
	[WRITE_ERRS]=46
)

declare cutFields

for field in DISPLAYTIME ELAPSEDTIME DISKGROUP_NAME READS WRITES BYTES_READ BYTES_WRITTEN
do
	cutFields=$cutFields','${allFields[$field]}
done

cutFields=${cutFields:1}

echo cutFields: $cutFields

for dataSet in asm-metrics-set-01 asm-metrics-set-02
do

	echo "###################################"
	echo "## data set: $dataSet"
	echo "###################################"

	#cut -d, -f$cutFields <( tail -q -n+2 $dataSet/asm*.csv | head -20000 -q ) | ./get-iops.pl 
	cut -d, -f$cutFields <( tail -q -n+2 $dataSet/asm*.csv ) | ./get-iops.pl 

	echo

done


