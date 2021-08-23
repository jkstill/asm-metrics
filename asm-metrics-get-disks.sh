#!/usr/bin/env bash

usage () {

cat <<-EOF

Get the set of diskgroups and disks (disk number) from a csv file
 
EOF

}

declare csvFile="$1"

[[ -z $csvFile ]] && { echo "tell me which CSV file to use"; exit 1; }

[[ -r $csvFile ]] || { echo "cannot read file: $csvFile"; exit 2; }

# get the diskgroup name column position
dgColPos=$(head -1 "$csvFile" | awk -F, '{ for (i=1;i<=NF;i++) { if ($i == "DISKGROUP_NAME") print i } }')
diskColPos=$(head -1 "$csvFile" | awk -F, '{ for (i=1;i<=NF;i++) { if ($i == "DISK_NUMBER") print i } }')

# check the first 10k lines or EOF
tail -n +2 $csvFile | head -10000 | cut -f$dgColPos,$diskColPos -d, | sort -u | sort -t, -k2

