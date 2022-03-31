#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;

# for use with asm-metrics CSV files created by the diskgroup-breakout script

my $debug=0;
my $debugInterval=1000;

my %iops=();
my %elapsedTimes=();

# expecting display time, elapsed time, diskgroup name, reads, writes, bytes_read, bytes_written
while(<STDIN>) {
	chomp;
	my ($date, $time, $elapsedTime, $dgName, $reads, $writes, $bytesRead, $bytesWritten) = split(/,/);
	my $displayTime = "$date $time";

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

#print "\n";
#$Data::Dumper::Varname = 'iops';
#print Dumper(\%iops);
#$Data::Dumper::Varname = 'elapsedTimes';
#print Dumper(\%elapsedTimes);
#exit;
#print "\n";

foreach my $dgName ( sort keys %iops ) {

	print "diskgroup: $dgName\n" if $debug;
	#next;

	my $totalElapsedTime=0;

	my %dgElapsedTimes = %{$elapsedTimes{$dgName}};
		
	#$Data::Dumper::Varname = $dgName;
	#print Dumper(\%dgElapsedTimes);

	foreach my $dgDisplayTime ( keys %dgElapsedTimes ) {
		$totalElapsedTime += $dgElapsedTimes{$dgDisplayTime};
		printf("   $dgDisplayTime   totalElapsedTime: %9d\n",$totalElapsedTime) if $debug;
	}

	print "$dgName: totalElapsedTime: $totalElapsedTime\n" if $debug;

	#next if $debug;

	my %tmpIops = %{$iops{$dgName}};

	$Data::Dumper::Varname = $dgName;
	#print Dumper(\%tmpIops);

	my $iops = ($tmpIops{reads} +  $tmpIops{writes})  / $totalElapsedTime;

	printf("dg %-20s | reads: %12d | writes: %12d | time: %8d | iops: %9d\n",$dgName, $tmpIops{reads}, $tmpIops{writes}, $totalElapsedTime,  $iops);

}


