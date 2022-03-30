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

print "\n";

foreach my $dgName ( sort keys %iops ) {

	my $totalElapsedTime=0;
	foreach my $dgElapsedKey ( keys %elapsedTimes ) {
		my %dgElapsedTimes = %{$elapsedTimes{$dgElapsedKey}};
		
		foreach my $displayTime ( keys %dgElapsedTimes ) {
			eval {
				use warnings 'FATAL';
				$totalElapsedTime += $dgElapsedTimes{$displayTime};
			};
			if ($@) {
				warn "ERROR!\n";
				warn "$@\n";
				warn 'DATA:  $dgElapsedTimes{$displayTime}:  ' .  $dgElapsedTimes{$displayTime} . "\n";
			}
		}
	}

	#print "$dgName: totalElapsedTime: $totalElapsedTime\n";

	my %tmpIops = %{$iops{$dgName}};

	$Data::Dumper::Varname = $dgName;
	#print Dumper(\%tmpIops);

	my $iops = ($tmpIops{reads} +  $tmpIops{writes})  / $totalElapsedTime;

	printf("dg %15s | reads: %12d | writes: %12d | time: %8d | iops: %9d\n",$dgName, $tmpIops{reads}, $tmpIops{writes}, $totalElapsedTime,  $iops);

}


