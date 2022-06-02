#!/usr/bin/env bash

banner () {
	local msg="$@"
	echo "#################################################"
	echo "## $msg"
	echo "#################################################"
	return
}

# this script should operate in the asm-metrics directory

# why 'ls -1' rather than 'echo'
# if there are no files, then the value of '${csvFiles[0]}' will be 'logs/asm-data*.csvd'
# empty string is preferred for checking
readarray csvFiles  < <(ls -1 logs/asm-data*.csv 2>/dev/null)
hdrFile=${csvFiles[0]}

maxMilliseconds=1000000
histogramScale=100

[ -z $hdrFile ] && { echo "No asm metrics files found"; exit 1; }

for dg in $(getcol.sh -d, -c DISKGROUP_NAME -f $hdrFile   | sort -u)
do
	for ioType in reads writes
	do
		banner "DiskGroup $dg - $ioType"
		./asm-time-histogram.sh -d $dg -s $histogramScale  -m $maxMilliseconds  -t $ioType -f <( head -1 $hdrFile; tail -q -n+2 logs/asm-data*.csv)
	done
done

