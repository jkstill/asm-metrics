#!/usr/bin/env bash


mkdir -p diskgroup-breakout

# get diskgroup names

testfile=$(ls -1 synth/*.csv | head -1)

declare -A outfiles;

for diskgroup in $( tail -n +2 $testfile |  head -100000  |  cut -f4 -d,| sort -u )
do
	outfiles[$diskgroup]=diskgroup-breakout/${diskgroup}.csv
done

for dg in ${!outfiles[@]}
do
	 head -1 $testfile > ${outfiles[$dg]}
done

for infile in synth/*.csv
do
	echo working on $infile

	for dg in ${!outfiles[@]}
	do
		grep ",$dg," $infile >> ${outfiles[$dg]}
	done

done


