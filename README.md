
ASM Metrics Collector
=====================

This is a set of scripts for collecting and processing Oracle ASM Metrics.

When the data is collected from the ASM instance, data for all disks, diskgroups and databases is collected.

As this is file based CSV data, it is fairly easy to filter and aggregate the data as needed.


Following are descriptions of many of the scripts.  A later section has examples of processing the data and charting it with Excel.

Note: These are Bash scripts, and as you might expect, these work on Linux and other Unix like OS's.
The Excel charting requires Perl with the `Excel::Writer::XLSX` module installed.

Of course, you can always just manually load the CSV into Excel for charting.


## Scripts

### asm-metrics-collector.pl
Collect ASM metrics for further processing.

### asm-metrics-collector.sh
bash driver example 

### asm-metrics-aggregator.pl
This script aggregates metrics based on one column from raw metrics data.
eg. Aggregate IO metrics per diskgroup

### asm-metrics-aggregator.sh
bash driver example - aggregates by diskgroup

### asm-metrics-aggregator_bydisk.sh
bash driver example - aggregates by disk

### asm-metrics-chart.pl
Create Excel file with charts of metrics

### asm-metrics-chart.sh
bash driver example using aggregates by diskgroup

### asm-metrics-chart_bydisk.sh
bash driver example using aggregates by diskname

### asm-metrics-validate.pl
Perl script used to look for negative values in raw CSV files.
Used for some debugging.
This script can be used to look for any value with minor adjustment

### verify.sh
bash script used for verifying aggregates during development


### asm-metrics-fix.pl
asm-metrics-collector.pl had a bug where HH was used in the timestamp format
when really it should have been HH24.

This bug resulted in PM timestamps that were 12 hours off.
In addition when the time changed from 12:59 to 13:00, this bug resulted in negative elapsed times.

This script will fix the snaptime and elapsed time in output files.
A new filename with '-corrected' inserting in the name will be created.

example:

   asm-metrics-fix.pl asm-metrics-1.csv asm-metrics-2.csv asm-metrics-3.csv

Three new corrected files will be created:
  asm-metrics-1-corrected.csv
  asm-metrics-2-corrected.csv
  asm-metrics-3-corrected.csv

# Processing ASM Metrics Data

Data is raw.  Metrics are per diskgroup and disk every 20 seconds.

So, one line for each disk.

For analysis and charting, the data is being aggregated.

Some detail is lost, but this level of detail  is not necessary for charting trends.

## Aggregate

Make a copy of `asm-metrics-aggregator.sh`, and modifify the default file names.

Or to run against an entire directory of files , use `asm-metrics-aggregator-loop.sh` instead.

To see the effect, the `asm-metrics-aggregator.sh` script was used to process 10000 lines of ASM metrics data in the file `before.csv`.

```text
  wc -l before.csv after.csv
  10000 before.csv
     51 after.csv
  10051 total
```

The metrics are provided per diskgroup, per snapshot time.

The metric values have all been summed, so the the average values can be calculated as needed.

### before.csv

```text
$  head -5 before.csv  
DISPLAYTIME,SNAPTIME,ELAPSEDTIME,INSTNAME,DBNAME,GROUP_NUMBER,DISK_NUMBER,DISKGROUP_NAME,READS,WRITES,READ_TIME,AVG_READ_TIME,WRITE_TIME,AVG_WRITE_TIME,BYTES_READ,BYTES_WRITTEN,COLD_BYTES_READ,COLD_BYTES_WRITTEN,COLD_READS,COLD_USED_MB,COLD_WRITES,CREATE_DATE,DISK_NAME,FAILGROUP,FAILGROUP_TYPE,FREE_MB,HEADER_STATUS,HOT_BYTES_READ,HOT_BYTES_WRITTEN,HOT_READS,HOT_USED_MB,HOT_WRITES,LABEL,MOUNT_DATE,OS_MB,PATH,PREFERRED_READ,PRODUCT,READ_ERRS,REDUNDANCY,REPAIR_TIMER,SECTOR_SIZE,TOTAL_MB,UDID,VOTING_FILE,WRITE_ERRS
2020-07-31 08:55:35,2020-07-31 08:55:35.629847,20.444252,PRDBTS13,PRDBTS1,3,24,DATA,0,206,0,0,0.483442000004288,0.00234680582526354,0,1843200,0,1843200,0,1673632,206,2018-04-13 13:46:15,DATA_0024,DATA_0024,REGULAR,374540,MEMBER,0,0,0,48980,0,,2019-10-12 22:52:43,2097152,/dev/mapper/asm_data_25p1,U,,0,UNKNOWN,0,512,2097152,,N,0
2020-07-31 08:55:35,2020-07-31 08:55:35.629847,20.444252,PRDBTS11,PRDBTS1,3,48,DATA,0,4,0,0,0.003153999998176,0.000788499999544001,0,49152,0,49152,0,1673236,4,2020-02-25 15:53:42,DATA_0048,DATA_0048,REGULAR,374916,MEMBER,0,0,0,49000,0,,2020-02-25 15:53:44,2097152,/dev/mapper/asm_data_49p1,U,,0,UNKNOWN,0,512,2097152,,N,0
2020-07-31 08:55:35,2020-07-31 08:55:35.629847,20.444252,PRDBTS14,PRDBTS1,4,0,FRA,0,0,0,0,0,0,0,0,0,0,0,504391,0,2017-06-14 13:54:53,FRA_0000,FRA_0000,REGULAR,1592761,MEMBER,0,0,0,0,0,,2019-10-12 22:52:43,2097152,/dev/mapper/asm_fra_1p1,U,,0,UNKNOWN,0,512,2097152,,N,0
2020-07-31 08:55:35,2020-07-31 08:55:35.629847,20.444252,PRDBTS14,PRDBTS1,6,7,REDO,752,8,0.343787999998312,0.000457164893614777,0.0216940000009345,0.00271175000011681,12435456,131072,12435456,131072,752,55,8,2020-02-26 11:38:29,REDO_0007,REDO_0007,REGULAR,20865,MEMBER,0,0,0,81480,0,,2020-02-26 11:38:29,102400,/dev/mapper/asm_redo_8p1,U,,0,UNKNOWN,0,512,102400,,N,0
```

