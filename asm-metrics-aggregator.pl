#!/usr/bin/env perl

use strict;
use Pod::Usage;
use Data::Dumper;
# use this where available
#use Data::TreeDumper;
use Getopt::Long;

my %optctl = ();

my $man = 0;
my $help = 0;
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.

my @groupingCols=();
my @aggCols=();
my @displayCols=();

GetOptions(\%optctl,
	"trunctime!",
	"delimiter=s",
	"output-delimiter=s",
	'list-available-cols!',
	"grouping-cols=s{1,10}" => \@groupingCols,
	"agg-cols=s{1,10}" => \@aggCols,
	"display-cols=s{2,20}" => \@displayCols,
	"debug!",
	'help|?' => \$help, man => \$man
) or pod2usage(2) ;


pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

my $listAvailableCols = defined($optctl{'list-available-cols'}) ? 1 : 0;
my $truncTime = defined($optctl{trunctime}) ? 0 : 1;
my $delimiter = defined($optctl{delimiter}) ? $optctl{delimiter} : ',';
my $outputDelimiter = defined($optctl{'output-delimiter'}) ? $optctl{'output-delimiter'} : ',';
my $debug = defined($optctl{debug}) ? 1 : 0;

print "\n\@groupingCols:\n" . Dumper(\@groupingCols) if $debug;

# function prototypes
sub colChk ($$$);

# columns used to group metrics
# SNAPTIME is used as a key for snapshots and so is not available for grouping
# SNAPTIME includes fractional seconds
# The format string to use in Excel is YYYY-MM-DD HH:MM:SS.000

# use the -trunctime option if you don't want fractional seconds 

my @availGroupingCols=qw[
	INSTNAME DBNAME
	GROUP_NUMBER DISK_NUMBER HEADER_STATUS
	REDUNDANCY DISKGROUP_NAME DISK_NAME FAILGROUP
	LABEL PREFERRED_READ SECTOR_SIZE FAILGROUP_TYPE 
	PATH
];

# columns that can be added
my @availAggCols=qw[
	READS WRITES READ_ERRS WRITE_ERRS 
	READ_TIME WRITE_TIME 
	BYTES_READ BYTES_WRITTEN 
	HOT_READS HOT_WRITES HOT_BYTES_READ HOT_BYTES_WRITTEN 
	COLD_READS COLD_WRITES COLD_BYTES_READ COLD_BYTES_WRITTEN
];

print "\n\@availAggCols: \n" . Dumper(\@availAggCols) if $debug;

# columns that can be displayed - pretty much everything
# get this list from the first line of the CSV file
# assume the delimiter is ',' for now
# add some code later to determine the delimiter from this line
$outputDelimiter=',';

my $hdrs=<>;
chomp $hdrs;

my @availDisplayCols=split(/$delimiter/,$hdrs);
print "\n\@availDisplayCols:\n" . Dumper(\@availDisplayCols) if $debug;

# assign values to column arrays only if not already done on the command line
@groupingCols = qw[INSTNAME DISKGROUP_NAME] unless $#groupingCols >= 0;
# aggregate columns are those for which values are additive
@aggCols = qw[READS WRITES READ_TIME WRITE_TIME] unless $#aggCols >= 0;
@displayCols=qw[SNAPTIME INSTNAME DISKGROUP_NAME ELAPSEDTIME] unless $#displayCols >= 0;
if ($displayCols[0] eq 'ALL-COLUMNS') { @displayCols = @availDisplayCols }

# if columns used for grouping are not already in the display list, add them
my %grpColsTmp=();
my $i=0;
map {$grpColsTmp{$_}=$i++} @displayCols;

print "\n\%grpColsTmp: \n" . Dumper(\%grpColsTmp) if $debug;
print "\n\@aggCols: \n" . Dumper(\@aggCols) if $debug;

foreach my $col ( @groupingCols ) {
	unless (defined($grpColsTmp{$col})) {
		push @displayCols,$col;
	}
}

print "\n\@groupingCols:\n" . Dumper(\@groupingCols) if $debug;
print "\n\@displayCols:\n" . Dumper(\@displayCols) if $debug;

#exit;

if ($listAvailableCols) {
	print join("\n",@availDisplayCols),"\n";
	exit;
}

# if there are any aggregate columns duplicated in the display columns,
# remove them from the display column list

foreach my $aggCol (@aggCols) {
	for (my $i=0; $i <= $#displayCols; $i++) {
		if ($aggCol eq $displayCols[$i]) {
			# neatly remove 1 element
			splice @displayCols,$i,1;
		}
	}
}

print "\n\@displayCols after pruning:\n" . Dumper(\@displayCols) if $debug;

# verify the requested column sets
colChk('Grouping Columns',\@groupingCols, \@availGroupingCols);
colChk('Aggregate Columns',\@aggCols, \@availAggCols);
colChk('Display Columns',\@displayCols, \@availDisplayCols);

