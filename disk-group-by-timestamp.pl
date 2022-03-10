#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

# this will be a hash of arrays
# 18 times per each timestamp in this case
my %timestamps=();

# data incoming
# timestamp,disknum,time 

while (<STDIN>) {
	chomp;
	my ($timestamp,$disknum,$time) = split(/,/);
	# convert to milliseconds
	push @{$timestamps{$timestamp}}, $time * 1000;
}

my @keys =  sort keys %timestamps;
#print Dumper(\@keys);

my @hdrCount=@{$timestamps{$keys[0]}};

my $hdrString='timestamp,';
foreach my $disknum ( 0 .. $#hdrCount ) {
	$hdrString .= "disk $disknum,";
}

print substr($hdrString,0,length($hdrString)-1) . "\n";


foreach my $metricTime ( @keys ) {
	print "$metricTime," . join(',', @{$timestamps{$metricTime}}) . "\n";
}

