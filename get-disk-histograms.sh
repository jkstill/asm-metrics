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

histogramScale=20

#for csvFile in ${csvFiles[@]}
#do
	#echo file: $csvFile
#done

[ -z $hdrFile ] && { echo "No asm metrics files found"; exit 1; }

# histograms per disk

for dg in $(getcol.sh -c DISKGROUP_NAME -f $hdrFile   | sort -u)
do
	for diskNumber in  $(cut -d, -f7,8 $hdrFile | grep ",$dg" | cut -d, -f1 | sort -u -n)
	do
		for ioType in reads writes
		do
			banner "DiskGroup $dg:$diskNumber - $ioType"
			./asm-time-histogram.sh -d $dg -n $diskNumber -s $histogramScale  -t $ioType -f <( head -1 $hdrFile; tail -q -n+2 ${csvFiles[@]} )
		done
	done
done

