#!/usr/bin/env bash

set -u

# get a column by name from a CSV file
# the CSV file must of course have a header line of column names

declare csvDelimiter=''
declare columnName=''
declare csvFile=''
declare skipLineCount=2;
declare getHdrAndExit='N'

help () {

	cat <<-EOF

 -d delimiter (single character) - omit this option for TAB delimited
 -f filename - use quotes if there are spaces in the file name
 -c column name - use quotes if there are spaces in the column name
 -g get the file header, display and exit script
 -s show column header in output
 -h help

EOF

}

while getopts d:f:c:gsh arg
do
	case $arg in
		h) help; exit 0;;
		d) csvDelimiter=" -d $OPTARG ";;
		g) getHdrAndExit='Y'; columnName='dummy';; # dummy to bypass check further down for columname being empty
		c) columnName=$OPTARG;;
		s) skipLineCount=0;;
		f) csvFile=$OPTARG;;
		*) help; exit 1;;
	esac
done

#echo "delimiter: $csvDelimiter"

# if process substitution is used, this script returns incorrect results
# that is because process substitution is a pipe
# the file is read twice, which does not work properly without a real file
# eg.  -f <(grep . somefile)

[[ -r $csvFile ]] || { echo "cannot open $csvFile"; exit 1; }
readlink $csvFile | cut -f1 -d: | grep --silent '^pipe' && { echo "$0 does not work with a pipe"; exit 1; }

[[ -z $columnName ]] && { echo "columnName is empty"; exit 2; }

declare header=$(head -1 $csvFile)
declare searchColName=''
declare searchColNum=0

#echo "$header" # if not quoted, the tabs are converted to spaces
cutCmd="cut $csvDelimiter" 

#echo "cutCmd: $cutCmd"

for i in {1..255}
do
	# $header MUST be quoted
	declare currColName="$(echo "$header" | eval $cutCmd -f$i )"
	if [[ -z $currColName ]]; then
		if [[ $getHdrAndExit == 'Y' ]] ; then
			exit 0;
		else
			break
		fi
	fi		

	[[ $getHdrAndExit == 'Y' ]] && { echo "$i: $currColName"; }

	[[ $currColName == $columnName ]] && { 
		searchColName=$currColName
		searchColNum=$i
		if [[ $getHdrAndExit == 'Y' ]] ; then
			continue
		else
			break; 
		fi
	}
done

[[ -z $searchColName ]] && { echo "column $columnName not found"; exit 3; }

#tail -n+$skipLineCount <(cut -d"$csvDelimiter" -f$searchColNum $csvFile)
tail -n+$skipLineCount <(eval $cutCmd -f$searchColNum $csvFile)

