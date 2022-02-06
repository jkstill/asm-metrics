#!/usr/bin/env bash

set -u

ASM_NAME=$(grep ^+ASM /etc/oratab | cut -d: -f1)
ASM_METRICS_HOME=$HOME/asm-metrics
DAYS_TO_COLLECT=1
INTERVAL_SECONDS=58
ITERATIONS_PER_DAY=1440

diskInfoFile="$1"

[[ -r $diskInfoFile ]] || {
	echo
	echo cannot read file $diskInfoFile
	echo
	exit 1
}

cd ~/asm-metrics || {
	echo
	echo Failed to CD to $"ASM_METRICS_HOME"
	echo 
	exit 1
}


declare pathFieldNumber
pathFieldNumber=$(head -1 $diskInfoFile | sed -r 's/\|/\n/g' | grep -n path | cut -f1 -d:)


# get the path, skip the header line
# some paths may be in the form of AFD:DATA001 or DATA002 for AFD or ASMLib
# ignore those

for diskPath in $(cut -d\| -f $pathFieldNumber $diskInfoFile | tail -n+2 | sort -u)
do
	[[ -r $diskPath ]] || { continue; }

	# get link ref, if any
	declare fullPath=$(readlink -f $diskPath)
	declare diskName=$(echo $fullPath | awk -F\/ '{ print $NF }' )

	echo -n "disk $fullPath: "

	if [[ -r /sys/block/$diskName/queue/scheduler ]]; then
		cat /sys/block/$diskName/queue/scheduler
	else
		echo "could not read /sys/block/$diskName/queue/scheduler"
	fi
done


