#!/usr/bin/env bash

# set the location as needed
# top-level directory where the ASM Metrics files are located
homeDir=/tmp/some-client/asm-metrics
# where the scripts are located
binDir=$HOME/asm-metrics/bin


cd $homeDir

export PATH="$binDir":"$PATH"

# set this if you have copied and modfied scripts to the homeDir location
export PATH="$homeDir":"$PATH"

: <<'COMMENT'

Assume that metrics were collected from several clusters,

the directory structure looks like this:

cluster-01/
  node-01/
  node-02/
  node-03/
cluster-02
  node-01/
  node-02/
  node-03/
  node-04/
...

COMMENT

for metricDir in cluster-*
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


