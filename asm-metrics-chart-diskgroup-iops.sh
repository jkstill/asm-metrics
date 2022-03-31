#!/bin/bash

mkdir -p xlsx-diskgroup-iops

for infile in diskgroup-breakout-iops/[A-Z]*.csv
do

	diskgroup=$(echo $infile | cut -f2 -d/ | cut -f1 -d\.)

	xlsxFile=xlsx-diskgroup-iops/${diskgroup}.xlsx

	echo working on $xlsxFile

	#/mnt/zips/tmp/asm-metrics/metrics-bin/asm-metrics-chart.pl \
		#--worksheet-col DATE \
		#--date-time-sep \
		#--spreadsheet-file $xlsxFile \
		#--chart-cols IOPS IOPS_SZ_SEC \
		#-- $infile

	dynachart.pl \
		--worksheet-col DATE \
		--category-col TIME \
		--spreadsheet-file $xlsxFile \
		--chart-cols IOPS --chart-cols IOPS_SZ_SEC \
		--combined-chart < $infile


done