print "\n\@availDisplayCols:\n" . Dumper(\@availDisplayCols) if $debug;

# get list of columns with element position
my %colPos=();
$i=0;
map {$colPos{$_}=$i++} @availDisplayCols;

print "\%colPos:\n" , Dumper(\%colPos) if $debug;


# push all aggregates for a snapshot of data into a hash
# this script will not be storing all data in a hash, only a single snapshot
# then a snapshot is completed (timestamp changes), write out the data
# couple of benefits to this method
# 1. arbitrarily long files can be processed
# 2. order of snapshots is preserved without extra code.
#    the order of metrics within a snapshot is unimportant.

my %aggs=(); # aggregates
my $firstPass=1;
my $prevSnapshot='';


# print header line
print join($outputDelimiter,@displayCols) . ',';
print join($outputDelimiter,@aggCols) . "\n";

while(<>) {

	chomp;
	my @data=split(/$delimiter/);

	my $snapshot=$data[1]; # SNAPTIME is the second element in a row
	if ($prevSnapshot ne $snapshot) {
		if ($firstPass) {
			$firstPass=0;
		} else {
			if ($debug) {
				print '=' x 80, "\n";
				print "Snapshot Key: $prevSnapshot\n";
				print Dumper(\%aggs);
			}
			my @keys = map{$_} keys %aggs;
			print "Keys: ", Dumper(\@keys) if $debug;

			# recalc the average read and write times if data available
			foreach my $aggKey ( keys %aggs ) {
				if (
					defined( $aggs{$aggKey}->{'WRITE_TIME'})
					&& defined( $aggs{$aggKey}->{'WRITES'})
				) {
					if ( $aggs{$aggKey}->{'WRITES'} && $aggs{$aggKey}->{'WRITE_TIME'}) {
						$aggs{$aggKey}->{'AVG_WRITE_TIME'} = $aggs{$aggKey}->{'WRITE_TIME'} / $aggs{$aggKey}->{'WRITES'};
					} else {
						$aggs{$aggKey}->{'AVG_WRITE_TIME'} = 0;
					}
				}
				if (
					defined( $aggs{$aggKey}->{'READ_TIME'})
					&& defined( $aggs{$aggKey}->{'READS'})
				) {
					if ( $aggs{$aggKey}->{'READS'} && $aggs{$aggKey}->{'READ_TIME'}) {
						$aggs{$aggKey}->{'AVG_READ_TIME'} = $aggs{$aggKey}->{'READ_TIME'} / $aggs{$aggKey}->{'READS'};
					} else {
						$aggs{$aggKey}->{'AVG_READ_TIME'} = 0;
					}
				}
			}

			# print the output for CSV
			foreach my $aggKey ( keys %aggs ) {
				# first the display columns (includes grouping columns)
				my $firstCol=1;
				foreach my $outCol (@displayCols) {
					print "$outputDelimiter" unless $firstCol;
					$firstCol=0 if $firstCol;
					print "$aggs{$aggKey}->{$outCol}";
				}
				# and now the calculated columns
				foreach my $outCol (@aggCols) {
					print "$outputDelimiter";
					print "$aggs{$aggKey}->{$outCol}";
				}
				print "\n";
			}

			%aggs=();
		}
	}
	$prevSnapshot=$snapshot;

	my @aggKeyValues;
	map {push @aggKeyValues, $data[$colPos{$_}]} @groupingCols;
	my $aggKey=join(':',@aggKeyValues);

	foreach my $displayCol (@displayCols) {
		$aggs{$aggKey}->{$displayCol} = $data[$colPos{$displayCol}];
	}

	foreach my $aggCol ( @aggCols ) {
		$aggs{$aggKey}->{$aggCol} = 
			defined $aggs{$aggKey}->{$aggCol} 
				? $aggs{$aggKey}->{$aggCol} += $data[$colPos{$aggCol}]
				: $data[$colPos{$aggCol}];
	}

} 


# verify that all elements in first array are available in the second
# arg 1: descriptive name for error message
# arg 2: ref to array of elements to be checked
# arg 3: ref to array that contains valid elements 

sub colChk ($$$) {
	my $errName=shift;
	my $chkRef=shift;
	my $availRef=shift;

	my %availCols=();
	map {$availCols{$_}=1} @{$availRef};

	foreach my $col (@{$chkRef}) {
		unless ( defined($availCols{$col})) {
			die qq{\nColumn for "$errName" - $col is not defined in the list of valid columns\n};
		}
	}
	
}

__END__

=head1 NAME

asm-metrics-aggregator.pl

  -help brief help message
  -man  full documentation
  -grouping-cols list of columns used as a key for aggregating additive data
  -agg-cols list of additive columns to be aggregated
  -display-cols list of columns to diplay
  -list-available-cols just the header line of the file will be read and available columns displayed
  -trunctime do not output fractional seconds - default is to output fractional seconds
  -delimiter input field delimiter - default is ,
  -output-delimiter output field delimiter - default is ,

 asm-metrics-aggregator.pl acts as a filter - all input is from STDIN
 As the number of columns can vary it is necessary to use the -- operator to notify
 the options processor to stop processing command line options.
 
 asm-metrics-aggregator.pl --grouping-cols DISKGROUP_NAME DISK_NAME  --agg-cols READS WRITES -- my_input_file.csv

