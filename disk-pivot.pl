#!/usr/bin/perl

=head1 disk-pivot.pl

=head2 pivot avg writetimes per  disk

 Transform this layout

 timestamp diskname  metric1 metric2 metric3

 To this layout

 timestamp disk1 disk2 disk3 ...
 metric

 In this case the metric is avg_wrt_time, but it can be any metric


=cut

use warnings;
use strict;
use Data::Dumper;

my @timestamps=();

my %diskData=();

my $hdr = <STDIN>;

chomp $hdr;
my @hdr = split(/,/,$hdr);

while(<STDIN>) {
	chomp;
	my ($timestamp, $avgReadTime, $avgWriteTime, $diskName) = split(/,/);
	push @timestamps, $timestamp unless grep(/$timestamp/,@timestamps);

	#push @{$diskData{$timestamp}->{$diskName}}, $avgWriteTime;
	$diskData{$timestamp}->{$diskName} =  $avgWriteTime;

}

#print Dumper(\%diskData);

my @diskNames;

foreach my $timestamp ( @timestamps ) {

	my %times = %{$diskData{$timestamp}};

	#print Dumper(\%times);
	#die;

	if (! defined $diskNames[0] ) {
		@diskNames = map{ $_ } sort keys %times;
		print 'timestamp,' . join(',',@diskNames) . "\n";
	}

	print "$timestamp";
	foreach my $diskName ( @diskNames ) {
		print ",$times{$diskName}";
	}
	print "\n";
}

#print Dumper(\@diskNames);
