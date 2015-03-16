#!/bin/bash
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
#				getopts
#				sed
#				scp
#				ssh
#				
# Argument :
#	-h --help      		Show this message
#	Required : 
#	   -u --user=STRING      	User name for connection
#	   -p --password=STRING     Password for the user
#	   -r --remote-host=ADDR    Server address
#   	   -d --remote-dir=DIR  	Directory on the remote server to backup
#   	   -b --backup-dir=DIR		Local directory to move archived folder
#    Optional : 	   
#	   -f --filename=FILE		Final filename for the backup filename.tar.gz
#	   -s --secure          	Uses sftp instead of standard ftp
#	   --port=STRING 			Port number for FTP/SFTP connection
#	   --cut-dirs=NUMBER     	ignore NUMBER remote directory components, wget parameter, default : 2 (eg: ../../example = /example with)
#
#        

set -e
function cleanup {
  	$RM -rf $tmpdir > /dev/null 2>&1
	$RM -rf $tmpsize > /dev/null 2>&1
	$RM -rf $tmplog > /dev/null 2>&1
	if [[ -f $SSH_ASKPASS_SCRIPT ]]; then
		$RM -rf $SSH_ASKPASS_SCRIPT > /dev/null 2>&1
	fi
}
trap cleanup EXIT
####################################################################################################################
############################# Variable configuration ###############################################################
####################################################################################################################

filename= #filename
tmpdir= #temporary olcation for files
#temporary files for crawling remote website
tmplog="list"
tmpsize="size"
logdir="/var/log/cron-backup" #log directory
log="$logdir/log" #log file

WGETOPTIONS="-c -r -nH --no-parent -e robots=off" #all basic wget options for download

port=

USER=
PASSWORD=
REMOTEHOST=
DIRECTORY=
SECURE=
BACKUPDIR=
error=
####################################################################################################################
############################# Check log availability ###############################################################
####################################################################################################################


if [ -f "$log" ]; then
	echo "">>$log
	echo "">>$log
	echo "[$(date +%d.%m@%H.%M.%S)]Started backup" >>$log
else
	if [ ! -e $logdir ]; then
	    mkdir $logdir
	elif [ ! -d $logdir ]; then
	    echo "$logdir already exists but is not a directory" >> error-backup
	    error=true
    else
    	echo "Couldn't write to log file $log" >> error-backup
	fi
