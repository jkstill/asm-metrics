#!/bin/bash

#./asm-metrics-chart.pl  --debug \
./asm-metrics-chart.pl \
	--worksheet-col DISKGROUP_NAME \
	--spreadsheet-file oravm-asm-metrics.xlsx \
	--chart-cols READS AVG_READ_TIME WRITES AVG_WRITE_TIME  \
	-- logs/asm-oravm-aggtest.csv

