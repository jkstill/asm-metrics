#!/bin/bash

mkdir -p xlsx-db-bydisk

#./asm-metrics-chart.pl  --debug \
./asm-metrics-chart.pl \
	--worksheet-col DISK_NAME \
	--spreadsheet-file xlsx-db-bydisk/asm-metrics-by-disk.xlsx \
	--chart-cols READS AVG_READ_TIME WRITES AVG_WRITE_TIME  \
	-- db-bydisk/asm-agg-bydisk.csv

