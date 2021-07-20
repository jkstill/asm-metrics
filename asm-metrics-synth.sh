#!/usr/bin/env bash

mkdir -p synth

for infile in output/*.csv
do
	outfile=$(echo $infile | sed -e 's/output/synth/');
	echo working on $outfile
	asm-metrics-synth.pl $infile $outfile
done