### after.csv

```text
$ head -6 after.csv
DISPLAYTIME,ELAPSEDTIME,DISKGROUP_NAME,READS,WRITES,READ_TIME,WRITE_TIME,BYTES_READ,BYTES_WRITTEN,READ_ERRS,WRITE_ERRS
2020-07-31 08:55:35,20.444252,FRA,80,807,31.6627970000747,46.6677670000765,1671680,21086720,0,0
2020-07-31 08:55:35,20.444252,GRID,64,196,0.0423570000002656,0.273379000002024,991232,8220672,0,0
2020-07-31 08:55:35,20.444252,ACFS,0,0,0,0,0,0,0,0
2020-07-31 08:55:35,20.444252,REDO,6259,43555,781.33763800023,64.7069339999862,436242432,336217088,0,0
2020-07-31 08:55:35,20.444252,DATA,187799,88229,1004.5424800001,875.308896999404,47032052224,1512292352,0,0
```

Usually `asm-metrics-aggregator-loop.sh` script is used, which reads files from the `logs` directory, and writes to the `output` directory.

## Synthesize Averages

So as to avoid doing this step in Excel, Google Sheets, or other charting tools, the averages can be calcualted for average read and write times, and written to a new file.


Some of the scripts that do this:

- asm-metrics-synth.pl
- asm-metrics-synth.sh

The `asm-metrics-synth.sh` script is just a driver for `asm-metrics-synth.pl`, and gets its input from the `output` directory of the previous step.

New files are written to the `synth` directory.

Let's try a test on the `after.csv` file created earlier


```text
$  ./asm-metrics-synth.pl after.csv synth.csv

>  head -6 after.csv synth.csv
==> after.csv <==
DISPLAYTIME,ELAPSEDTIME,DISKGROUP_NAME,READS,WRITES,READ_TIME,WRITE_TIME,BYTES_READ,BYTES_WRITTEN,READ_ERRS,WRITE_ERRS
2020-07-31 08:55:35,20.444252,FRA,80,807,31.6627970000747,46.6677670000765,1671680,21086720,0,0
2020-07-31 08:55:35,20.444252,GRID,64,196,0.0423570000002656,0.273379000002024,991232,8220672,0,0
2020-07-31 08:55:35,20.444252,ACFS,0,0,0,0,0,0,0,0
2020-07-31 08:55:35,20.444252,REDO,6259,43555,781.33763800023,64.7069339999862,436242432,336217088,0,0
2020-07-31 08:55:35,20.444252,DATA,187799,88229,1004.5424800001,875.308896999404,47032052224,1512292352,0,0

==> synth.csv <==
DATE,TIME,ELAPSEDTIME,DISKGROUP_NAME,AVG_READ_TIME,AVG_WRITE_TIME,READS,WRITES,READ_TIME,WRITE_TIME,BYTES_READ,BYTES_WRITTEN,READ_ERRS,WRITE_ERRS
2020-07-31,08:55:35,20.444252,FRA,0.395785,0.057829,80,807,31.6627970000747,46.6677670000765,1671680,21086720,0,0
2020-07-31,08:55:35,20.444252,GRID,0.000662,0.001395,64,196,0.0423570000002656,0.273379000002024,991232,8220672,0,0
2020-07-31,08:55:35,20.444252,ACFS,0,0,0,0,0,0,0,0,0,0
2020-07-31,08:55:35,20.444252,REDO,0.124834,0.001486,6259,43555,781.33763800023,64.7069339999862,436242432,336217088,0,0
2020-07-31,08:55:35,20.444252,DATA,0.005349,0.009921,187799,88229,1004.5424800001,875.308896999404,47032052224,1512292352,0,0

```

