#!/usr/bin/env bash

# remove outliers
# remove large spikes
# this is useful for seeing trends without the charts
# being skewed by outliers and large spikes


mkdir -p cleaned

for infile in diskgroup-breakout/*.csv
do
	outfile=$(echo $infile | sed -e 's/diskgroup-breakout/cleaned/' -e 's/\.csv/-cleaned\.csv/');
	echo infile: $infile
	echo outfile: $outfile
	echo "========================"
	#$infile $outfile

	outlier-remove.py AVG_READ_TIME AVG_WRITE_TIME READ_TIME WRITE_TIME  < "$infile" \
		|  flatten.py   AVG_READ_TIME AVG_WRITE_TIME READ_TIME WRITE_TIME  \
		> "$outfile"

done




