#!/bin/bash

mkdir -p xlsx-by-diskgroup

for infile in diskgroup-breakout/[A-Z]*.csv
do

	diskgroup=$(echo $infile | cut -f2 -d/ | cut -f1 -d\.)

	xlsxFile=xlsx-by-diskgroup/${diskgroup}.xlsx

	echo working on $xlsxFile

	asm-metrics-chart.pl \
		--worksheet-col DATE \
		--date-time-sep \
		--spreadsheet-file $xlsxFile \
		--chart-cols AVG_READ_TIME AVG_WRITE_TIME READS BYTES_READ WRITES BYTES_WRITTEN  \
		-- $infile


done

