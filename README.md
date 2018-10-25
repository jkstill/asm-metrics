
# asm-metrics-collector.pl
Collect ASM metrics for further processing.

# asm-metrics-collector.sh
bash driver example 

# asm-metrics-aggregator.pl
This script aggregates metrics based on one column from raw metrics data.
eg. Aggregate IO metrics per diskgroup

# asm-metrics-aggregator.sh
bash driver example - aggregates by diskgroup

# asm-metrics-aggregator_bydisk.sh
bash driver example - aggregates by disk

# asm-metrics-chart.pl
Create Excel file with charts of metrics

# asm-metrics-chart.sh
bash driver example using aggregates by diskgroup

# asm-metrics-chart_bydisk.sh
bash driver example using aggregates by diskname

# asm-metrics-validate.pl
Perl script used to look for negative values in raw CSV files.
Used for some debugging.
This script can be used to look for any value with minor adjustment

# verify.sh
bash script used for verifying aggregates during development


# asm-metrics-fix.pl
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

