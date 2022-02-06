

set term on feed off head off
set pause off 
ttitle off
btitle off

set linesize 500 trimspool on

set pagesize 0

prompt inst_id|name|label|path|library|group_number|disk_number|mount_status|header_status|os_mb|total_mb|free_mb|state|repair_timer|failgroup|failgroup_type|redundancy|voting_file

-- library may have commas, so pipe delimited

select 
	inst_id
	|| '|' || name
	|| '|' || label
	|| '|' || path
	|| '|' || library
	|| '|' || group_number
	|| '|' || disk_number
	|| '|' || mount_status
	|| '|' || header_status
	|| '|' || os_mb
	|| '|' || total_mb
	|| '|' || free_mb
	|| '|' || state
	|| '|' || repair_timer
	|| '|' || failgroup
	|| '|' || failgroup_type
	|| '|' || redundancy
	|| '|' || voting_file
from gv$asm_disk
/


