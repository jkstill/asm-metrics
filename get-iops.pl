#!/usr/bin/env perl

# for use on raw asm-metrics CSV files

use warnings;
use strict;
use Data::Dumper;

my $debug=0;
my $debugInterval=1000;

my %iops=();
my %elapsedTimes=();

# expecting display time, elapsed time, diskgroup name, reads, writes, bytes_read, bytes_written
while(<STDIN>) {
	chomp;
	my ($displayTime, $elapsedTime, $dgName, $reads, $writes, $bytesRead, $bytesWritten) = split(/,/);

	print qq{
 display time: $displayTime
      dg name: $dgName
      elapsed: $elapsedTime
        reads: $reads
       writes: $writes
   bytes read: $bytesRead
bytes written: $bytesWritten
=============================================} if ( ($debug) && ( $. % $debugInterval == 0 ));

	$elapsedTimes{$dgName}->{$displayTime} = $elapsedTime; # unless exists($elapsedTimes{$displayTime});

	$iops{$dgName}->{reads} += $reads;
	$iops{$dgName}->{writes} += $writes;
	$iops{$dgName}->{bytesRead} += $bytesRead;
	$iops{$dgName}->{bytesWritten} += $bytesWritten;

}

#$Data::Dumper::Varname = 'elapsedTimes';
#print Dumper(\%elapsedTimes);
#print "\n";
#exit;

foreach my $dgName ( sort keys %iops ) {

	#print "dg: $dgName\n";

	my $totalElapsedTime=0;

	my %dgElapsedTimes = %{$elapsedTimes{$dgName}};
			
	# sorted output is nice for debugging
	#foreach my $displayTime ( sort { $a cmp $b } keys %dgElapsedTimes ) {
	foreach my $displayTime ( keys %dgElapsedTimes ) {
		$totalElapsedTime += $dgElapsedTimes{$displayTime};
		#print "  $displayTime  $totalElapsedTime\n";
	}

	#print "$dgName: totalElapsedTime: $totalElapsedTime\n";

	my %tmpIops = %{$iops{$dgName}};

	$Data::Dumper::Varname = $dgName;
	#print Dumper(\%tmpIops);

	my $iops = ($tmpIops{reads} +  $tmpIops{writes})  / $totalElapsedTime;

	printf("dg %-20s | reads: %12d | writes: %12d | time: %8d | iops: %9d\n",$dgName, $tmpIops{reads}, $tmpIops{writes}, $totalElapsedTime,  $iops);

}


