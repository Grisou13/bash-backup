# bash-backup
A backup utility for Linux machines using only ftp connection. It uses normal Ubuntu components to work.

Dependencies
===================================
All these dependencies maybe installed on your distro, unless your a dinausor.
The dependencies are mainly listed because the user running this script may be restricted, so make sure it can access all these commands.
This script uses bash *getopts* for argument parsing, please make sure that your distro supports it.
* *ftp*
* *wget*
* *tar*
* *rm*
* *getopts*
* *sed*
* *ssh*
* *awk*
* *mkdir*
* *grep*
* *cat*
* *df*
* *tr*
* *mv*
* *setsid*
* *chmod*

Usage
====================================
Before using this script make sure that you have all the dependencies.

This script was entented to be portable but may not work on some distros, if so please fork me.

All backups created by this script are named as **backup-HOST-YYYY.m.d.HH.MM.SS** .

All backups that are **not** specified with --no-zip, will get bziped.

basic usage would be : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html`, this would backup the remote directory recursivly and put it in the current working directory.

With a backup directory : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html -b /var/backups/`, this would backup the remote directory recursivly with WGET, and put it in the specified directory.

With multiple remote directories : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html,/var/logs/ -b /var/backups/`, this would backup all the remote directory recursivly with WGET, and put it in the specified directory, in 1 archive.

With secure : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html -b /var/backups/ --secure`, this would backup the remote directory recursivly with SCP, and put it in the specified directory.

Every action is loged and put in the directory `/var/log/script-name.log`.

If you want to use this script without getting in the directory or anything, simply do a `mv backup.sh /usr/local/bin/name-of-script` (you may require sudo to move it there), then let it executable with `sudo chmod +x /usr/local/bin/name-of-script`.

Arguments
===================================
For help just call `backup.sh -h`

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

