#!/usr/bin/env perl
#

use strict;
use warnings;

my $headers=<>;

print "headers: $headers\n";

chomp $headers;

my @hdrs=split(/,/,$headers);
# these values may need to be adjusted, dependent on the columns in the file
# this works for the following sample headers:
# headers: DISPLAYTIME,SNAPTIME,ELAPSEDTIME,INSTNAME,DBNAME,GROUP_NUMBER,DISK_NUMBER,DISKGROUP_NAME,READS,WRITES,READ_TIME,AVG_READ_TIME,WRITE_TIME,AVG_WRITE_TIME,BYTES_READ,BYTES_WRITTEN,DISK_NAME,READ_ERRS,WRITE_ERRS

my @chkColNames = ($hdrs[2], $hdrs[8], @hdrs[9..15]);

# just verify the names
print 'chkColNames: ', join(' - ', @chkColNames), "\n";

my @chkCols=(2,8,9,10,11,12,13,14,15);

my $minThreshold = 0;
print "\nThreshold: values < $minThreshold\n\n";

my $previousLine='';

my $i=1;
while (<>) {
	next if /^DISPLAYTIME/;

	chomp;
	my $line=$_;
	my @row=split(/,/,$line);

	#print "ROW: ", join(' - ',@row), "\n";
	foreach my $chkCol (@chkCols) {
		my $chkVal = $row[$chkCol];
		if ($row[$chkCol] < $minThreshold) {
			print "Chk: $hdrs[$chkCol] - $row[$chkCol]\n";
			print "File: $ARGV\n";
			print "Line: $.\n";
			print "HDRS: $headers\n";
			print "PREV: $previousLine\n";
			print "ERR : $line\n";
			print '#' x 100, "\n";
			last;
		}
	}


	$previousLine=$line;
	$i++;
	
	#last if $i >= 1000;
}

print "count: $i\n"

