#!/bin/bash

set -e 
# This script only works with PostgreSQL
# updates c_partstates to text.
# http://www.sogo.nu/bugs/view.php?id=3175
# the field length was actually changed in v2.2.18

defaultusername=$USER
defaulthostname=localhost
defaultdatabase=$USER
#indextable=sogo_folder_info
indextable=$(sogo-tool dump-defaults -f /etc/sogo/sogo.conf | awk -F\" '/ OCSFolderInfoURL =/  {print $2}' |  awk -F/ '{print $NF}')
if [ -z "$indextable" ]; then
  echo "Couldn't fetch OCSFolderInfoURL value, aborting" >&2
  exit 1
fi

read -p "Username ($defaultusername): " username
read -p "Hostname ($defaulthostname): " hostname
read -p "Database ($defaultdatabase): " database

if [ -z "$username" ]
then
  username=$defaultusername
fi
if [ -z "$hostname" ]
then
  hostname=$defaulthostname
fi
if [ -z "$database" ]
then
  database=$defaultdatabase
fi

sqlscript=""

function growVC() {
    oldIFS="$IFS"
    IFS=" "
    part="`echo -e \"ALTER TABLE $table ALTER COLUMN c_partstates TYPE TEXT;\\n\"`";
    sqlscript="$sqlscript$part"
    IFS="$oldIFS"
}

echo "Converting c_cycleinfo from VARCHAR(255) to TEXT in calendar quick tables" >&2
tables=`psql -t -U $username -h $hostname $database -c "select split_part(c_quick_location, '/', 5) from $indextable where c_path3 = 'Calendar';"`

for table in $tables;
do
  growVC
done

echo "$sqlscript" | psql -q -e -U $username -h $hostname $database
