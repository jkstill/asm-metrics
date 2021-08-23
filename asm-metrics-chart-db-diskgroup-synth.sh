#!/bin/bash

mkdir -p xlsx-by-db-diskgroup

for infile in db-diskgroup-breakout/*.csv
do

	filebase=$(echo $infile | cut -f2 -d/ | cut -f1 -d\.)
	diskgroup=$(echo $filebase | cut -f1 -d-)
	db=$(echo $filebase | cut -f2 -d-)

	xlsxFile=xlsx-by-db-diskgroup/${diskgroup}-${db}.xlsx

	echo working on $xlsxFile

	asm-metrics-chart.pl \
		--worksheet-col DATE \
		--date-time-sep \
		--spreadsheet-file $xlsxFile \
		--chart-cols AVG_READ_TIME AVG_WRITE_TIME READS BYTES_READ WRITES BYTES_WRITTEN  \
		-- $infile


done

