#!/bin/bash

# to get all data for all databases, run as the grid user, connecting to the ASM instance.

# as SYSASM is the default method
# run as grid
# assumes ~/asm-metrics

#: << 'AS-SYSASM'

# approximately 24 hours per collection
# with approximately a 0.45 second overhead we can get 4233 iterations per day at 20 second intervals

ASM_NAME=$(grep ^+ASM /etc/oratab | cut -d: -f1)
ASM_METRICS_HOME=$HOME/asm-metrics
DAYS_TO_COLLECT=3
INTERVAL_SECONDS=59
ITERATIONS_PER_DAY=1440

cd ~/asm-metrics || {
	echo
	echo Failed to CD to $"ASM_METRICS_HOME"
	echo 
	exit 1
}


mkdir -p logs

. /usr/local/bin/oraenv <<< $ASM_NAME

# get the disk info

declare timestamp=$(date +%Y%m%d-%H%M%S)

diskInfoFile=logs/asm-disk-info-${timestamp}.psv
diskSchedulerInfoFile=logs/asm-disk-scheduler-info-${timestamp}.log


sqlplus -L -S / as sysasm <<-EOF > $diskInfoFile

	@@asm-disk-info.sql
	exit

EOF

./asm-disk-queue-info.sh $diskInfoFile > $diskSchedulerInfoFile


for day in $(seq 1 $DAYS_TO_COLLECT)
do

	echo day: $day

	$ORACLE_HOME/perl/bin/perl ./asm-metrics-collector.pl --interval "$INTERVAL_SECONDS" --iterations "$ITERATIONS_PER_DAY" \
		--opt-cols ALL-COLUMNS \
		> logs/asm-data-$(date +%Y%m%d-%H%M%S).csv

done

#AS-SYSASM


: << 'SIMPLE'

# collect for an hour

cat password.txt | ./asm-metrics-collector.pl --interval 10 --iterations 1080 --database oravm --username system \
	--opt-cols DISK_NAME READ_ERRS \
	> logs/asm-oravm-data-$(date +%Y%m%d-%H%M%S).csv

SIMPLE



