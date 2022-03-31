#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;

# based on format of diskgroup-breakout files

=head1 fields

 subtract 1 for perl

 1: DATE
 2: TIME
 3: ELAPSEDTIME
 4: DISKGROUP_NAME
 5: AVG_READ_TIME
 6: AVG_WRITE_TIME
 7: READS
 8: WRITES
 9: READ_TIME
 10: WRITE_TIME
 11: BYTES_READ
 12: BYTES_WRITTEN
 13: READ_ERRS
 14: WRITE_ERRS

=cut 

my $header=<STDIN>;
chomp $header;
$header .= ',IOPS,IOPS_SZ_SEC';

print "$header\n";

while (<STDIN>) {
	chomp;

	#my ($date, $time, $elapsedTime, $diskGroupName, $avgReadTime, $avgWriteTime, $reads, $writes,
	#$readTime, $writeTime, $bytesRead, $bytesWritten, $readErrors, $writeErrors) = split(/,/);
	#

	my @data = split(/,/);

	my $ioSzSec = ($data[10] +  $data[11]) / $data[2];
	
	my $iops = ($data[6] +  $data[7]) / $data[2];

	#print "iops: $iops  sz: $ioSzSec\n";
	push @data,($iops,$ioSzSec);

	print join(',',@data) . "\n";
}
