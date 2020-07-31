#!/bin/bash

# to get all data for all databases, run as the grid user, connecting to the ASM instance.

: << 'AS-SYSASM'

cd ~/asm-metrics
mkdir -p logs

. /usr/local/bin/oraenv <<< +ASM1

# approximately 24 hours per collection
# with approximately a 0.4 second overhead we can get 4233 iterations per day at 20 second intervals

for day in {1..10}
do

	echo day: $day

	$ORACLE_HOME/perl/bin/perl ./asm-metrics-collector.pl --interval 20 --iterations 4233 \
		--opt-cols ALL-COLUMNS \
		> logs/asm-data-$(date +%Y%m%d-%H%M%S).csv

done

AS-SYSASM



# collect for an hour

cat password.txt | ./asm-metrics-collector.pl --interval 10 --iterations 1080 --database oravm --username jkstill \
	--opt-cols DISK_NAME READ_ERRS \
	> logs/asm-oravm-data-$(date +%Y%m%d-%H%M%S).csv



