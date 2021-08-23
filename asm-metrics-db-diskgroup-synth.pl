#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use IO::File;

my $debug=0;

my ($inputFile, $outputFile) = @ARGV;

-r $inputFile || die "cannot open $inputFile - $!\n";

my $fhIn=IO::File->new;
my $fhOut=IO::File->new;

$fhIn->open($inputFile,'r');
$fhOut->open($outputFile,'w') or die "Cannot write $outputFile - $!\n";

my $hdr=<$fhIn>;

#print "hdr: $hdr\n"; # debug

my @hdrCols=split(/,/,$hdr);

splice @hdrCols,7,0,qw(AVG_READ_TIME );
splice @hdrCols,9,0,qw(AVG_WRITE_TIME );
splice @hdrCols,0,1,qw(DATE TIME);

#print 'Cols: ' . join(' - ', @hdrCols) . "\n";

print $fhOut join(',',@hdrCols);
print join(',',@hdrCols)."\n"; # debug

#exit; #debug

while (<$fhIn>) {
	#print;
	chomp;
	my @data=split(/,/);
	my ($date, $time) = split(/\s+/,$data[0]);
	my ($reads,$writes,$readTime,$writeTime) = @data[4..7];
	$reads = 0 unless $reads;
	$writes = 0 unless $writes;
	$readTime = 0 unless $readTime;
	$writeTime = 0 unless $writeTime;

	print qq{
       reads: $reads
   read time: $readTime
      writes: $writes
  write time: $writeTime

	} if $debug;

	my ($avgReadTime, $avgWriteTime) = (0,0);

	if ( $reads > 0 ) { $avgReadTime = sprintf("%3.6f",$readTime / $reads) }
	if ( $writes > 0 ) { $avgWriteTime = sprintf("%3.6f",$writeTime / $writes) }


	splice @data,7,0,($avgReadTime);
	splice @data,9,0,($avgWriteTime);
	splice @data,0,1,($date,$time);

	print $fhOut join(',',@data) . "\n";

}

