#!/usr/bin/env bash

# Script to run backups to server using borgbackup tool
# Checks whether server can be pinged and then initiates backup
# Backup is done to server using ssh in borgbackup
# Written by Victor Ansart in October 2018


##################-setup-################


conf_file='/usr/local/etc/backup/backup.conf'
omit_from_backup_file='/usr/local/etc/backup/excludeFromBackup'
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


##################-functions-#############

#cleans string passed as argument
#Ex: cleanString "$variable_with_dirty_string"
cleanString()
{
	local clean=${1//[^a-zA-Z0-9\/\\_ -.]/}
	echo "$clean"
}

#write out data to log file with date
#Ex: log "data to write to log"
log()
{
	echo "$(date)" "$@" >> "$logfile"
}

#prints the status of the latest command and exits accordingly
#Ex: printCommandStatusAndExit $? "command_type"
printCommandStatusAndExit()
{
	if [ "$1" -eq 0 ]
	then
		printf "%s" "$2"
		printf " command succeeded. \\n"
		log "$2" " command succeeded"
		exit 0
	fi
	if [ "$1" -eq 1 ]
	then
		printf "%s" "$2"
		printf " command had a warning. \\n"
		log "$2" "command had a warning"
		exit 1
	fi
	if [ "$1" -gt 1 ]
	then
		printf "%s" "$2"
		printf " command had an error. \\n"
		log "$2" " command had an error"
		exit "$1"
	fi
}


##################-main-##################

#clean variables from conf file
#backup_location=$(cleanString "$backup_location")

#server=$(cleanString "$server")

#user=$(cleanString "$user")

#repo_location=$(cleanString "$repo_location")

#borg_pass=$(cleanString "$borg_pass")

#key_location=$(cleanString "$key_location")



#assemble remaining necessary variables
host=${HOSTNAME%'.local'}

host=$(cleanString "$host")

backup_name="$host"'_'$(date +%m-%d-%y_%H:%M)

repo=$user'@'$server':'$repo_location

logfile="/usr/local/var/log/backup.log"


#help messages
helpMsg='usage: backup <command>
   <command>
      initialize   			Initiate a repository
      backup 				Create a backup archive only
      backupAndPrune    		Create a backup archive and then prune repo
      listArchives			List all the archives in repo
      listLatestContents	  	List contents of latest archive in repo
      extractPath 			Extract specific path from latest archive in repo
      extractAll 			Extract entire latest archive from repo
      exportKey				Export the repo key for backing it up
      pause 				Pause backup daemon and stop current borg operation
      resume				Resume backup daemon
      stop				Stop currently running borg operation

backup is a wrapper for borg which is used for backups onto a remote server
'

extractPathMsg='usage: backup extractPath [PATH]
backup extractPath: error: argument 
'


#######################script#####################


#export variables for editing $PATH so commands can be found
export PATH=/usr/local/bin:$PATH 		#so can find borg command
export PATH=/sbin:$PATH  				#so can find ping command

#export variables needed for borg
export BORG_RSH="ssh -i $key_location"

export BORG_PASSPHRASE="$borg_pass"

export BORG_REPO="$repo"

if [ "$#" -eq 0 ]      #check number of arguments supplied
then
	printf "%s" "$helpMsg"
	exit 1
fi

if [ "$1" == '-h' ] || [ "$1" == '--help' ] # display help before ping test
then
	printf "%s" "$helpMsg"
	exit 1
fi


#check to see if server is up and available using ping
if ! ping -c 5 -o "$server" 2>/dev/null 1>/dev/null ;
then 
     printf "Server not found! \\n"
     log "Server not found!"
     exit 2
fi
printf "Server found \\n"
log "Server found"


case $1 in      #go through supplied arguments
	-h|--help)
		printf "%s" "$helpMsg"
		exit 1
		;;
	initialize)
		msg="Initializing remote repo... \\n"
		printf "$msg"
		log "$msg"
		borg init --verbose --encryption=repokey
		printCommandStatusAndExit $? "initialize"
		;;
	backup)
		msg="Creating remote backup archive... \\n"
		printf "$msg"
		log "$msg"
		borg create --verbose --list --stats --progress --compression lz4  --exclude-caches --exclude-from "$omit_from_backup_file" ::"$backup_name" "$backup_location"
		create_exit="$?"
		if [[ $create_exit -eq 0 ]]     #check to see if latest command ran successfully
		then
			date +%s > "$last_backup_time_file"      #write current time to file so we know time of latest backup
		fi
		printCommandStatusAndExit "$create_exit" "backup"
		;;
	backupAndPrune)
		msg="Creating remote backup archive... \\n"
		printf "$msg"
		log "$msg"
		borg create --verbose --list --stats --progress --compression lz4 --exclude-caches --exclude-from "$omit_from_backup_file" ::"$backup_name" "$backup_location"
		create_exit="$?"
		if [[ $create_exit -eq 0 ]]     #check to see if latest command ran successfully
		then
			date +%s > "$last_backup_time_file"      #write current time to file so we know time of latest backup
		fi
		msg="Pruning extra archives in remote repo... \\n"
		printf "$msg"
		log "$msg"
		borg prune --list --prefix "$host" --keep-last 15 --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 5
		prune_exit="$?"
		general_exit=$(( create_exit > prune_exit ? create_exit : prune_exit ))
		printCommandStatusAndExit "$general_exit" "backup and/or prune"
		;;
	listArchives)
		msg="Listing archives stored in remote repo... \\n"
		printf "$msg"
		log "$msg"
		borg list
		printCommandStatusAndExit $? "listArchives"
		;;
	listLatestContents)
		msg="Listing latest remote archive contents... \\n"
		printf "$msg"
		log "$msg"
		latestArchive=$(borg list | tail -n 1 | awk '{print $1}')
		borg list ::"$latestArchive"
		printCommandStatusAndExit $? "listLatestContents"
		;;
	extractPath)
		if [ "$#" -ne 2 ]	   #not enough args for command and path
		then
			printf "%s" "$extractPathMsg"
			exit 1
		fi
		msg="Extracting data in supplied path from latest archive in remote repo to current directory... \\n"
		printf "$msg"
		log "$msg"
		latestArchive=$(borg list | tail -n 1 | awk '{print $1}')
		borg extract --list ::"$latestArchive" "$2"
		printCommandStatusAndExit $? "extractPath"
		;;
	extractAll)
		msg="Extracting all data from latest archive in remote repo to current directory... \\n"
		printf "$msg"
		log "$msg"
		latestArchive=$(borg list | tail -n 1 | awk '{print $1}')
		borg extract --list ::"$latestArchive"
		printCommandStatusAndExit $? "extractAll"
		;;
	exportKey)
		msg="Exporting repo key to current directory... \\nNote: key is still encrypted with borg passphrase \\nBe sure to move somewhere safe!! \\n"
		printf "$msg"
		log "$msg"
		borg key export "$repo" "$host.repokey"
		printCommandStatusAndExit $? "exportKey"
		;;
	pause)
		msg="Pausing daemon and stopping current borg backup operation... \\n"
		printf "$msg"
		log "$msg"

		#disable crontab keep alive
		crontab -l | sed -E '/ *([^ ]+  *){5}[^ ]*\/usr\/local\/bin\/keep_alive/s/^/#/' | crontab -

		#kill daemon
		daemon_PID=$(ps -ax | grep /usr/local/bin/backupd | grep -v grep | awk '{ print $1 }')	#get PID of daemon process
		if [[ "$daemon_PID" -ne "" ]]   #check that daemon was found
		then
			kill "$daemon_PID"		#kill daemon gently
		fi

		#kill borg
		borg_PID=$(pgrep borg | sort -gr | head -n 1)	#get PID of latest borg process
		if [[ "$borg_PID" -ne "" ]]   #check that borg process was found
		then
			kill "$borg_PID"		#kill borg process gently
		fi
		printCommandStatusAndExit 0 "pause"
		;;
	resume)
		msg="Resuming backup daemon... \\n"
		printf "$msg"
		log "$msg"

		#restart daemon if necessary
		daemon_PID=$(ps -ax | grep /usr/local/bin/backupd | grep -v grep | awk '{ print $1 }')	#get PID of daemon process
		if [[ "$daemon_PID" -eq "" ]]   #check that daemon is NOT running
		then
			backupd &  		#restart daemon in background
		fi

		#re-enable crontab for keep alive
		crontab -l | sed -E '/# *([^ ]+  *){5}[^ ]*\/usr\/local\/bin\/keep_alive/s/^#*//' | crontab -

		printCommandStatusAndExit 0 "resume"
		;;
	stop)
		msg="Stopping current borg backup operation... \\n"
		printf "$msg"
		log "$msg"
		borg_PID=$(pgrep borg | sort -gr | head -n 1)	#get PID of latest borg process
		if [[ "$borg_PID" -ne "" ]]   #check that borg process was found
		then
			kill "$borg_PID"		#kill borg process gently
		fi
		printCommandStatusAndExit 0 "Stop"
		;;
	*)
		printf "%s" "$helpMsg"
		exit 1
esac


exit 0
