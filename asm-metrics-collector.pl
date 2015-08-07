#!/usr/bin/env perl

use strict;
use DBI;
use DBD::Oracle qw(:ora_session_modes);
use Pod::Usage;
use Data::Dumper;
# use this where available
#use Data::TreeDumper;
use Getopt::Long;

sub setOptionalColumns($);
my %optionalColumnsAvail=();
setOptionalColumns(\%optionalColumnsAvail);
#print "OPTIONAL COLUMNS:\n ", Dumper(\%optionalColumnsAvail);
#exit;

my %optctl = ();

my $man = 0;
my $help = 0;
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.

my @optionalColumns=();

GetOptions(\%optctl,
	"interval=i",
	"iterations=i",
	"delimiter=s",
	"opt-cols=s{1,40}" => \@optionalColumns,
	"database=s",
	"username=s",
	"sysdba!",
	"debug!",
	'help|?' => \$help, man => \$man
) or pod2usage(2) ;

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
#exit;

my $interval = defined($optctl{interval}) ? $optctl{interval} : 60;
my $delimiter = defined($optctl{delimiter}) ? $optctl{delimiter} : ',';
my $iterations = defined($optctl{iterations}) ? $optctl{iterations} : 5;
my $debug = defined($optctl{debug}) ? 1 : 0;
my $timestamp_format= 'yyyy-mm-dd hh24:mi:ss.ff6';

my($db, $username, $password, $connectionMode);

$connectionMode = 0;
if ( $optctl{sysdba} ) { $connectionMode = 2 }

# assume connection is to local instance as SYSDBA via bequeath if db and username not defined


my $dbh='';
if ( defined($optctl{database}) and defined($optctl{username} ) ) {
	$username=$optctl{username};
	my $password = <>;
	chomp $password;
	$db=$optctl{database};
	#print "CMD LINE: $$\n";system("ps -flp $$");
	#exit;
	# TNS connection
	$dbh = DBI->connect(
		'dbi:Oracle:' . $db,
		$username, $password,
		{
			RaiseError => 1,
			AutoCommit => 0,
			ora_session_mode => $connectionMode
		}
	);
} else {
	# bequeath connection
	$dbh = DBI->connect('dbi:Oracle:','', '', { ora_session_mode => ORA_SYSDBA });
}


	#, systimestamp -  to_timestamp(? ,'YYYY-MM-DD HH24:MI:SS.FF6') interval

my $asmMetricSQL = q[
with data as (
select
	to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') displaytime
	, to_char(systimestamp ,'YYYY-MM-DD HH24:MI:SS.FF6') snaptime
	, 0 elapsedtime -- calculated field
	, io.instname
	, io.dbname
	, io.group_number
	, io.disk_number
	, g.name DISKGROUP_NAME
	, io.reads
	, io.writes
	, io.read_time --total i/o time (in seconds) for read requests for the disk
	, 0 avg_read_time -- will calculate as reads / read_time
	, io.write_time --total i/o time (in seconds) for write requests for the disk
	, 0 avg_write_time -- will calculate as writes / write_time
	, io.bytes_read --total number of bytes read from the disk
	, io.bytes_written --total number of bytes written from the disk];


print Dumper(\@optionalColumns) if $debug;

# get all columns if --opt-cols ALL-COLUMNS
if ($optionalColumns[0] eq 'ALL-COLUMNS') {
	foreach my $colName (sort keys %optionalColumnsAvail) {
		#print "COL: $colName\n";
		$asmMetricSQL .= qq[\n\t, ${optionalColumnsAvail{$colName}}];
	}
} else {
	foreach my $colName (@optionalColumns) {
		#print "COL: $colName\n";
		die qq["$colName" is not a valid column name\n] unless $optionalColumnsAvail{$colName};
		$asmMetricSQL .= qq[\n\t, ${optionalColumnsAvail{$colName}}];
	}
}

$asmMetricSQL .= q[
from gv$asm_disk_iostat io
join gv$asm_disk d on d.inst_id = io.inst_id
	and d.group_number = io.group_number
	and d.disk_number = io.disk_number
join gv$asm_diskgroup g on g.inst_id = d.inst_id
	and g.group_number = d.group_number
where d.mount_status = 'CACHED'
order by 1,2,3,4)
select * from data];


print "SQL:\n$asmMetricSQL\n\n" if $debug;

