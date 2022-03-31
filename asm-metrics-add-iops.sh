#!/usr/bin/env bash

mkdir -p diskgroup-breakout-iops

for dgFile in diskgroup-breakout/[A-Z]*.csv
do
	iopsOutfile=diskgroup-breakout-iops/$(basename $dgFile | cut -f1 -d\.)_iops.csv
	echo "working on iopsOutfile: $iopsOutfile"
	./asm-metrics-add-iops.pl < $dgFile > $iopsOutfile
done

