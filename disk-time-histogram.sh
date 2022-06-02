#!/usr/bin/env bash

# create scatter charts of disk read/write times for each combination of diskgroup and instances
# for the DBP0078 database only

declare DB=DBP0078

declare xlsxDir=./xlsx-disk-time-histograms
mkdir -p $xlsxDir

declare readTimCol=12
declare writeTimCol=13
declare chartType=scatter

for instance in DB0007 DBP008
do
	for diskGroup in $(getcol.sh -d, -c DISKGROUP_NAME -f logs/asm-data-20220116-034544.csv | sort -u)
	do
			
		declare xlsxFile=$xlsxDir/${DB}-${instance}-$diskGroup-readtim.xlsx
		echo $xlsxFile

		grep -ahE "${instance},${DB},.*,${diskgroup}," <(tail -q -n+2 logs/asm-*.csv) \
			| cut -d, -f$readTimCol | ./disk-time-histogram.pl  \
			| dynachart.pl --spreadsheet-file $xlsxFile --category-col bucket --chart-cols 'count' --chart-type $chartType

		xlsxFile=$xlsxDir/${DB}-${instance}-$diskGroup-writetim.xlsx
		echo $xlsxFile
		echo

		grep -ahE "${instance},${DB},.*,${diskgroup}," <(tail -q -n+2 logs/asm-*.csv) \
			| cut -d, -f$writeTimCol | ./disk-time-histogram.pl  \
			| dynachart.pl --spreadsheet-file $xlsxFile --category-col bucket --chart-cols 'count' --chart-type $chartType

	done
done