=head1 SYNOPSIS

sample [options] [file ...]

 Options:
   -help brief help message
   -man  full documentation
   -grouping-cols list of columns used as a key for aggregating additive data
   -agg-cols list of additive columns to be aggretated
   -display-cols list of columns to diplay
   -list-available-cols just the header line of the file will be read and available columns displayed
   -trunctime do not output fractional seconds - default is to output fractional seconds
   -delimiter input field delimiter - default is ,
   -output-delimiter output field delimiter - default is ,

 asm-metrics-aggregator.pl acts as a filter - all input is from STDIN
 As the number of columns can vary it is necessary to use the -- operator to notify
 the options processor to stop processing command line options.

 asm-metrics-aggregator.pl --grouping-cols DISKGROUP_NAME DISK_NAME  --agg-cols READS WRITES -- my_input_file.csv

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-display-cols>

 The arguments for the columns lists should appear following other single option and binary arguments.
 These are all of the possible columns from the collector.  
 These may not all appear in the file output from asm-metrics-collector.pl
 See the examples section.

 Columns that will be displayed in the output.
 If not already present the columns for grouping and aggregation will automatically be added.

 If the first argument is ALL-COLUMNS then all available columns will be output.

B< Available Display Columns:>

 DISPLAYTIME SNAPTIME ELAPSEDTIME INSTNAME DBNAME GROUP_NUMBER DISK_NUMBER 
 HEADER_STATUS REDUNDANCY OS_MB TOTAL_MB FREE_MB HOT_USED_MB COLD_USED_MB 
 GROUP_NAME DISK_NAME FAILGROUP LABEL PATH UDID PRODUCT CREATE_DATE MOUNT_DATE 
 REPAIR_TIMER PREFERRED_READ VOTING_FILE SECTOR_SIZE FAILGROUP_TYPE 
 READS WRITES READ_ERRS WRITE_ERRS READ_TIME AVG_READ_TIME WRITE_TIME 
 AVG_WRITE_TIME BYTES_READ BYTES_WRITTEN HOT_READS HOT_WRITES HOT_BYTES_READ 
 HOT_BYTES_WRITTEN COLD_READS COLD_WRITES COLD_BYTES_READ COLD_BYTES_WRITTEN

B< Default Display Columns:>

 SNAPTIME INSTNAME DISKGROUP_NAME ELAPSEDTIME

=item B<list-available-cols>

B< List All Columns from the CSV file>

 Only the header line of the file will be read and available columns displayed

=item B<-grouping-cols>

 List of columns that will be used to group the data for aggregation

B< Available Grouping Columns:>

 INSTNAME DBNAME GROUP_NUMBER 
 DISK_NUMBER DISKGROUP_NAME DISK_NAME FAILGROUP FAILGROUP_TYPE 
 HEADER_STATUS REDUNDANCY 
 LABEL PREFERRED_READ SECTOR_SIZE 

B< Default Grouping Columns:>

 INSTNAME DISKGROUP_NAME

=item B<-agg-cols>

 List of columns that will be additively aggregated

B< Available Aggregated Columns:>

 READS READ_TIME READ_ERRS BYTES_READ 
 HOT_READS HOT_BYTES_READ 
 COLD_READS COLD_BYTES_READ 

 WRITES WRITE_TIME WRITE_ERRS BYTES_WRITTEN 
 HOT_WRITES HOT_BYTES_WRITTEN 
 COLD_WRITES COLD_BYTES_WRITTEN

B< Default Aggregate Columns>

 READS WRITES READ_TIME WRITE_TIME

=item B<-delimiter>

The character used as a delimiter between output fields for the CSV input.

=item B<-output-delimiter>

The character used as an delimiter between output fields for the CSV output.


=back

=head1 DESCRIPTION

B<asm-metrics-aggregtor.pl> is used to aggregate a slice of the data output by B<asm-metrics-collector.pl>


=head1 EXAMPLES

 asm-metrics-aggregator.pl acts as a filter - all input is from STDIN
 As the number of columns can vary it is necessary to use the -- operator to notify
 the options processor to stop processing command line options.
 
 In the following example the default list of display columns will be used.
 The grouping and aggregate columns will be added to the display list as needed.

 asm-metrics-aggregator.pl --display-cols SNAPTIME DBNAME ELAPSEDTIME --grouping-cols DBNAME DISKGROUP_NAME --agg-cols READS WRITES -- my_input_file.csv

 asm-metrics-aggregator.pl --display-cols ALL-COLUMNS --grouping-cols DBNAME DISKGROUP_NAME --agg-cols READS WRITES -- my_input_file.csv

=cut


