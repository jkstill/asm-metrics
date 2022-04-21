#!/usr/bin/env bash

echo $0

[ "$(dirname $0)" == '.' ] || {
	echo 
	echo Please run only from the directory where the script lives
	echo 
	exit 1
}

declare fullPath=$(pwd)
declare sourceDir=$(basename $fullPath)
declare excludeListFile=zip-exclude.txt

set -u

# do not get files ignored by git

while read item
do
	if [[ $item =~ \/$ ]]; then
		item="$item"'*'
	fi

	# skip if just single '?' or double '??'
	# this is used to skip single/double  letter files in git, but will translate to the directories  '.' and '..' here
	[[ $item == '?' ]] && { continue; }
	[[ $item == '??' ]] && { continue; }

	# expand the '?' git wildcard if necessary
	if [[ $item =~ '?' ]]; then
		echo "Exanding git wildcards to full file names" >&2
		echo " for this expression: $item" >&2

		for foundFile in $( find . -name "$item" )
		do
			echo  "Exclude: $sourceDir/$foundFile" >&2
			# the pattern must be exact for zip
			# bash will resolve dir/./dir/file, but zip will not
			echo "$sourceDir/$foundFile" | sed -e 's#/\./#/#g'
		done
	else	
		echo "$sourceDir/$item"
	fi


done < <(grep -vE "^\s*$|^\s*#" .gitignore ) > $excludeListFile

echo $excludeListFile

# do not include untracked files
while read untracked
do
	echo -n "$sourceDir/$untracked"
	if [[ $untracked =~ \/$ ]]; then
		echo '*'
	else
		echo ''
	fi
done < <(git status  -s --porcelain | cut -f2 -d' ' ) >> $excludeListFile

# do not include working files that are frequently a single letter
for item in $(find . -name "?" -type f)
do
	echo "$sourceDir/$item" | sed -e 's#/\./#/#g'
done >> $excludeListFile

# exclude a few others 
for exItem in afiedt.buf sqlnet.log
do
	for item in $(find . -name "$exItem" -type f)
	do
		echo "$sourceDir/$item" | sed -e 's#/\./#/#g'
	done >> $excludeListFile
done

# do not get .git
echo "$sourceDir/.git/*" >> $excludeListFile
echo "$sourceDir/$excludeListFile" >> $excludeListFile

echo Exclude File: $excludeListFile

cd ..

declare zipFile=asm-metrics.zip
rm -f $zipFile

echo "zip --symlinks -r $zipFile $sourceDir --exclude @$sourceDir/$excludeListFile"
#exit

zip --symlinks -r $zipFile $sourceDir --exclude @$sourceDir/$excludeListFile

engagementToolsDir='/mnt/zips/tmp/pythian/oracle-engagement-tools'

cp $zipFile $engagementToolsDir

echo 
echo "zip file locations"
echo

ls -ld $(pwd)/$zipFile
ls -ld $engagementToolsDir/$zipFile



