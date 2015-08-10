#!/bin/bash

# collect for an hour

cat password.txt | ./asm-metrics-collector.pl --interval 10 --iterations 1080 --database oravm --username jkstill \
	--opt-cols DISK_NAME READ_ERRS \
	> logs/asm-oravm-data-$(date +%Y%m%d-%H%M%S).csv

