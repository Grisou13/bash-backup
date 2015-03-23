# bash-backup
A backup utility for Linux machines using only ftp connection.

It uses normal Ubuntu components to work, and was tested on RedHat

Dependencies
===================================
All these dependencies maybe already installed on your distro, unless your a dinausor comming from unix 1.0.

The dependencies are mainly listed because the user running this script may be restricted, so make sure it can access all these commands.
This script uses bash *getopts* for argument parsing, please make sure that your distro, and bash version supports it.

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
* *cat*
* *head*
* *tail*

Usage
====================================
Before using this script make sure that you have all the dependencies.

This script was entented to be portable but may not work on some distros, if so please fork me.

All backups created by this script are named as **backup-HOST-YYYY.m.d.HH.MM.SS** .

All backups that are **not** specified with --no-zip, will get bziped.

basic usage would be : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html`, this would backup the remote directory recursivly and put it in the current working directory.

With a backup directory : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html -b /var/backups/`, this would backup the remote directory recursivly with WGET, and put it in the specified directory.

You can specify multiple remote directory to backup, which can be usefull if you need logs, and backup some data.

With multiple remote directories : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html,/var/logs/ -b /var/backups/`, this would backup all the remote directory recursivly with WGET, and put it in the specified directory, in 1 archive.

With secure : `./backup.sh -u username -p pwd -r mysite.com -d /var/www/html -b /var/backups/ --secure`, this would backup the remote directory recursivly with SCP, and put it in the specified directory.

Every action is loged and put in the directory `/var/log/script-name.log`.

If the log file wasn't accessible, the script will create in the current working directory a file called *error-backup*

The script will leave with status code:
* **0** if everything was OK
* **1** if there was an error, in which case check the logs
* **2** if there was an error parsing arguments (argument missing, or something)

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

Errors & Debug
=================================
Errors that may accure is when specifing a complex password, oyu may need to put it in simple quotes '', other wise bash tries to interprete it as an argument.

If there was an error during the backup process please check the logs, or if you want debug information, run the script with `/bin/bash +x /path/to/backup-script`, this will give you all debug information needed

There is a argument that you can specify which is `--debug`, and this will leave all temporary files.