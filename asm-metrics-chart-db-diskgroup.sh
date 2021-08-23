#!/bin/bash

mkdir -p xlsx-by-db-diskgroup

for infile in db-diskgroup/*.csv
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

