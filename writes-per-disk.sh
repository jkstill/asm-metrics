#!/usr/bin/env bash

# use after running asm-metrics-aggregator_bydisk.sh

diskGroupName=DATA_T1_01

for disknum in $(grep ",$diskGroupName," logs/asm-data-20220525-194006.csv | cut -f7 -d,| sort -nu)
do
   echo "#########################"
   echo "##### Disk $disknum"
   echo "#########################"
   ./asm-time-histogram.sh -n $disknum -s 100  -t writes -f <( head -1 logs/asm-data-20220524-200045.csv; grep ",$disknum,$diskGroupName," logs/asm-data*.csv)
done | tee writes-by-disk-DATA_T1_01.log
