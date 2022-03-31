#!/bin/bash

mkdir -p xlsx-diskgroup-iops

for infile in diskgroup-breakout-iops/[A-Z]*.csv
do

	diskgroup=$(echo $infile | cut -f2 -d/ | cut -f1 -d\.)

	xlsxFile=xlsx-diskgroup-iops/${diskgroup}.xlsx

	echo working on $xlsxFile

	# https://github.com/jkstill/csv-tools/tree/master/dynachart
	dynachart.pl \
		--worksheet-col DATE \
		--category-col TIME \
		--spreadsheet-file $xlsxFile \
		--chart-cols TIME --chart-cols IOPS --chart-cols IOPS_SZ_SEC \
		--secondary-axis-col IOPS \
		--chart-type scatter \
		--combined-chart < $infile

done

