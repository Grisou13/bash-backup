# bash-backup
A backup utility for Linux machines using only ftp connection
Required arguments
| Short  | Long  | Description  | \n
|---|---|---| \n
| -u  | --user=STRING  | User name for connection  | \n
| -p  | --password=STRING  | Password for the user | \n
| -r  | --remote-host=ADDR  | Server address | \n
| -d  | --remote-dir=DIR  | Directory on the remote server to backup | \n

<<<<<<< HEAD
Dependencies
===================================
#				ftp
#               wget
#				tar
#				rm
#				getopts
#				sed
#				ssh

Install
====================================
Before using this script make sure that you have all the dependencies. This script was entented to be portable but may not work on some distros, if so please fork me

Arguments
===================================

For help just call backup.sh -h

###Required arguments

|        |                      | Description                              |
|--------|----------------------|------------------------------------------|
| -u     | --user=STRING        | User name for connection                 |
| -p     | --password=STRING    | Password for the user                    |
| -r     | --remote-host=ADDR   | Server address                           |
| -d     | --remote-dir=DIR     | Directory on the remote server to backup |

###Optional Arguments


|        |                      | Description                                                                                               |
|--------|----------------------|-----------------------------------------------------------------------------------------------------------|
|        | --no-zip             | Doesn't bzip the downloaded directory and instead moves it direcly in the backup directory                |
| -b     | --backup-dir=DIR     | Local directory to move remote dowloaded folder                                                           |
| -f     | --filename=FILE      | Final filename for the backup filename.tar.gz (or directory with --no-zip)                                |
|        | --cut-dirs=NUMBER    | Ignore NUMBER remote directory components, wget parameter, default : 2 (eg: ../../example = /example with)|
|        | --port=STRING 		| Port number for FTP/SFTP connection                                                                       |
| -s     | --secure          	| Uses sftp instead of standard ftp                                                                         |
=======

	-h --help      		Show this message
	Required : 
	          	
	         
	        
         		   
    Optional :	   
      -b --backup-dir=DIR		Local directory to move archived folder
	   -f --filename=FILE		Final filename for the backup filename.tar.gz
	   -s --secure          	Uses sftp instead of standard ftp
	   --port=STRING 			Port number for FTP/SFTP connection
	   --cut-dirs=NUMBER     	ignore NUMBER remote directory components, wget parameter, default : 2 (eg: ../../example = /example with)
	   --no-zip					doesn't zip the downloaded directory and instead moves it direcly in the backup directory
>>>>>>> 70821f5f0be1d80260ac90cb0f3f9dcf58b730a2