$|++; # do not buffer output

#exit;

my $sth=$dbh->prepare($asmMetricSQL);
$sth->execute;

# get the names of columns with a reference to position in the array
my %names = %{$sth->{NAME_hash}};

# names for header row
my @selectCols=@{$sth->{NAME_uc}};
print join($delimiter,@selectCols),"\n";

my %selectColsHash=map{ $_ => 1 } @selectCols;

#print Dumper(\%selectColsHash);

# columns for which the current values are calculated from previous and current snapshots
my @calcColsAvail = qw[READS WRITES READ_ERRS WRITE_ERRS READ_TIME 
	WRITE_TIME BYTES_READ BYTES_WRITTEN HOT_READS HOT_WRITES HOT_BYTES_READ 
	HOT_BYTES_WRITTEN COLD_READS COLD_WRITES COLD_BYTES_READ COLD_BYTES_WRITTEN];

my @calcCols=();
foreach my $col (@calcColsAvail) {
	push(@calcCols, $col) if exists $selectColsHash{$col};
}

#print '@calcCols: ' , Dumper(\@calcCols) if $debug;

#foreach my $colName ( sort { $names{$a} <=> $names{$b} } keys %names) {
	#printf "%3d: %30s\n", $names{$colName}, $colName;
#}

my %prevSnap=();
my %currSnap=();

# get first set and use to calculate values for the first current set
while( my $ary = $sth->fetchrow_arrayref ) {
	my $key = join(':',( $ary->[$names{INSTNAME}],  $ary->[$names{DBNAME}], $ary->[$names{GROUP_NUMBER}], $ary->[$names{DISK_NUMBER}]));
	push @{$prevSnap{$key}}, @{$ary};
}

for (my $i=0;$i<$iterations;$i++) {

	my $elapsedTime;

	sleep $interval;
	$sth->execute;
	while( my $ary = $sth->fetchrow_arrayref ) {

		my $key = join(':',( $ary->[$names{INSTNAME}],  $ary->[$names{DBNAME}], $ary->[$names{GROUP_NUMBER}], $ary->[$names{DISK_NUMBER}]));
		if ($debug) {
			print "key: $key\n";
			print 'data: ' . join($delimiter,@{$ary}),"\n";
		}

		push @{$currSnap{$key}}, @{$ary};

		# this may fail if a new disk is added while running, and no previous row exists
		unless (defined($elapsedTime)) {

			# Consideration was given to changing this to a PL/SQL routine rather than select from dual
			# 'select from dual' has become quite optimized, while PL/SQL would be kind of cumbersome and kludgy in this context
			# we do not want to create a funtion in the database, and retrieving the data via PL/SQL block is kludgy
			my $sql = q[select extract( second from to_timestamp(?, 'yyyy-mm-dd hh24:mi:ss.ff6') - to_timestamp(?, 'yyyy-mm-dd hh24:mi:ss.ff6')) seconds from dual];
			my $sth=$dbh->prepare($sql);

			print qq[
				Current  Timestamp: $currSnap{$key}->[$names{SNAPTIME}]
				Previous Timestamp: $prevSnap{$key}->[$names{SNAPTIME}]
			] if $debug;

			$sth->execute($currSnap{$key}->[$names{SNAPTIME}],$prevSnap{$key}->[$names{SNAPTIME}]);

			($elapsedTime) = $sth->fetchrow_array;

		};

		#warn "ElapsedTime: $elapsedTime\n";

		$currSnap{$key}->[$names{ELAPSEDTIME}] = $elapsedTime;
	
		print qq{

CurrSnap:
Display Time $currSnap{$key}->[$names{DISPLAYTIME}]
   Snap Time $currSnap{$key}->[$names{SNAPTIME}]
    instname $currSnap{$key}->[$names{INSTNAME}]
      dbname $currSnap{$key}->[$names{DBNAME}]
      group# $currSnap{$key}->[$names{GROUP_NUMBER}]
       disk# $currSnap{$key}->[$names{DISK_NUMBER}]
   failgroup $currSnap{$key}->[$names{FAILGROUP}]

		} if $debug;


	}

	# populate %modSnap which will eventually hold caculated values for output
	# simply using %modSnap = %currSnap does not work properly
	# as calculations to %modSnap will also change %currSnap

	# map is equiv to the loop shown following it

	my %modSnap=(); 
	map { push @{$modSnap{$_}} , @{$currSnap{$_} } } keys %currSnap;
	#foreach my $key (keys %currSnap) {
		#push @{$modSnap{$key}} , @{$currSnap{$key}};
	#}


	foreach my $key ( keys %modSnap ) {
		print "currkey: $key\n" if $debug;
		# get before and after values to verify that map() is working correctly
		if ($debug) {
			print '=' x 80 , "\n";
			print "key: $key\n";
			print 'RAW2: ' . join($delimiter,@{$modSnap{$key}}),"\n";
			print "currSnap before: $currSnap{$key}->[$names{READS}]\n"; 
			print " modSnap before: $modSnap{$key}->[$names{READS}]\n"; 
			print "prevSnap before: $prevSnap{$key}->[$names{READS}]\n"; 
		}
		# do the diffs between current and previous
		map { $modSnap{$key}->[$names{$_}] -= $prevSnap{$key}->[$names{$_}]} @calcCols;

		# calculate avg read/write times
		my $reads=$modSnap{$key}->[$names{READS}];
		$modSnap{$key}->[$names{AVG_READ_TIME}] = ($modSnap{$key}->[$names{READ_TIME}] / $reads) if $reads > 0;

		my $writes=$modSnap{$key}->[$names{WRITES}];
		$modSnap{$key}->[$names{AVG_WRITE_TIME}] = ($modSnap{$key}->[$names{WRITE_TIME}] / $writes) if $writes > 0;

		if ($debug) {
			print " mod after: $modSnap{$key}->[$names{READS}]\n" ;
			print "prev after: $prevSnap{$key}->[$names{READS}]\n"; 
			print "curr after: $currSnap{$key}->[$names{READS}]\n"; 
		}
		print join($delimiter,@{$modSnap{$key}}),"\n";
		
	}
	
	%prevSnap = ();
	map { push @{$prevSnap{$_}} , @{$currSnap{$_} } } keys %currSnap;
	%currSnap=();
}

	
$dbh->disconnect;

