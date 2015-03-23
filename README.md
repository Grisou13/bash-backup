# bash-backup
A backup utility for Linux machines using only ftp connection
Required arguments
| Short  | Long  | Description  | \n
|---|---|---| \n
| -u  | --user=STRING  | User name for connection  | \n
| -p  | --password=STRING  | Password for the user | \n
| -r  | --remote-host=ADDR  | Server address | \n
| -d  | --remote-dir=DIR  | Directory on the remote server to backup | \n


	-h --help      		Show this message
	Required : 
	          	
	         
	        
         		   
    Optional :	   
      -b --backup-dir=DIR		Local directory to move archived folder
	   -f --filename=FILE		Final filename for the backup filename.tar.gz
	   -s --secure          	Uses sftp instead of standard ftp
	   --port=STRING 			Port number for FTP/SFTP connection
	   --cut-dirs=NUMBER     	ignore NUMBER remote directory components, wget parameter, default : 2 (eg: ../../example = /example with)
	   --no-zip					doesn't zip the downloaded directory and instead moves it direcly in the backup directory
