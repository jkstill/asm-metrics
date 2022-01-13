#!/usr/bin/env bash

# copy these scripts to bin
# adjust values as needed

# top-level directory where the ASM Metrics files are located

homeDir=/mnt/zips/tmp/presentations/asm-metrics
# where the scripts are located
binDir=/mnt/zips/tmp/presentations/asm-metrics

cd $homeDir

export PATH="$binDir":"$PATH"

# set this if you have copied and modified scripts to the homeDir location
export PATH="$homeDir":"$PATH"

: <<'COMMENT'

Assume that metrics were collected from several clusters,

the directory structure looks like this:

cluster-01/logs
cluster-02/logs
...

COMMENT

for clusterDir in cluster-*
do
	echo "#########################################################"
	echo "dir: $clusterDir"
	cd $clusterDir
	[[ $? -ne 0 ]] && {
		echo failed to cd to $clusterDir
		exit 1
	}

	echo "running: asm-metrics-aggregator-loop.sh"
	$binDir/asm-metrics-aggregator-loop.sh


	echo "running: asm-metrics-synth.sh"
	$binDir/asm-metrics-synth.sh
	echo "running: asm-diskgroup-breakout.sh"
	$binDir/asm-diskgroup-breakout.sh
	#echo "running: asm-metrics-cleaned.sh"
	#$binDir/asm-metrics-cleaned.sh
	echo "running: asm-metrics-chart-synth.sh"
	$binDir/asm-metrics-chart-synth.sh
	#echo "running: asm-metrics-chart-cleaned.sh"
	#$binDir/asm-metrics-chart-cleaned.sh


	cd $homeDir

done


