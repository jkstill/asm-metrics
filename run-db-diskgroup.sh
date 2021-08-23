#!/usr/bin/env bash

homeDir=/mnt/zips/tmp/pythian/opentext/sow7/asm-metrics-august
binDir=/mnt/zips/tmp/pythian/opentext/sow7/bin

cd $homeDir || { echo "could not cd to $homeDir"; exit 1; }

export PATH=/home/jkstill/oracle/health_check/asm-metrics:$PATH
export PATH=/mnt/zips/tmp/pythian/opentext/sow7/bin:$PATH

#for metricDir in all-dbrac* lit-dbrac*
for metricDir in lit-dbrac12
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

# from runall.sh
: << 'COMMENT'
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
COMMENT


	#echo "running: asm-metrics-aggregator-db-diskgroup.sh"
	echo $binDir/asm-metrics-aggregator-db-diskgroup.sh


	echo "running: asm-metrics-db-diskgroup-synth.sh"
	echo $binDir/asm-metrics-db-diskgroup-synth.sh

	echo "running: asm-db-diskgroup-breakout.sh"
	echo $binDir/asm-db-diskgroup-breakout.sh

	echo "running: asm-metrics-chart-db-diskgroup-synth.sh"
	$binDir/asm-metrics-chart-db-diskgroup-synth.sh

	cd $homeDir

done


