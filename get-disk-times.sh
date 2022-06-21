#!/usr/bin/env bash

# scale the histograms to reasonable length
declare readTimeScale=50
declare writeTimeScale=25

for file in db-diskgroup-breakout/*.csv
do
	echo "#############################################"
	echo "## $file"
	echo "#############################################"

	echo "   === AVG_READ_TIME "
	echo "   each '*' == $readTimeScale reads "
	echo 
	
	# adjust path to asm-time-histogram.sh as necessary
	./asm-time-histogram.sh -s $readTimeScale -t reads -f $file  | head -10
	echo '...'
	./asm-time-histogram.sh -s $readTimeScale -t reads -f $file  | tail -10

	echo 
	echo "   === AVG_WRITE_TIME "
	echo "   each '*' == $writeTimeScale writes "
	echo 

	./asm-time-histogram.sh -s $writeTimeScale -t writes -f $file  | head -10
	echo '...'
	./asm-time-histogram.sh -s $writeTimeScale -t writes -f $file  | tail -10


done

