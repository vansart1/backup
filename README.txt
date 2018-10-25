Wrapper and daemon for borg backups to remote host over ssh

Automatically create backups periodically and prunes extra backups using a daemon
Has keep_alive to ensure daemon keeps running
Has notifier to send alert if backups don't happen after a time delay
Set and forget setup!

Written by Victor Ansart Sept 2018


##################################
Instructions for seting up server:
##################################

1) On server, create new user on server and set password
	adduser backup

2) On client, create ssh keypair
	ssh-keygen -t ed25519 -f ~/.ssh/key_name

3) On client, copy pubkey to server 
	ssh-copy-id -i key_name.pub backup@server.local

4) On client, test ssh connection using pubkey authentication
	ssh -i .ssh/key_name backup@server.local

5) On server, secure ssh access by adding the following at the end of sshd_config in /etc/ssh/
	Match User backup
	    PasswordAuthentication no
	    AuthenticationMethods publickey
	    AllowAgentForwarding no
	    AllowTcpForwarding no
	    X11Forwarding no

6) On server, restrict ssh key by modifying "authorized_keys" file in backup user's ~/.ssh/ folder

It should look like the following:
	command=“/path/to/bin/borg serve --restrict-to-path /path/to/backup_repo/“ ssh-rsa AAAFB5[…]

7) Install borg
	sudo apt install borgbackup



##################################
Instructions for seting up client:
##################################

1) On client, download backup files from github
	git clone https://github.com/vansart1/backup.git

2) On client, install backup tool
	a) chmod +x install.sh
	b) ./install.sh

3) On client, edit config file, backup.conf in /usr/local/etc/backup/ to fit your needs

4) On client, initialize borg repository on server
	backup initialize

5) Backups will begin to run automatically with daemon.
To manually start a backup, run:
	backup backupAndPrune




Once installed type "backup -h" for more information.

