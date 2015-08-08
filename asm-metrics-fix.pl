#!/usr/bin/env perl

=head1 asm-metrics-fix.pl

 This script will correct snaptime values if present
 Negative elapsed times will also be fixed

 These occurred due to the bug where 'HH' was used in a timestamp conversion.
 The correct value in the timestamp format is 'HH24' and this has been corrected
 in asm-metrics-collector.pl

=cut


use strict;
use warnings;
use IO::File;

my $debug=0;
my $dateLen=19; # YYYY-MM-DD HH24:MI:SS results in a 19 character date 

# locations of column names in the row
# if snaptime is not in the data file,
# then remove or comment out the line

my %locations = (
	DISPLAYTIME => 0,
	SNAPTIME => 1,
	ELAPSEDTIME	 => 2
);

my $useSnaptime = exists ($locations{SNAPTIME}) ? 1 : 0;

warn "useSnaptime: $useSnaptime\n" if $debug;

my $delimiter=',';
my $inputFile='abc123';
my $fh;

while (<>) {

	my $newInputFile=$ARGV;
	if ($inputFile ne $newInputFile) {
		my $headers=<>;
		$inputFile=$newInputFile;
		# assuming here that filename has a '.csv' suffix
		my $flen = length($inputFile);
		my $outputFile=substr($inputFile,0,$flen-4) . '-corrected.csv';
		if (defined($fh)) {
			print $fh "\n";
		}
		$fh = IO::File->new();

		#open CSVOUT, '>', $outputFile or die "cannot create $outputFile - $!\n";
		$fh->open($outputFile,'>') or die "cannot create $outputFile - $!\n";
		print $fh $headers;
		next;
	}

	my $line=$_;
	my @row=split(/$delimiter/,$line);
	my ($displayTime, $snapTime, $elapsedTime);
	$displayTime=$row[$locations{DISPLAYTIME}];
	$elapsedTime=$row[$locations{ELAPSEDTIME}];

	if ($useSnaptime) {
		$snapTime=$row[$locations{SNAPTIME}];
		# detect incorrect snaptime by comparing just the first part of snaptime to display time
		# display time was always correct

		if ( substr($snapTime,0,$dateLen) ne $displayTime ) {
			warn qq[
###########################
Orig Disptime: $displayTime
Orig Snaptime: $snapTime
] if $debug;

		# 2015-06-23 01
		my $errHour=substr($snapTime,11,2);
		warn "Err Hour: $errHour\n" if $debug;
		my $newHour = $errHour + 12;
		warn "New Hour: $newHour\n" if $debug;
		substr($snapTime,11,2)=$newHour;
		warn "New  Snaptime: $snapTime\n" if $debug;

		$row[$locations{SNAPTIME}] = $snapTime;

		}
	}

	# the negative elapsed times occurred only the time went from 12:59.x to 13:00.x
	# subtracting the absolute value of elapsed time from 60 will correct the negative values

	if ($elapsedTime < 0 ) {
		warn "Old elapsedTime: $elapsedTime\n" if $debug;
		$elapsedTime = (60 - abs($elapsedTime));
		warn "New elapsedTime: $elapsedTime\n" if $debug;
		$row[$locations{ELAPSEDTIME}] = $elapsedTime;
	}

	print $fh join($delimiter,@row);
}



