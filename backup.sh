#!/bin/sh
# FTP updload script
#
# Version: 1.0
# Author: Thomas Ricci (thomas.ricci@nagra.com)
# License : MIT 
#    Copyright (c) 2015 Thomas Ricci NagraVision
#
#		Permission is hereby granted, free of charge, to any person obtaining a copy
#		of this software and associated documentation files (the "Software"), to deal
#		in the Software without restriction, including without limitation the rights
#		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#		copies of the Software, and to permit persons to whom the Software is
#		furnished to do so, subject to the following conditions:
#
#		The above copyright notice and this permission notice shall be included in all
#		copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#		SOFTWARE.
#
# Dependencies : 
#               wget
#				tar
#				rm
#				getopt
#				sed
# Argument :
# 	Required :
#        -u username -r server -p password -d ../../directoryFromRootByRelativePath
#   Optional :
#        -v (verbose)
####################################################################################################################
############################# File configuration ###################################################################
####################################################################################################################
filename="backup-$FTPS-$(date +%d.%m@%H.%M.%S)" #filename
backupdir="/vagrant/backups/" #final destination for files in tar.gz
tmpdir="/tmp/$filename" #temporary olcation for files
#temporary files for crawling remote website
tmplog="/tmp/wget-website-$REMOTEHOST-size"
tmpremotesize="/tmp/remotesize"
tmplocalsize="/tmp/localsize"

cutdirs="2"
logdir="/var/log/cron-backup" #log directory
log="$logdir/log" #log file

error=false
####################################################################################################################
############################# Check log availability ###############################################################
####################################################################################################################
if [ ! -f "$log" ]; then
	echo "\n[$(date +%d.%m@%H.%M.%S)]Started backup\n" >>$log
else
	if [ ! -e $logdir ]; then
	    mkdir $logdir
	elif [ ! -d $logdir ]; then
	    echo "$logdir already exists but is not a directory\n" >> error-backup.txt
	    error=true
    else
    	echo "Couldn't write to log file $log\n" >> error-backup.txt
	fi
fi
####################################################################################################################
############################# Check dependencies ###################################################################
####################################################################################################################
TAR=$(which tar)
if [ -z "$TAR" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: tar not found exiting!\n" >>$log
fi

WGET=$(which wget)
if [ -z "$WGET" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: wget not found exiting!\n" >>$log
fi

RM=$(which rm)
if [ -z "$RM" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: rm not found!\n" >>$log
fi

GETOPT=$(which getopt)
if [ -z "$GETOPT" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: getopt not found!\n" >>$log
fi

####################################################################################################################
############################# Argument treatement ##################################################################
####################################################################################################################
#Help function for usage of this script

usage()
{
echo <"

usage: $0 options

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

"
exit 1
}

USER=
PASSWORD=
REMOTEHOST=
DIRECTORY=
SECURE=
while getopts hfsu:p:r:-: arg; do
  case $arg in
  	h )
		usage
	;;
    u )    
		USER="$OPTARG"
	;;
    p )    
		PASSWORD="$OPTARG"
	;;
	r )    
		REMOTEHOST="$OPTARG"
	;;
	f )
		FILENAME="$OPTARG"
	;;
	b )
		backupdir="$OPTARG"
	;;
	s )
		SECURE=true
	;;
    - )
		[ $OPTIND -ge 1 ] && optind=$(expr $OPTIND - 1 ) || optind=$OPTIND
         eval OPTION="\$$optind"
         OPTARG=$(echo $OPTION | cut -d'=' -f2)
         OPTION=$(echo $OPTION | cut -d'=' -f1)
         case $OPTION in
            --user)
            	USER="$OPTARG"
			;;
			--remote-host)	
				REMOTEHOST="$OPTARG" 
			;;
			--password)
				PASSWORD="$OPTARG"
			;;
			--remote-dir)
				DIRECTORY="$OPTARG"
			;;
			--backup-dir)
				backupdir="$OPTARG"
			;;
			--secure)
				SECURE=true
			;;
			--filename)
				filename="$OPTARG"
			;;
			--cut-dirs)
				cutdirs="$OPTARG"
			;;
			--help)
				usage
			;;
            '' )
            	break # "--" terminates argument processing
			;;
            * )    
				if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                    echo "Unknown option --${OPTARG}" >&2
                fi
            ;;
       esac
       OPTIND=1
       shift
	;;
    \? )   exit 2 ;;
  esac
done
shift $((OPTIND-1))

if [ -z "$REMOTEHOST" ] && [ -z "$PASSWORD" ] && [ -z "$DIRECTORY" ] && [ -z" $USER" ] ; then
    usage
fi

####################################################################################################################
############################# Check for errors before continuaing ##################################################
####################################################################################################################

if [ -z $error ]; then
	echo "[$(date +%d.%m@%H.%M.%S)] Error: exiting....\n" >>$log && exit 1;
else
	echo "[$(date +%d.%m@%H.%M.%S)] Info: All dependencies found starting download\n" >>$log;
fi
####################################################################################################################
############################# Check remote site size ###############################################################
####################################################################################################################
 
#List all files in remote directory recursively
ftp -n $REMOTEHOST <<END_SCRIPT > ${tmplog} 2>&1
quote USER $USER
quote PASS $PASSWORD

cd $DIRECTORY
ls -lR

quit
END_SCRIPT
#Get remote directory size * 1.6
cat $tmplog | \
grep ^- | \
sed s/\ /{space}/ | \
awk '{sum+= $5}END{print sum*1.6;}' | \
sed s/{space}/\ / > $tmpremotesize;

#Get local filestystem available bytes
# http://stackoverflow.com/questions/19703621/get-free-disk-space-with-df-to-just-display-free-space-in-kb
df -k $backupdir | \
tail -1 | \
awk '{print $4}' > $tmplocalsize;


if [[ $(cat $tmplocalsize) -gt $(cat $tmpremotesize) ]]; then
	echo "size available"
fi


exit 1;

####################################################################################################################
############################# Download files by ftp or sftp ########################################################
####################################################################################################################
if [ -z "$SECURE" ]; then
	$WGET -P $tmpdir -q -c -r -nH --no-parent --cut-dirs=$cutdirs -e robots=off --output-file="$log" sftp://$USER:$PASSWORD@$REMOTEHOST$DIRECTORY
else
	$WGET -P $tmpdir -q -c -r -nH --no-parent --cut-dirs=$cutdirs -e robots=off --output-file="$log" ftp://$USER:$PASSWORD@$REMOTEHOST$DIRECTORY
fi

if [[ $? != 0 ]]; then
	echo "[$(date +%d.%m@%H.%M.%S)] Failed to download exited with code : $?">>$log
	exit 1;
fi
####################################################################################################################
############################# Archive ##############################################################################
####################################################################################################################
$TAR -vcf $backupdir/$filename.tar.gz $tmpdir

if [[ $? != 0 ]]; then
	echo "[$(date +%d.%m@%H.%M.%S)] Failed to compress exited with code : $?">>$log
	exit 1;
fi
####################################################################################################################
############################# clear tmp files ######################################################################
####################################################################################################################
$RM -rf $tmpdir
