#!/bin/bash

# verify some data to see if report matches what is found in the file
# as shown by asm-metrics-aggregator.pl for file logs/asm-oravm-20150511_03.csv

METRICSFILE='logs/asm-oravm-20150511_03.csv'
SNAPSHOT='2015-05-11 15:43:58'
KEY='oravm1.*,DATA'

#head -1 logs/asm-oravm-20150511_03.csv

# Col  position
READS=29
WRITES=30
ELAPSEDTIME=3
READ_TIME=33
WRITE_TIME=35

read_time=0
for i in $(grep "$SNAPSHOT" $METRICSFILE | grep "$KEY" | cut -d, -f $READ_TIME)
do
	read_time=$(echo "$read_time + $i" | bc)
done

echo Read Time: $read_time


total_reads=0
for i in $(grep "$SNAPSHOT" $METRICSFILE | grep "$KEY" | cut -d, -f $READS)
do
	(( total_reads += i))	
done

echo Total Reads: $total_reads

################

write_time=0
for i in $(grep "$SNAPSHOT" $METRICSFILE | grep "$KEY" | cut -d, -f $WRITE_TIME)
do
	write_time=$(echo "$write_time + $i" | bc)
done

echo Write Time: $write_time


total_writes=0
for i in $(grep "$SNAPSHOT" $METRICSFILE | grep "$KEY" | cut -d, -f $WRITES)
do
	(( total_writes += i))	
done

echo Total Writes: $total_writes

#################

elapsed_time=0
for i in $(grep "$SNAPSHOT" $METRICSFILE | grep $KEY | cut -d, -f $ELAPSEDTIME)
do
	elapsed_time=$(echo "$elapsed_time + $i" | bc)
done

echo Elapsed Time: $elapsed_time



