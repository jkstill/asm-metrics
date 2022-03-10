#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

# data incoming
# timestamp,disknum,time 

my %msBuckets = ();
my $bucketSize = 5;

while (<STDIN>) {
	chomp;
	my $time = $_;
	#print "time: $time\n";

	# convert to milliseconds
	
	#push @{$timestamps{$timestamp}}, $time * 1000;
	#
	my $ms;

	eval {
		$ms = $time * 1000;
	};

	if ($@) {
		print "line: $.\n";
		print "time: $time\n";
	}

	my $bucket;
	if ($ms == 0 ) {	
		$bucket=0;
	} else  {
		$bucket = int($ms - ($ms % $bucketSize)) + $bucketSize;
	}

	#print "$ms $bucket\n";

	$msBuckets{$bucket}++;
	
}

#print Dumper(\%msBuckets);

#foreach my $bucket ( sort { $msBuckets{$a} <=> $msBuckets{$b} } keys %msBuckets )  {
#print "$bucket: $msBuckets{$bucket}\n";
#}
  
print "bucket,count\n";

foreach my $bucket ( sort { $a <=> $b } keys %msBuckets )  {
	print "$bucket,$msBuckets{$bucket}\n";
}

