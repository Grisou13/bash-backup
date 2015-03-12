# bash-backup
A backup utility for Linux machines using only ftp connection

This script will run a backup of any remote site with an ftp/sftp connection

All long arguments must be used with '=' sign to asign a value, as such : --long-arg=value

OPTIONS:
	-h --help      		Show this message
	Required : 
	   -u --user      		User name for connection
	   -p --password     	Password for the user
	   -r --remote-host 	Server address
   	   -d --remote-dir     	Directory on the remote server to backup (must be relative)
    Optional : 
	   -b --backup-dir		Local directory to move archived folder
	   -f --filename		Final filename for the backup filename.tar.gz
	   -s --secure          Uses sftp instead of standard ftp
	   --cut-dirs			Number of directories to cut wile downloading files (eg: ../../example = /example)
