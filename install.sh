#!/usr/bin/env bash

#Installs backup script, sets up configuration and log files, and crontab

#determine path where backup tool will be saved depending on if installed as root or not
if [[ $EUID -eq 0 ]]; then
	#running as root
	backupPath=/usr/bin/backup
else
	#not running as root
	backupPath=/usr/local/bin/backup
fi


########## paths to install files #############

#path where backup tool will be installed
backupPath='/usr/local/bin/backup'

#path where conf file will be saved
confPath='/usr/local/etc/backup/backup.conf'

#path where backupd daemon will be installed
backupDaemonPath='/usr/local/bin/backupd'

#path where keep_alive dependency will be installed
keep_alivePath='/usr/local/bin/keep_alive'

#path where backup_checker dependency will be installed
backup_checkerPath='/usr/local/bin/backup_checker'



############# STARTING INSTALL ####################

echo "Installing backup..."

echo "Moving files to appropriate location..."



#################### install backup tool ###################

#check to see if backup alredy installed
if [ -f "$backupPath" ] 
then
	echo "backup is already installed!"
	echo -n "Would you like to reinstall it (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ]; #wants to reinstall
	then
    	echo "Reinstalling backup..."
    	#Install backup.sh script in /usr/local/bin
		cp backup.sh "$backupPath"

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Skipping backup reinstallation..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else	#backup not installed, so install
	#Install backup.sh script in /usr/local/bin
	cp backup.sh "$backupPath"
fi


#check to see if backup was successfully installed
if [ ! -f "$backupPath" ] 
then
	echo "backup utility installation failed..."
	echo "Quitting"
	exit 2
fi



################# install config ######################

#create directory for backup conf files if it doesnt exist
if [ ! -d /usr/local/etc/backup ]
then
	mkdir /usr/local/etc/backup
fi

#check to see if conf file alredy installed
if [ -f "$confPath" ] 
then
	echo "backup.conf already exists in /etc/backup/!"
	echo -n "Would you like to overwrite the current version with defaults (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ] ; #wants to reinstall
	then
    	echo "Overwritting backup.conf..."
    	#Copy backup.conf to /etc/backup/
		cp backup.conf "$confPath"

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Keeping current backup.conf..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else   #backup not installed, so install

    	#Copy backup.conf to /etc/backup/
		cp backup.conf "$confPath"
fi

#check to see if conf file was successfully copied
if [ ! -f "$confPath" ] 
then
	echo "backup configuration file copying failed..."
	echo "Quitting"
	exit 2
fi

#Write README file in configuration folder
printf "Borg backup wrapper written by Victor Ansart. \\nType \"backup -h\" for information on usage. \\n" > /usr/local/etc/backup/README.txt



#################### install backup daemon ###################

#check to see if backupDaemon alredy installed
if [ -f "$backupDaemonPath" ] 
then
	echo "backupDaemon is already installed!"
	echo -n "Would you like to reinstall it (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ]; #wants to reinstall
	then
    	echo "Reinstalling backupd daemon..."
    	#Install backupd.sh script in /usr/local/bin
		cp backupd.sh "$backupDaemonPath"

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Skipping backupd daemon reinstallation..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else	#backupDaemon not installed, so install
	#Install backupd.sh script in /usr/local/bin
	cp backupd.sh "$backupDaemonPath"
fi


#check to see if backupDaemon was successfully installed
if [ ! -f "$backupDaemonPath" ] 
then
	echo "backupd daemon installation failed..."
	echo "Quitting"
	exit 2
fi



################## install dependencies keep_alive ################################

###########check to see if keep_alive alredy installed
if [ -f "$keep_alivePath" ] 
then
	echo "Dependency keep_alive is already installed!"
	echo -n "Would you like to reinstall it (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ]; #wants to reinstall
	then
    	echo "Reinstalling keep_alive dependency..."
    	#Install keep_alive script in /usr/local/bin
		cp keep_alive.sh "$keep_alivePath"
		chmod 755 /usr/local/bin/keep_alive

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Skipping keep_alive reinstallation..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else	#keep_alive not installed, so install
	#Install keep_alive.sh script in /usr/local/bin
	cp keep_alive.sh "$keep_alivePath"
	chmod 755 "$keep_alivePath"
fi

#check to see if keep_alive was successfully installed
if [ ! -f "$keep_alivePath" ] 
then
	echo "keep_alive dependency installation failed..."
	echo "Quitting"
	exit 2
fi



################## install dependencies backup_checker ################################

#check to see if backup_checker alredy installed
if [ -f "$backup_checkerPath" ] 
then
	echo "backup_checker is already installed!"
	echo -n "Would you like to reinstall it (y/n)? "
	read response
	if [ "$response" != "${response#[Yy]}" ]; #wants to reinstall
	then
    	echo "Reinstalling backup_checker..."
    	#Install backup_checker.sh script in /usr/local/bin
		cp backup_checker.sh "$backup_checkerPath"

	elif [ "$response" != "${response#[Nn]}" ];  #does not want to reinstall
	then
    	echo "Skipping backup_checker reinstallation..."
    else
    	echo "Please type 'Y' or 'N' as an answer"
    	echo "Quitting."
    	exit 1
	fi
else	#backup_checker not installed, so install
	#Install backup_checker.sh script in /usr/local/bin
	cp backup_checker.sh "$backup_checkerPath"
fi


#check to see if backup_checker was successfully installed
if [ ! -f "$backup_checkerPath" ] 
then
	echo "backup_checker utility installation failed..."
	echo "Quitting"
	exit 2
fi



################## setup crontab ###########################################

cronInfo="$(crontab -l)"   #read crontab
if [[ "$cronInfo" = *"$backupDaemonPath"* ]];    #see if crontab already modified
then
	echo "crontab already modified. Skipping crontab modification..."
else
	#add entry for backup in crontab.
	(crontab -l 2>/dev/null; echo "#crontab entries for backup tool") | crontab -			#comment
	(crontab -l 2>/dev/null; echo "@reboot $backupDaemonPath") | crontab -			#start backupd at startup
	(crontab -l 2>/dev/null; echo "*/10 * * * * $keep_alivePath $backupDaemonPath") | crontab -		#run keep_alive tool every 10 mn for backupd
	(crontab -l 2>/dev/null; echo "0 */6 * * * $backup_checkerPath") | crontab -		#run backup_checker tool every 6 hours
#	(crontab -l 2>/dev/null; echo "0 */2 * * * /usr/local/bin/backup backupAndPrune 1>>/dev/null 2>/usr/local/var/log/backup.latest") | crontab -
fi



echo "Installation complete!"

exit 0
