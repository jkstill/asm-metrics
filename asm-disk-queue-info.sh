#!/usr/bin/env bash

set -u

# with default sort, +ASM[1-9] will appear before +ASM if both exist
ASM_NAME=$(grep ^+ASM /etc/oratab | sort | head -1 |  cut -d: -f1)
SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR || { echo "could not cd to '$SCRIPT_DIR'"; exit 1; }
ASM_METRICS_HOME=$(pwd)

diskInfoFile="$1"

[[ -r $diskInfoFile ]] || {
	echo
	echo cannot read file $diskInfoFile
	echo
	exit 1
}

cd $ASM_METRICS_HOME || {
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


