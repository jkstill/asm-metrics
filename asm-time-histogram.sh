#!/usr/bin/env bash

: << 'EXPORT_VARS'

Interesting bit about export here.

In the Perl one liner, it is not necessary for ROWCOUNT to be exported

But, scalingFactor must be exported, or 'divide by zero' error occurs

Perhaps because scalingFactor is enclosed in parentheses, but ROWCOUNT is not?

EXPORT_VARS

usage () {

cat <<EOF

asm-time-histogram.sh

 -h help
 -t metric type - [reads|writes]
    default is reads
 -f ASM metric file
 -d diskgroup - defaults to all diskgroups
 -n disknumber - defaults to all disks
 -m max milliseconds to report on - defaults to 1000000
 -s scaling factor for displaying histogram
    defaults to 50
 -v verbose

 get the named metric from a CSV file
 count the number of occurrences
 print a histogram ordered (descending) by the metric value, with count, percentage  and histogram line


$  ./asm-time-histogram.sh  -f logs/asm-data-20220222-201322.csv

   10     250 1.42% *****
    9     297 1.69% *****
    8     335 1.91% ******
    7     386 2.20% *******
    6     378 2.15% *******
    5     568 3.24% ***********
    4    1456 8.29% *****************************
    3    1220 6.95% ************************
    2    1826 10.40% ************************************
    1    4841 27.58% ************************************************************************************************
    0    5448 31.04% ************************************************************************************************************

$  ./asm-time-histogram.sh -s 200 -f logs/asm-data-20220222-201322.csv

   10     250 1.42% *
    9     297 1.69% *
    8     335 1.91% *
    7     386 2.20% *
    6     378 2.15% *
    5     568 3.24% **
    4    1456 8.29% *******
    3    1220 6.95% ******
    2    1826 10.40% *********
    1    4841 27.58% ************************
    0    5448 31.04% ***************************

$  ./asm-time-histogram.sh -t writes -s 30 -d RECO -v -f logs/asm-data-20220222-201322.csv 

   metricName: AVG_WRITE_TIME
scalingFactor: 30
         file: logs/asm-data-20220222-201322.csv
     ROWCOUNT: 3248
  csvTempFile: /tmp/tmp.dFalBTmg2H

  188       1 0.03% 
  171       1 0.03% 
   55       1 0.03% 
   54       1 0.03% 
   45       1 0.03% 
   36       1 0.03% 
   33       2 0.06% 
   31       1 0.03% 
   20       1 0.03% 
   18       1 0.03% 
   17       4 0.12% 
   16       2 0.06% 
   15       1 0.03% 
   14       1 0.03% 
   13       5 0.15% 
   12       5 0.15% 
   11       6 0.18% 
   10       9 0.28% 
    9      12 0.37% 
    8      17 0.52% 
    7      34 1.05% *
    6      42 1.29% *
    5      89 2.74% **
    4     129 3.97% ****
    3     187 5.76% ******
    2     374 11.51% ************
    1    1123 34.58% *************************************
    0    1196 36.82% ***************************************


EOF

}

declare csvTempFile=$(mktemp)

cleanup () {
	rm -f $csvTempFile
}

trap 'cleanup' INT
trap 'cleanup' TERM

# do not allow unbound vars
# catches misspelled variables
set -u

declare metricName='AVG_READ_TIME'
declare asmMetricsFile
declare verbose=0
declare scalingFactor=50; export scalingFactor
declare diskGroup='.+'
declare diskNumber='.+'
declare maxMilliseconds=1000000; export maxMilliseconds

# lowercase the arg for -t
typeset -l arg

while getopts vzhs:t:f:d:n:m: arg
do
	case $arg in
		hz) usage;exit 0;;
		d) diskGroup=$OPTARG;;
		n) diskNumber=$OPTARG;;
		m) maxMilliseconds=$OPTARG;;
		f) asmMetricsFile=$OPTARG;;
		s) scalingFactor=$OPTARG;;
		t) [[ $OPTARG == 'writes' ]] && { metricName='AVG_WRITE_TIME'; } ;;
		v) verbose=1;;
		*) usage;exit 1;;
	esac
done

[[ -r $asmMetricsFile ]] || { echo "cannot open $asmMetricsFile"; exit 2; }

# do not know why there may be a line of '^0$'
grep -E "(^DISPLAYTIME|,$diskNumber,$diskGroup,)" $asmMetricsFile | grep -v '^0$'  > $csvTempFile

#ROWCOUNT=$(getcol.sh -d, -c $metricName -f <( grep -E "(^DISPLAYTIME|,$diskGroup+,)" $asmMetricsFile) | grep -v '^0$' | wc -l)
# exclude times of 0 as there was no read or write
ROWCOUNT=$(getcol.sh -d, -c $metricName -f $csvTempFile | grep -v '^0$' | wc -l)

export ROWCOUNT

[[ $verbose -ne 0 ]] && {
	echo 
	echo "   metricName: $metricName"
	echo "scalingFactor: $scalingFactor"
	echo "         file: $asmMetricsFile"
	echo "     ROWCOUNT: $ROWCOUNT"
	echo "  csvTempFile: $csvTempFile"
	echo 
}

#exit

getcol.sh -d, -c $metricName -f $csvTempFile \
	| grep -v '^0$'\
	| perl -p -e '$_ *= 1000; $_=int($_); $_ .= qq{\n}' \
	| sort -nr | uniq -c \
	| perl -wn -e 'chomp;s/^\s+//; ($count,$ms)=split(/\s+/);printf(qq{%5d %7d %3.2f%% %s\n}, $ms, $count, $count / $ENV{ROWCOUNT} * 100, q{*} x ( $count /  $ENV{scalingFactor})) if $ms <= $ENV{maxMilliseconds}'

cleanup



