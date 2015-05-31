#!/bin/bash

#./asm-metrics-chart.pl  --debug \
./asm-metrics-chart.pl \
	--worksheet-col DISK_NAME \
	--spreadsheet-file oravm-asm-metrics-by-disk.xlsx \
	--chart-cols READS AVG_READ_TIME WRITES AVG_WRITE_TIME  \
	-- logs/asm-oravm-agg-bydisk.csv

