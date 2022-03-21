#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;

=head1 get-slow-writes-hist.pl

 This script prints lines from ASM Metrics data when the write time is 3.0 seconds or more

 The previous 5 lines are also printed for that disk.


   $  head -1 asm-data-20220110-065458.csv > asm-fra01-slow-writes.csv
   $  grep -h ',dbp004,.*,FRA01,' asm-data*.csv |  ./get-slow-writes-hist.pl >> asm-fra01-slow-writes.csv

 Sample the data

   $  cut -d, -f1,7,8,14 asm-fra01-slow-writes.csv | head -30
   DISPLAYTIME,DISK_NUMBER,DISKGROUP_NAME,AVG_WRITE_TIME
   2022-01-09 07:47:46,1,FRA01,0.151036499999464
   2022-01-09 07:48:45,1,FRA01,0.00115562500104716
   2022-01-09 07:49:44,1,FRA01,0.00105226829274637
   2022-01-09 07:50:43,1,FRA01,0.00102099999882436
   2022-01-09 07:51:42,1,FRA01,3.00137900000846
   2022-01-09 07:50:43,5,FRA01,0.00106599999708124
   2022-01-09 07:51:42,5,FRA01,0
   2022-01-09 07:52:41,5,FRA01,0.429843142857343
   2022-01-09 07:53:40,5,FRA01,0.0010293465345985
   2022-01-09 07:54:39,5,FRA01,0.354050882353262
   2022-01-09 07:55:38,5,FRA01,3.00099899999623
   2022-01-09 07:50:43,6,FRA01,0.00122180000180379
   2022-01-09 07:51:42,6,FRA01,0
   2022-01-09 07:52:41,6,FRA01,0
   2022-01-09 07:53:40,6,FRA01,0.00101174999984393
   2022-01-09 07:54:39,6,FRA01,0.143833952380754
   2022-01-09 07:55:38,6,FRA01,3.00096099999791
   2022-01-09 07:50:43,7,FRA01,1.50122099999862
   2022-01-09 07:51:42,7,FRA01,0
   2022-01-09 07:52:41,7,FRA01,0.00101109090874988
   2022-01-09 07:53:40,7,FRA01,0.00100167692309277
   2022-01-09 07:54:39,7,FRA01,0.00100507258062979
   2022-01-09 07:55:38,7,FRA01,3.00107300000673
   2022-01-09 07:51:42,1,FRA01,3.00137900000846
   2022-01-09 07:52:41,1,FRA01,0.0011576666632512
   2022-01-09 07:53:40,1,FRA01,0.000990931404072498
   2022-01-09 07:54:39,1,FRA01,0.023830571065986
   2022-01-09 07:55:38,1,FRA01,0.00108950000139885

=cut

my %colNames = (
 displaytime => 0,
 snaptime => 1,
 elapsedtime => 2,
 instname => 3,
 dbname => 4,
 group_number => 5,
 disk_number => 6,
 diskgroup_name => 7,
 reads => 8,
 writes => 9,
 read_time => 10,
 avg_read_time => 11,
 write_time => 12,
 avg_write_time => 13,
 bytes_read => 14,
 bytes_written => 15,
 cold_bytes_read => 16,
 cold_bytes_written => 17,
 cold_reads => 18,
 cold_used_mb => 19,
 cold_writes => 20,
 create_date => 21,
 disk_name => 22,
 failgroup => 23,
 failgroup_type => 24,
 free_mb => 25,
 header_status => 26,
 hot_bytes_read => 27,
 hot_bytes_written => 28,
 hot_reads => 29,
 hot_used_mb => 30,
 hot_writes => 31,
 label => 32,
 mount_date => 33,
 os_mb => 34,
 path => 35,
 preferred_read => 36,
 product => 37,
 read_errs => 38,
 redundancy => 39,
 repair_timer => 40,
 sector_size => 41,
 total_mb => 42,
 udid => 43,
 voting_file => 44,
 write_errs => 45
);

my %diskLineFifo=();

my $pipeDepth=5;

while(<STDIN>) {
	my $line=$_;
	chomp $line;
	my (
		$displaytime, $snaptime, $elapsedtime, $instname, $dbname, $group_number, $disk_number,
		$diskgroup_name, $reads, $writes, $read_time, $avg_read_time, $write_time, $avg_write_time,
		$bytes_read, $bytes_written, $cold_bytes_read, $cold_bytes_written, $cold_reads, $cold_used_mb,
		$cold_writes, $create_date, $disk_name, $failgroup, $failgroup_type, $free_mb, $header_status,
		$hot_bytes_read, $hot_bytes_written, $hot_reads, $hot_used_mb, $hot_writes, $label, $mount_date,
		$os_mb, $path, $preferred_read, $product, $read_errs, $redundancy, $repair_timer, $sector_size,
		$total_mb, $udid, $voting_file, $write_errs
	) = split(/,/,$line);

	# filter input with grep to skip this
	#next if ($instname ne 'dbp004');
	#next if ($diskgroup_name ne 'FRA01');

	if ( $avg_write_time >= 3 ) {
		foreach my $diskLine ( @{$diskLineFifo{$disk_number}} ) {
			print "$diskLine\n";
		}
		print "$line\n";
	} 

	fifoPush(\%diskLineFifo,$disk_number, $line);

	#print "$line\n";
	#print Dumper(\%diskLineFifo{$disk_number});

}

#foreach my $key (sort keys %diskLineFifo) {
#print "key: $key\n";
#my @fifo = @{$diskLineFifo{$key}};
#print Dumper(\@fifo);
#}

# push into fifo and remove top element
sub fifoPush{
	my ($fifoHashRef, $diskNumber, $value) = @_;
	push @{$fifoHashRef->{$diskNumber}}, $value;
	shift @{$fifoHashRef->{$diskNumber}} if $#{$fifoHashRef->{$diskNumber}} gt $pipeDepth -1;
	return;
}


