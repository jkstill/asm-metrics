#!/usr/bin/env bash

mkdir -p db-diskgroup-synth

for infile in db-diskgroup/*.csv
do
	outfile=$(echo $infile | sed -e 's/db-diskgroup/db-diskgroup-synth/');
	echo working on $outfile
	asm-metrics-db-diskgroup-synth.pl $infile $outfile
done