There are 2 changes made to the `synth.csv` file.

1) DISPLAYTIME has been split into DATE and TIME columns
2) New columns are AVG_READ_TIME and AVG_WRITE_TIME


## Breaking out diskgroups

To further simplify charting, the data can be split into diskgroup based files.

The `asm-diskgroup-breakout.sh` is a fairly simple Bash script that creates diskgroup based files, taking its input from the `synth` directory of the previous step.

New files are written to the `diskgroup-breakout` directory.


## Remove Outliers and Spikes

Sometimes there may be outliers and very large spikes. These tend to skew the data and make the charts hard to read.

In extreme cases a chart may consist of some spike connected by a flat line.

Normally you would like to see that data charted.

The data for each file is piped through two Python scripts, `outlier-remove.py` and `flatten.py`.

These CSV files and XLS files are placed in directories with a suffix of '-chart'.

Should you not want these, simply comment out the `asm-*clean*.sh` lines in `run-std.sh`.

### Pivot Disk Metrics

Using the `disk-pivot.pl` script, transform this layout:

   timestamp diskname  metric1 metric2 metric3

To this layout:

   timestamp disk1 disk2 disk3 ...
   metric

The default metric is avg_wrt_time, but it can be any metric, just modify the code a bit as needed.


## Charting Data

The data can now be charted using `asm-metrics-chart.pl`.

There are already a couple of shell driver scripts for this task:

- asm-metrics-chart.sh
- asm-metrics-chart-synth.sh

### asm-metrics-chart.sh

This script is hardcoded to create a single Excel file from an ASM Metrics file.

It can be used as the basis for a script that processes an entire directory of files.

### asm-metrics-chart-synth.sh

This script is configured to process all the csv files in a single directory.

The input is taken from the `diskgroup-breakout` directory created in the previous step.

The output is Excel files, written to the `xlsx-by-diskgroup` directory.




## Running all scripts

The commands to process all data were put into a the Bash script, `run-std.sh`.

```shell
#!/usr/bin/env bash

./asm-metrics-aggregator-loop.sh
./asm-metrics-synth.sh
./asm-diskgroup-breakout.sh
./asm-metrics-chart-synth.sh
```

```text
$  time ./run-std.sh
working on output/asm-data-20200731-085514.csv
working on output/asm-data-20200801-084753.csv
working on output/asm-data-20200802-083738.csv
working on output/asm-data-20200803-083430.csv
working on output/asm-data-20200804-083016.csv
working on output/asm-data-20200805-083703.csv
working on synth/asm-data-20200731-085514.csv
working on synth/asm-data-20200801-084753.csv
working on synth/asm-data-20200802-083738.csv
working on synth/asm-data-20200803-083430.csv
working on synth/asm-data-20200804-083016.csv
working on synth/asm-data-20200805-083703.csv
working on synth/asm-data-20200731-085514.csv
working on synth/asm-data-20200801-084753.csv
working on synth/asm-data-20200802-083738.csv
working on synth/asm-data-20200803-083430.csv
working on synth/asm-data-20200804-083016.csv
working on synth/asm-data-20200805-083703.csv
working on xlsx-by-diskgroup/ACFS.xlsx
working on xlsx-by-diskgroup/DATA.xlsx
working on xlsx-by-diskgroup/FRA.xlsx
working on xlsx-by-diskgroup/GRID.xlsx
working on xlsx-by-diskgroup/REDO.xlsx

real    4m53.885s
user    3m44.880s
sys     0m23.900s

```

## Running all scripts for a collection of files per RAC system 


ASM Metrics files are to be organized like this:

```text
cluster-01/
  node-01/logs
  node-02/logs
  node-03/logs
cluster-02
  node-01/logs
  node-02/logs
  node-03/logs
  node-04/logs
...

```

Then:

`./runall-cluster.s`


## Granularity of Data

The data is collected at the ASM device level.

This means that data can be sliced and diced many ways.

For instance, take a look at the *dg-diskgroup* scripts:

```text
$ ls -1 *db-diskgroup*

asm-db-diskgroup-breakout.sh
asm-metrics-aggregator-db-diskgroup.sh
asm-metrics-chart-db-diskgroup-synth.sh
asm-metrics-chart-db-diskgroup.sh
asm-metrics-db-diskgroup-synth.pl
asm-metrics-db-diskgroup-synth.sh
run-db-diskgroup.sh

```

These scripts can be used to create charts for each database and diskgroup pairing.

For instance, if there are 42 databases sharing the +DATA diskgroup, then 42 differenct XLXS files will be created, each showing the individual contribution toward all IO seen in +DATA.