#foreach my $colName ( sort { $names{$a} <=> $names{$b} } keys %names) {
	#my $s=sprintf "%3d: %30s\n", $names{$colName}, $colName;
	#warn $s;
#}


# set optional columns 
# takes a hash ref
sub setOptionalColumns($) {
	my $href=shift;
	%{$href} = (
		'HEADER_STATUS'	=> 'd.header_status',
		'REDUNDANCY'		=> 'd.redundancy -- refers to redundancy of external schemes - RAID1, RAID5 (MIRROR,PARITY)',
		'OS_MB'				=> 'd.os_mb -- disk size as reported by OS',
		'TOTAL_MB'			=> 'd.total_mb',
		'FREE_MB'			=> 'd.free_mb',
		'HOT_USED_MB'		=> 'd.hot_used_mb',
		'COLD_USED_MB'		=> 'd.cold_used_mb',
		'DISK_NAME'			=> 'd.name DISK_NAME',
		'FAILGROUP'			=> 'd.failgroup',
		'LABEL'				=> 'd.label',
		'PATH'				=> 'd.path',
		'UDID'				=> 'd.udid',
		'PRODUCT'			=> 'd.product -- mfg name',
		'CREATE_DATE'		=> q[to_char(d.create_date,'yyyy-mm-dd hh24:mi:ss') create_date],
		'MOUNT_DATE'		=> q[to_char(d.mount_date,'yyyy-mm-dd hh24:mi:ss') mount_date],
		'REPAIR_TIMER'		=> 'd.repair_timer',
		'PREFERRED_READ'	=> 'd.preferred_read',
		'VOTING_FILE'		=> 'd.voting_file',
		'SECTOR_SIZE'		=> 'd.sector_size',
		'FAILGROUP_TYPE'	=> 'd.failgroup_type',
		'READ_ERRS'			=> 'io.read_errs',
		'WRITE_ERRS'		=> 'io.write_errs',
		'HOT_READS'			=> 'io.hot_reads --number of reads from the hot region on disk',
		'HOT_WRITES'		=> 'io.hot_writes --number of writes to the hot region on disk',
		'HOT_BYTES_READ'	=> 'io.hot_bytes_read --number of bytes read from the hot region on disk',
		'HOT_BYTES_WRITTEN'	=> 'io.hot_bytes_written --number of bytes written to the hot region on disk',
		'COLD_READS'		=> 'io.cold_reads --number of reads from the cold region on disk',
		'COLD_WRITES'		=> 'io.cold_writes --number of writes to the cold region on disk',
		'COLD_BYTES_READ' => 'io.cold_bytes_read --number of bytes read from the cold region on disk',
		'COLD_BYTES_WRITTEN'	=> 'io.cold_bytes_written --number of bytes written to the cold region on disk'
	);

}

