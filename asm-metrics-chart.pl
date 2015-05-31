#!/usr/bin/env perl

# asm-metrics-chart.pl
# Jared Still
# jkstill@gmail.com

# data is from STDIN


use warnings;
use strict;
use Data::Dumper;
use Pod::Usage;
use Getopt::Long;
use Excel::Writer::XLSX;

my $debug = 0;
my %optctl = ();
my ($help,$man);
my @chartCols;

Getopt::Long::GetOptions(
	\%optctl, 
	'spreadsheet-file=s',
	'debug!' => \$debug,
	'chart-cols=s{1,10}' => \@chartCols,
	'worksheet-col=s',  # creates a separate worksheet per value of this column
	'h|help|?' => \$help, man => \$man
) or pod2usage(2) ;

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

my $xlFile = defined($optctl{'spreadsheet-file'}) ? $optctl{'spreadsheet-file'} : 'asm-metrics.xlsx';
my $workSheetCol = defined($optctl{'worksheet-col'}) ? $optctl{'worksheet-col'} : 0;

#if ($workSheetCol) {
	#print "Work Sheet Col: $workSheetCol\n";
#} else {
	#print "ASM-Metrics\n";
#}


my %fonts = (
	fixed			=> 'Courier New',
	fixed_bold	=> 'Courier New',
	text			=> 'Arial',
	text_bold	=> 'Arial',
);

my %fontSizes = (
	fixed			=> 10,
	fixed_bold	=> 10,
	text			=> 10,
	text_bold	=> 10,
);

my $maxColWidth = 50;
my $counter = 0;
my $interval = 100;

# create workbook
my $workBook = Excel::Writer::XLSX->new($xlFile);
die "Problems creating new Excel file $xlFile: $!\n" unless defined $workBook;

# create formats
my $stdFormat = $workBook->add_format(bold => 0,font => $fonts{fixed}, size => $fontSizes{fixed}, color => 'black');
my $boldFormat = $workBook->add_format(bold => 1,font => $fonts{fixed_bold}, size => $fontSizes{fixed_bold}, color => 'black');
my $wrapFormat = $workBook->add_format(bold => 0,font => $fonts{text}, size => $fontSizes{text}, color => 'black');
$wrapFormat->set_align('vjustify');



# set column widths per each sheet
# these are commented out
# see dynamic settings in data loop below
#$roleWorkSheets{$role}->set_column(0,0,10); # privtype
#$roleWorkSheets{$role}->set_column(1,1,40); # privname
#$roleWorkSheets{$role}->set_column(2,2,20); # owner
#$roleWorkSheets{$role}->set_column(3,3,30); # table_name
#$roleWorkSheets{$role}->set_column(4,4,10); # grantable ( admin option )


my $labels=<>;
chomp $labels;
my @labels = split(/,\s*/,$labels);

#print join("\n",@labels);

# get the element number of the column used to segregate into worksheets
my $workSheetColPos;
if ($workSheetCol) {
	my $i=0;
	foreach my $label ( @labels)  {
		if ($label eq $workSheetCol) { 
			$workSheetColPos = $i;
			last;
		}
		$i++;
	}
}

#print "\nPOS: $workSheetColPos\n";

# validate the columns to be charted
# use as an index into the labels
my @chartColPos=();
{
	my $i=0;
	foreach my $label ( @labels)  {
		foreach my $chartCol ( @chartCols ) {
			if ($label eq $chartCol) { 
				push @chartColPos, $i;
				last;
			}
		}
		$i++;
	}
}

if ($debug) {
	print "\nChartCols:\n", Dumper(\@chartCols);
	print "\nChartColPos:\n", Dumper(\@chartColPos);
	print "\nLabels:\n", Dumper(\@labels);
}

my %lineCount=();
my %workSheets=();
#my $worksheetTracker=();

