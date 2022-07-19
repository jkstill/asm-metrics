#!/usr/bin/env bash

# get the values that must be changed to be anonymized
# specific db, instance, diskgroup...

: << 'FIELDS'

This bit will need to be verified per data set, as not all will have the same number of fields

head -1 asm-data-20200625-133202.csv  | perl -e '@a=split(/,/,<STDIN>); print join("\n",@a)'| awk '{ print "fields["$1"]="NR  }'

FIELDS

declare -A fields=(
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

declare sedFile=anonymize.sed
declare -A objNames

getNames () {
	local fieldNum=$1

	objNames=()

	for file in *.csv
	do
		for obj in $(tail -n +2 $file | head -10001 | cut -f${fieldNum} -d, | sort -u)
		do
			objNames[$obj]=1
		done
	done

}

showNames () {
	for db in ${!objNames[@]}
	do
		echo $db
	done | sort

}

banner () {
	local bannerText="$@"

	echo
	echo "### $bannerText ###"
	echo
}

genSedCMDs () {

	for db in ${!objNames[@]}
	do
		echo "s/\b$db/$db/g"
	done

}

> $sedFile

for field in DBNAME DISKGROUP_NAME
do
	banner $field
	getNames ${fields[$field]}
	showNames
	genSedCMDs >> $sedFile
done


cat << EOF

Sed commands have been written to $sedFile

Edit the transformations as needed

Then use this command to modify values in the csv files:

  sed -i -r -f $sedFile CSV-FILE
	 
The files will NOT be backed up, so make sure you are not working with the only copy of your data file
  

EOF




