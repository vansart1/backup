#!/usr/bin/env bash

# Daemon to trigger backups every X hours following config file
# Written by Victor Ansart in October 2018

conf_file='/usr/local/etc/backup/backup.conf'
last_backup_time_file='/usr/local/etc/backup/lastBackupTime'


## check conf file to make sure it has no nefarious input
# commented lines, empty lines und lines such as var_name='var_value' are valid
syntax_check="^\s*#|^\s*$|^[a-zA-Z0-9_]+='[a-zA-Z0-9_/.]*'$"

# check if the file contains undesired characters
if egrep -q -v "${syntax_check}" "$conf_file"; 
then
	echo "Syntax error in config file: ${conf_file}." 
	egrep -vn "${syntax_check}" "$conf_file"
	exit 10
fi

#import config file if no problems
source "${conf_file}"

#time interval between backups in HOURS (default is 2 hours)
#backup_timeout=2

#how often to check that backup server is available when it is time to do a backup in MINUTES (default is 10 mn)
#check_timeout=10

#name of backup server to ping
#server="capsule.local"


############# setup #####################

#help messages
helpMsg='usage: backupd

backupd is a daemon for the "backup" tool to make a backup every X hours
Written by Victor Ansart
'

if [ "$#" -ne 0 ]      #check number of arguments supplied
then
	printf "%s" "$helpMsg"
	exit 1
fi

if [ "$1" == '-h' ] || [ "$1" == '--help' ] # display help
then
	printf "%s" "$helpMsg"
	exit 1
fi


################ script ###############

#export variables for editing $PATH so commands can be found
export PATH=/usr/local/bin:$PATH 		#so can find borg command
export PATH=/sbin:$PATH  				#so can find ping command


while :   #infinite loop
do
	last_backup_time="$(head -1 "$last_backup_time_file")"     #get last_backup_time from file

	current_time=$(date +%s)     #get current time from date command displayed in seconds

	time_diff_seconds=$(( $current_time - $last_backup_time ))

	time_diff_min=$(( $time_diff_seconds / 60 ))
	time_diff_hour=$(( $time_diff_min / 60 ))

	#echo "last backup: $last_backup_time"
	#echo "current_time: $current_time"
	#echo "time_diff_seconds: $time_diff_seconds"
	#echo "time_diff_min: $time_diff_min"
	#echo "time_diff_hour: $time_diff_hour"


	if [[ $time_diff_hour -ge $backup_timeout ]]       #check to see if last backup later than timeout
	then
		printf "Timeout reached! \\n"
		if ping -c 5 -o "$server" 2>/dev/null 1>/dev/null ;    	#check to see if server is up and available using ping
		then 
			#echo "Server found!"
			backup backupAndPrune 1>>/dev/null 2>/usr/local/var/log/backup.latest    			#run backup

		fi
	fi

	sleep $(( $check_timeout * 60))

done

exit 0

