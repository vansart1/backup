#!/usr/bin/env bash

# Script to send notification if backup hasn't happened in more than 2 days
# Written by Victor Ansart in October 2018


last_backup_time_file='/usr/local/etc/backup/lastBackupTime'

#time before sending an alert in hours (48 hours for 2 days)
alert_timeout=48


#help messages
helpMsg='usage: backup_checker

backup_checker is a tool to check if a backup happened in past two days and send an notification otherwise
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




last_backup_time="$(head -1 "$last_backup_time_file")"     #get last_backup_time from file

current_time=$(date +%s)     #get current time from date command displayed in seconds

time_diff_seconds=$(( $current_time - $last_backup_time ))

time_diff_min=$(( $time_diff_seconds / 60 ))
time_diff_hour=$(( $time_diff_min / 60 ))
time_diff_day=$(( $time_diff_hour / 24 ))

#echo "last backup: $last_backup_time"
#echo "current_time: $current_time"
#echo "time_diff_seconds: $time_diff_seconds"
#echo "time_diff_min: $time_diff_min"
#echo "time_diff_hour: $time_diff_hour"
#echo "time_diff_day: $time_diff_day"

#notification settings
notification_title="Backup"
notification_text="Alert! A backup hasn't occured in $time_diff_day days"
notification_sound="Submarine"

if [[ $time_diff_hour -ge $alert_timeout ]]
then
	osascript -e "display notification \"$notification_text\" with title \"$notification_title\" sound name \"$notification_sound\""
fi

exit 0