fi
####################################################################################################################
############################# Check dependencies ###################################################################
####################################################################################################################
TAR=$(which tar)
if [ -z "$TAR" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: tar not found exiting!" >>$log
fi

WGET=$(which wget)
if [ -z "$WGET" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: wget not found exiting!" >>$log
fi

RM=$(which rm)
if [ -z "$RM" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: rm not found!" >>$log
fi
SCP=$(which scp)
if [ -z "$SCP" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: scp not found!" >>$log
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
	   -u --user=STRING      	User name for connection
	   -p --password=STRING     Password for the user
	   -r --remote-host=ADDR    Server address
   	   -d --remote-dir=DIR  	Directory on the remote server to backup
   	   -b --backup-dir=DIR		Local directory to move archived folder
    Optional : 	   
	   -f --filename=FILE		Final filename for the backup filename.tar.gz
	   -s --secure          	Uses sftp instead of standard ftp
	   --port=STRING 			Port number for FTP/SFTP connection
	   --cut-dirs=NUMBER     	ignore NUMBER remote directory components, wget parameter, default : 2 (eg: ../../example = /example with)

If you want to pass an absolute path to the remote directory, you have to add a '/' (eg: /dir/on/remote-server/to/backup/)
The remote host directory can act like a wild card /dir/*.zip, since it uses wget.
The filename of the .tar.gz backup is by default backup-HOST-DD.M@HH.MM.SS
"
exit 1
}


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
		BACKUPDIR="$OPTARG"
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
				BACKUPDIR="$OPTARG"
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
			--port)
				port="$OPTARG"
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
#check mandatory options
if [ -z ${REMOTEHOST+x} ] && [ -z ${PASSWORD+x} ] && [ -z ${DIRECTORY+x} ] && [ -z ${USER+x} ] && [ -z ${BACKUPDIR+x} ] ; then
    usage
fi

#####Re-assign some variables with arguments that were passed
tmplog="list-$REMOTEHOST"
filename="backup-$REMOTEHOST-$(date +%d.%m@%H.%M.%S)" #filename
tmpdir="/tmp/$filename" #temporary olcation for files
if [[ ! -z $cutdirs ]]; then
	WGETOPTIONS="${WGETOPTIONS} --cut-dirs=$cutdirs"
fi
if [ ! -e $BACKUPDIR ]; then
    mkdir $BACKUPDIR
fi
####################################################################################################################
############################# Check for errors before continuaing ##################################################
####################################################################################################################
if [ ${error} ] ; then
	echo "[$(date +%d.%m@%H.%M.%S)] Error occured : exiting...." >>$log && exit 1;
fi
####################################################################################################################
############################# Check remote site size ###############################################################
####################################################################################################################
echo "[$(date +%d.%m@%H.%M.%S)] Info: calculating remote folder size">>$log
if [[ -z ${SECURE+x} ]]; then
#List all files in remote directory recursively to a temporary file
	if [ -z ${port+x} ] ; then
		ftp -n $REMOTEHOST << END_SCRIPT > ${tmplog} 2>&1
		quote USER $USER
		quote PASS $PASSWORD

		cd $DIRECTORY
		ls -lR

		quit
END_SCRIPT
	else
		ftp -n $REMOTEHOST $port << END_SCRIPT > ${tmplog} 2>&1
		quote USER $USER
		quote PASS $PASSWORD

		cd $DIRECTORY
		ls -lR

		quit
END_SCRIPT

	fi

	if [[ $? != 0 ]] ; then
		echo "[$(date +%d.%m@%H.%M.%S)] Error:  Failed to connect via FTP, exited with error code : $?">>$log
		exit 1;
	fi

	#Get remote directory size * 1.6
	cat $tmplog | \
	grep ^- | \
	sed s/\ /{space}/ | \
	awk '{sum+= $5}END{print sum*1.6;}' | \
	sed s/{space}/\ / > $tmpsize;


else
	#https://www.exratione.com/2014/08/bash-script-ssh-automation-without-a-password-prompt/
	#----------------------------------------------------------------------
	# Create a temp script to echo the SSH password, used by SSH_ASKPASS
	#----------------------------------------------------------------------
	 
	SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
	cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/bin/bash
echo "${PASSWORD}"
EOL
	chmod u+x ${SSH_ASKPASS_SCRIPT}
		# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
	export DISPLAY=:0
	 
	# Tell SSH to read in the output of the provided script as the password.
	# We still have to use setsid to eliminate access to a terminal and thus avoid
	# it ignoring this and asking for a password.
	export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}
	 
	# LogLevel error is to suppress the hosts warning. The others are
	# necessary if working with development servers with self-signed
	# certificates.
	SSH_OPTIONS="-oLogLevel=error"
	SSH_OPTIONS="${SSH_OPTIONS} -oStrictHostKeyChecking=no"
	SSH_OPTIONS="${SSH_OPTIONS} -oUserKnownHostsFile=/dev/null"
	if [ -z ${port+x} ]; then
		SSH_OPTIONS="${SSH_OPTIONS} -p ${port}"
	fi
	setsid ssh ${SSH_OPTIONS} ${USER}@${REMOTEHOST} "ls -lR $DIRECTORY" >> $tmplog
	if [[ $? != 0 ]] ; then
		echo "[$(date +%d.%m@%H.%M.%S)] Error:  Failed to connect via FTP, exited with error code : $?">>$log
		exit 1;
	fi

	#Get remote directory size * 1.6
	cat $tmplog | \
	grep ^- | \
	sed s/\ /{space}/ | \
	awk '{sum+= $5}END{print sum*1.6;}' | \
	sed s/{space}/\ / > $tmpsize;
fi

if [[ ! -f $tmpsize ]]; then
	echo "[$(date +%d.%m@%H.%M.%S)] Error: temporary file for directory size wasn't created, cannot continue">>$log
	exit 1;
fi

#Get local filestystem available bytes
# http://stackoverflow.com/questions/19703621/get-free-disk-space-with-df-to-just-display-free-space-in-kb
echo "[$(date +%d.%m@%H.%M.%S)] Info: calculating local folder size">>$log
df $BACKUPDIR | \
tail -1 | \
awk '{print $4}' >> $tmpsize;

#remote size is in 1st line of $tmpsize
REMOTESIZE=$(head -n 1 $tmpsize | awk '{printf "%.0f",$1}')
#local size is in 2nd/last line of file $tmpsize
LOCALSIZE=$(tail -n 1 $tmpsize | awk '{printf "%.0f",$1}')

if [ $REMOTESIZE -gt $LOCALSIZE ]; then
	echo "[$(date +%d.%m@%H.%M.%S)] Error: size available on local disk is insufficient, exited with error code : $?">>$log
	exit 1;
fi

####################################################################################################################
############################# Download files by ftp or sftp ########################################################
####################################################################################################################
echo "[$(date +%d.%m@%H.%M.%S)] Info: started downloading files">>$log
if [ ! -z ${SECURE} ]; then
	#----------------------------------------------------------------------
	# Create a temp script to echo the SSH password, used by SSH_ASKPASS
	#----------------------------------------------------------------------
	 
	SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
	cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/bin/bash
echo "${PASSWORD}"
EOL
	chmod u+x ${SSH_ASKPASS_SCRIPT}
		# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
	export DISPLAY=:0
	 
	# Tell SSH to read in the output of the provided script as the password.
	# We still have to use setsid to eliminate access to a terminal and thus avoid
	# it ignoring this and asking for a password.
	export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}
	 
	# LogLevel error is to suppress the hosts warning. The others are
	# necessary if working with development servers with self-signed
	# certificates.
	SSH_OPTIONS="-oLogLevel=error -r -C"
	SSH_OPTIONS="${SSH_OPTIONS} -oStrictHostKeyChecking=no"
	SSH_OPTIONS="${SSH_OPTIONS} -oUserKnownHostsFile=/dev/null"
	if [ -z ${port+x} ]; then
		SSH_OPTIONS="${SSH_OPTIONS} -P ${port}"
	fi
	setsid $SCP $SSH_OPTIONS $USER@$REMOTEHOST:$DIRECTORY $tmpdir >> $log 2>&1
else
	$WGET -P $tmpdir $WGETOPTIONS --output-file="$log" ftp://$USER:$PASSWORD@$REMOTEHOST/$DIRECTORY >> $log 2>&1
fi
#check exit code of wget
if [[ $? != 0 ]]; then
	echo "[$(date +%d.%m@%H.%M.%S)] Error:  Failed to download exited with code : $?">>$log
	exit 1;
fi
####################################################################################################################
############################# Archive ##############################################################################
####################################################################################################################
#http://www.dslreports.com/forum/r23739041-Bash-Script-path-correcting
echo "[$(date +%d.%m@%H.%M.%S)] Info: started archiving">>$log
LEN=${#BACKUPDIR}-1
 
if [ "${BACKUPDIR:LEN}" != "/" ]; then
  BACKUPDIR=$BACKUPDIR"/"
fi
$TAR -vcf $BACKUPDIR$filename.tar.gz $tmpdir >> $log 2>&1
#check exit code of tar
if [[ $? != 0 ]]; then
	echo "[$(date +%d.%m@%H.%M.%S)] Error: Failed to compress exited with code : $?">>$log
	exit 1;
fi
####################################################################################################################

exit 0;