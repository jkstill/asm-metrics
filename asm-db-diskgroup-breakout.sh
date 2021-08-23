#!/usr/bin/env bash


mkdir -p db-diskgroup-breakout

# get diskgroup names

testfile=$(ls -1  db-diskgroup-synth/*.csv | head -1)

declare -A outfiles;
declare -a databases
declare -a diskgroups

# add db to this
declare i=0
for db in $( tail -n +2 $testfile |  head -100000  |  cut -f5 -d,| sort -u )
do
	databases[$i]=$db
	(( i++ ))
done

i=0
for diskgroup in $( tail -n +2 $testfile |  head -100000  |  cut -f4 -d,| sort -u )
do
	diskgroups[$i]=$diskgroup
	(( i++ ))
done

for diskgroup in ${diskgroups[@]}
do
	for db in ${databases[@]}
	do
		outfiles[$diskgroup:$db]=db-diskgroup-breakout/${diskgroup}-${db}.csv
	done
done

for dg in ${!outfiles[@]}
do
	 head -1 $testfile > ${outfiles[$dg]}
done

#: << 'COMMENT'

for infile in db-diskgroup-synth/*.csv
do
	echo working on $infile

	for dgdb in ${!outfiles[@]}
	do
		declare filename=$(basename $dgdb)
		declare dg=$(echo $filename | cut -f1 -d:)
		declare db=$(echo $filename | cut -f2 -d:)
		echo "dg: $dg db: $db"
		grep -E  ",$dg,$db," $infile >> ${outfiles[$dgdb]}
	done

done

#COMMENT
