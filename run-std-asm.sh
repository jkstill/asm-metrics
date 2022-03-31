#!/usr/bin/env bash

# copy these scripts to binDir
# adjust values as needed

# full path required
homeDir=/mnt/zips/tmp/health-check-data/servers
binDir=/mnt/zips/tmp/health-check-data/bin

cd $homeDir || { echo "could not cd to $homeDir"; exit 1; }
[ -d $binDir ] || { echo "$binDir does not exist or is not a directory"; exit 1; }

export PATH=$HOME/oracle/health_check/asm-metrics:$binDir:$PATH

# some scripts use some python scripts to manipulate data
eval "$(conda shell.bash hook)"
conda activate base

for metricDir in server00?/asm-metrics_data
do
	echo "#########################################################"
	echo "dir: $metricDir"
	cd $metricDir
	[[ $? -ne 0 ]] && {
		echo failed to cd to $metricDir
		exit 1
	}
	echo -n 'PWD: '
	pwd

	echo "running: asm-metrics-aggregator-loop.sh"
	$binDir/asm-metrics-aggregator-loop.sh
	echo "running: asm-metrics-synth.sh"
	$binDir/asm-metrics-synth.sh
	echo "running: asm-diskgroup-breakout.sh"
	$binDir/asm-diskgroup-breakout.sh
	echo "running: asm-metrics-cleaned.sh"
	$binDir/asm-metrics-cleaned.sh
	echo "running: asm-metrics-chart-synth.sh"
	$binDir/asm-metrics-chart-synth.sh
	echo "running: asm-metrics-chart-cleaned.sh"
	$binDir/asm-metrics-chart-cleaned.sh
	
	cd $homeDir

done