__END__

=head1 NAME

asm-metrics-collector.pl

-help brief help message
-man  full documentation
-interval seconds between snapshots - default is 0
-iterations number of snapshots - default is 5
-delimiter output field delimiter - default is ,

=head1 SYNOPSIS

sample [options] [file ...]

 Options:
   --help brief help message
   --man  full documentation
   --database tnsname of oracle database
   --username oracle user name
   --sysdba connect as sysdba if this option is used
   --interval seconds between snapshots - default is 0
   --iterations number of snapshots - default is 5
   --opt-cols optional columns to collect - if ALL-COLUMNS is the first argument than all available columns will be output
   --delimiter output field delimiter - default is ,

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--database> 

TNS name of database

=item B<--username>

Username for connection

 Note: there is no option for password.
 The password will be expected on STDIN if arguments for both --database and --username are speciffied
 If both are not on the command line, the connection attempt will be via BEQUEATH as SYSDBA

=item B<--interval>

The integer number of seconds between each snapshot of ASM storage metrics

=item B<--iterations>

The integer number of the number of snapshots of ASM storage metrics

=item B<--delimiter>

The character used as a delimiter between output fields for the CSV output.

=item B<--opt-cols>

 Optional columns to collect

 The arguments for the columns lists should appear following other single option and binary arguments.
 If ALL-COLUMNS is the first argument than all available columns will be output.

 See the examples section.

B< Available Optional Columns:>

 OS_MB TOTAL_MB FREE_MB HOT_USED_MB COLD_USED_MB
 REDUNDANCY DISK_NAME FAILGROUP LABEL PATH UDID
 PRODUCT CREATE_DATE MOUNT_DATE REPAIR_TIMER
 PREFERRED_READ VOTING_FILE SECTOR_SIZE FAILGROUP_TYPE
 READ_ERRS WRITE_ERRS 
 HOT_READS HOT_WRITES HOST_BYTES_READ HOT_BYTES_WRITTEN
 COLD_READS COLD_WRITES COLD_BYTES_READ COLD_BYTES_WRITTEN

=back

=head1 DESCRIPTION

B<asm-metrics-collector.pl> will connect as SYSDBA to the currently set ORACLE_SID.

Metrics for reads and writes will be collected for each disk in GV$ASM_DISK_IOSTAT

Minimal calculations are performed by this script.

The following are the calculations done in this script

  avg_read_time per disk
  avg_write_time per disk

Output is to STDOUT, so it will be necessary to redirect to a file if results are to be saved.

=head1 EXAMPLES

These examples all connect to the local instance specified in ORACLE_SID as SYSDBA

20 snapshots at 10 second intervals

  asm-metrics-collector.pl  -interval 10 -iterations 20 -delimiter ,

5 snapshots at 60 second intervals

  asm-metrics-collector.pl  > my-asm.csv

Add optional columns to output

 asm-metrics-collector.pl -interval 5 -iterations 5 -delimiter , --opt-cols DISK_NAME COLD_BYTES_WRITTEN PATH | tee asm_metrics.csv

Include all available columns in the output

 asm-metrics-collector.pl -interval 5 -iterations 5 -delimiter , --opt-cols ALL-COLUMNS | tee asm_metrics.csv

These next examples get the password from STDIN

This first example will require you to type in the password as the script appears to hang:

  asm-metrics-collector.pl --database orcl --username scott --sysdba > my-asm.csv

The next two examples get the password from a file:

  asm-metrics-collector.pl --database orcl --username scott --sysdba < password.txt > my-asm.csv 
  cat password.txt | asm-metrics-collector.pl --database orcl --username scott --sysdba > my-asm.csv 


This next example works in bash - the password will not appear in ps

  asm-metrics-collector.pl --database orcl --username scott --sysdba <<< scott > my-asm.csv 

=cut

