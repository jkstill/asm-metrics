#!/bin/bash

# to get all data for all databases, run as the ASM owner (usually grid), connecting to the ASM instance.
# as SYSASM is the default method

# approximately 24 hours per collection
# with approximately a 0.45 second overhead we can get 4233 iterations per day at 20 second intervals
#

usage () {

cat <<-EOF

There are several variables that can be set in the environment or on the command line:

              HELP:  If set to 'Y' or 'y', this message will be displayed and the script will exit.
           DRY_RUN:  If set to 'Y' or 'y', the script will exit after displaying the variables that have been set.
   DAYS_TO_COLLECT:  The number of days to collect data.  Default is 3.
  INTERVAL_SECONDS:  The number of seconds between each collection.  Default is 59.
ITERATIONS_PER_DAY:  The number of iterations per day.  Default is 1440.

Examples:

Use defaults:

  nohup ./asm-metrics-collector.sh &

Set all of the variables to non-default values:

<<<<<<< HEAD
  nohup DAYS_TO_COLLECT=5 INTERVAL_SECONDS=30 ITERATIONS_PER_DAY=2880 ./asm-metrics-collector.sh &
=======
  DAYS_TO_COLLECT=5 INTERVAL_SECONDS=30 ITERATIONS_PER_DAY=2880 nohup ./asm-metrics-collector.sh &
>>>>>>> 57df1ae (corrected use of nohup)

Help:

  HELP=Y ./asm-metrics-collector.sh

EOF

}

: ${HELP:='N'}

if [ "$HELP" = 'Y' -o "$HELP" = 'y' ]
then
	usage
	exit 0
fi

# with default sort, +ASM[1-9] will appear before +ASM if both exist
ASM_NAME=$(grep ^+ASM /etc/oratab | sort | head -1 |  cut -d: -f1)

ASM_METRICS_HOME=$(dirname -- "$( readlink -f -- "$0"; )")
cd $ASM_METRICS_HOME || { echo "could not cd to '$ASM_METRICS_HOME'"; exit 1; }

# with default sort, +ASM[1-9] will appear before +ASM if both exist
ASM_NAME=$(grep ^+ASM /etc/oratab | sort | head -1 |  cut -d: -f1)

: ${DRY_RUN:=N}
: ${DAYS_TO_COLLECT:=3}
: ${INTERVAL_SECONDS:=59}
: ${ITERATIONS_PER_DAY:=1440}

cd $ASM_METRICS_HOME || {
	echo
	echo Failed to CD to $"ASM_METRICS_HOME"
	echo 
	exit 1
}

cat <<-EOF

             ASM_NAME=$ASM_NAME
                 HELP=$HELP
              DRY_RUN=$DRY_RUN
     ASM_METRICS_HOME=$ASM_METRICS_HOME
      DAYS_TO_COLLECT=$DAYS_TO_COLLECT
     INTERVAL_SECONDS=$INTERVAL_SECONDS
   ITERATIONS_PER_DAY=$ITERATIONS_PER_DAY

EOF

if [ "$DRY_RUN" = 'Y' -o "$DRY_RUN" = 'y' ]
then
	exit 0
fi

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