while (<>) {

	chomp;
	my @data=split(/,/);

	my $currWorkSheetName;
	if ($workSheetCol) {
		$currWorkSheetName=$data[$workSheetColPos];
	} else {
		$currWorkSheetName='ASM-Metrics';
	}

	unless (defined $workSheets{$currWorkSheetName}) {
		$workSheets{$currWorkSheetName} = $workBook->add_worksheet($currWorkSheetName);
		$workSheets{$currWorkSheetName}->write_row($lineCount{$currWorkSheetName}++,0,\@labels,$boldFormat);
		# freeze pane at header
		$workSheets{$currWorkSheetName}->freeze_panes($lineCount{$currWorkSheetName},0);
	}

	# setup column widths
	#$workSheet->set_column($el,$el,$colWidth);
	$workSheets{$currWorkSheetName}->write_row($lineCount{$currWorkSheetName}++,0,\@data, $stdFormat);

}

if ($debug) {
	print "Worksheets:\n";
	print "$_\n" foreach keys %workSheets;
	print Dumper(\%lineCount);
}

foreach my $workSheet ( keys %workSheets ) {
	print "Charting worksheet: $workSheet\n" if $debug;
	my $chartNum = 0;
	foreach my $colPos ( @chartColPos ) {
		my $col2Chart=$labels[$colPos];
		print "\tCharting column: $col2Chart\n" if $debug;
		my $chart = $workBook->add_chart( type => 'line', name => "$col2Chart" . '-' . $workSheets{$workSheet}->get_name(), embedded => 1 );
		# triple from default width
		# default height is 288 pixels
		# default width is 480 pixels
		$chart->set_size( width => 3 * 480, height => 288 );

		# each chart consumes about 16 rows
		$workSheets{$workSheet}->insert_chart((($chartNum * 16) + 2),3, $chart);

		

		# [ sheet, row_start, row_end, col_start, col_end]
		$chart->add_series(
			name => $col2Chart,
			categories => [$workSheet, 1,$lineCount{$workSheet},0,0],
			values => [$workSheet, 1,$lineCount{$workSheet},$colPos,$colPos]
		);

		$chartNum++;

	}
}

__END__

=head1 NAME

asm-metrics-chart.pl

  --help brief help message
  --man  full documentation
  --spreadsheet-file output file name - defaults to asm-metrics.xlsx
  --worksheet-col name of column used to segragate data into worksheets 
    defaults to a single worksheet if not supplied
  --chart-cols list of columns to chart

 asm-metrics-chart.pl accepts input from STDIN

 This script will read CSV data created by asm-metrics-collector.pl or asm-metrics-aggregator.pl


=head1 SYNOPSIS

asm-metrics-chart.pl [options] [file ...]

 Options:
   --help brief help message
   --man  full documentation
   --spreadsheet-file output file name - defaults to asm-metrics.xlsx
   --worksheet-col name of column used to segragate data into worksheets 
     defaults to a single worksheet if not supplied
  --chart-cols list of columns to chart


 asm-metrics-chart.pl accepts input from STDIN

 asm-metrics-chart.pl --worksheet-col DISKGROUP_NAME < my_input_file.csv

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<--spreadsheet-file>

 The name of the Excel file to create.
 The default name is asm-metrics.xlsx

=item B<--worksheet-col>

 By default a single worksheet is created.
 When this option is used the column supplied as an argument will be used to segragate data into separate worksheets.

=item B<--chart-cols>

 List of columns to chart
 This should be the last option on the command line if used.

 It may be necessary to tell Getopt to stop processing arguments with '--' in some cases.

 eg.

 asm-metrics-chart.pl asm-metrics-chart.pl --worksheet-col DISKGROUP_NAME --chart-cols READS WRITES -- logs/asm-oravm-20150512_01-agg-dg.csv

=back

=head1 DESCRIPTION

B<asm-metrics-chart.pl> creates an excel file with charts for selected columns>

=head1 EXAMPLES

 asm-metrics-chart.pl accepts data from STDIN
 
 asm-metrics-chart.pl --worksheet-col DISKGROUP_NAME --spreadsheet-file mywork.xlsx

=cut


