#!/bin/bash

echo -n 'PWD: '
pwd

mkdir -p xlsx-by-diskgroup-cleaned

for infile in cleaned/[A-Z]*.csv
do

	diskgroup=$(echo $infile | cut -f2 -d/ | cut -f1 -d\.)

	xlsxFile=xlsx-by-diskgroup-cleaned/${diskgroup}.xlsx

	echo infile: $infile
	echo working on $xlsxFile

#: << 'COMMENT'

	asm-metrics-chart.pl \
		--worksheet-col DATE \
		--date-time-sep \
		--spreadsheet-file $xlsxFile \
		--chart-cols AVG_READ_TIME AVG_WRITE_TIME READS BYTES_READ WRITES BYTES_WRITTEN  \
		-- $infile

#COMMENT

done

