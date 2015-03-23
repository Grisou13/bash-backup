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
# 		*ftp*
# 		*wget*
# 		*tar*
# 		*rm*
# 		*getopts*
# 		*sed*
# 		*ssh*
# 		*awk*
# 		*mkdir*
# 		*grep*
# 		*cat*
# 		*df*
# 		*tr*
# 		*mv*
# 		*setsid*
# 		*chmod*
# 		*cat*
# 		*head*
# 		*tail*
#				
# Argument :
#	-h --help      		Show this message
#	Required : 
#	   -u --user=STRING      	User name for connection
#	   -p --password=STRING     Password for the user
#	   -r --remote-host=ADDR    Server address
#      -d --remote-dir=DIR  	Directory on the remote server to backup  	   
#    Optional :	   
#      -b --backup-dir=DIR		Local directory to move archived folder
#	   -f --filename=FILE		Final filename for the backup filename.tar.gz
#	   -s --secure          	Uses sftp instead of standard ftp
#	   --port=STRING 			Port number for FTP/SFTP connection
#	   --cut-dirs=NUMBER     	ignore NUMBER remote directory components, wget parameter, default : 2 (eg: ../../example = /example with)
#	   --no-zip					doesn't zip the downloaded directory and instead moves it direcly in the backup directory
#        

set -e #enable errors
function cleanup {
	if [[ -z $debug ]]; then
		$RM -rf $tmpdir > /dev/null 2>&1
		$RM -rf $tmpsize > /dev/null 2>&1
		$RM -rf $tmplog > /dev/null 2>&1
		if [[ -f $SSH_ASKPASS_SCRIPT ]]; then
			$RM -rf $SSH_ASKPASS_SCRIPT > /dev/null 2>&1
		fi
	fi
}
trap cleanup EXIT #on every exit cleanup tmp files
####################################################################################################################
############################# Variable configuration ###############################################################
####################################################################################################################

filename= #filename
tmpdir= #temporary olcation for files
#temporary files for crawling remote website
tmplog="list"
tmpsize="size"
logdir="/var/log" #log directory
log="$logdir/$(basename $0).log" #log file

port=
cutdirs=0

USER=
PASSWORD=
REMOTEHOST=
RDIRECTORY=
SECURE=
BACKUPDIR=$(pwd)

error=
####################################################################################################################
############################# Check log availability ###############################################################
####################################################################################################################

if [ -f "$log" ]; then
	echo "">>$log
	echo "####################################################################################################################">>$log
	echo "####################################################################################################################">>$log
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
FTP=$(which ftp)
if [ -z "$FTP" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: ftp not found exiting!" >>$log
fi
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
SSH=$(which ssh)
if [ -z "$SSH" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: ssh not found!" >>$log
fi
BZIP=$(which bzip2)
if [ -z "$BZIP" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: bzip2 not found!" >>$log
fi
MV=$(which mv)
if [ -z "$MV" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: mv not found!" >>$log
fi
SETSID=$(which setsid)
if [ -z "$SETSID" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: setsid not found!" >>$log
fi
TR=$(which tr)
if [ -z "$TR" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: tr not found!" >>$log
fi
AWK=$(which awk)
if [ -z "$AWK" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: awk not found!" >>$log
fi
GREP=$(which grep)
if [ -z "$GREP" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: grep not found!" >>$log
fi
CAT=$(which cat)
if [ -z "$CAT" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: cat not found!" >>$log
fi
DF=$(which df)
if [ -z "$DF" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: df not found!" >>$log
fi
CHMOD=$(which chmod)
if [ -z "$CHMOD" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: chmod not found!" >>$log
fi
HEAD=$(which head)
if [ -z "$HEAD" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: head not found!" >>$log
fi
TAIL=$(which tail)
if [ -z "$TAIL" ]; then
	error=true
    echo "[$(date +%d.%m@%H.%M.%S)] Error: tail not found!" >>$log
fi
####################################################################################################################
############################# Argument parsing #####################################################################
####################################################################################################################
#Help function for usage of this script

usage()
{
echo <"

usage: $0 options

This script will run a backup of any remote site with an ftp/sftp connection, and backup recursivly a directory

All long arguments that require a value must be used with '=' sign to asign a value, as such : --long-arg=value

OPTIONS:
	-h --help      		Show this message
	Required : 
	   -u --user=STRING      	User name for connection
	   -p --password=STRING     Password for the user
	   -r --remote-host=ADDR    Server address
   	   -d --remote-dir=DIR  	Directory on the remote server to backup
   	   
    Optional : 	   
       -b --backup-dir=DIR		Local directory to move archived folder, if not specified it will be the current working directory
	   -f --filename=FILE		Final filename for the backup filename.tar.bz2
	   -s --secure          	Uses sftp instead of standard ftp
	   --port=STRING 			Port number for FTP/SFTP connection
	   --cut-dirs=NUMBER     	ignore NUMBER remote directory components, see WGET --cut-dirs , default : 0 (eg: ../../example = /example with)
	   --no-zip					doesn't zip the downloaded directory and instead moves it direcly in the backup directory


The remote path can be passed either relativly, or absolutly, just keep in mind that when it is relative it must be from the entry point of the connection.
The remote host directory can act like a wild card /dir/*.zip, since it uses wget or scp.
The filename of the local backup .tar.bz2 is by default backup-HOST-YYYY.m.d.HH.MM.SS

This script will exit with 0 if everything was OK, 1 if an error was encountered, and 2 if an argument is not valid
"
exit 2; #exit with 1 since an argument was invalid
}
#required arguments must be seperated by a ':'
#Optional arguments must be at first and not seperated

while getopts hfbsu:p:r:-: arg; do
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
				RDIRECTORY="$OPTARG"
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
			--debug)
				debug=true
			;;
			--no-zip)
				nozip=true
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
if [ -z ${REMOTEHOST+x} ] && [ -z ${PASSWORD+x} ] && [ -z ${RDIRECTORY+x} ] && [ -z ${USER+x} ] ; then
    usage
fi

#####Re-assign some variables with arguments that were passed
tmplog="list-$REMOTEHOST"
if [ -z ${filename} ]; then
	filename="backup-$REMOTEHOST-$(date +%Y%m%d%H%M%S)" #filename
fi
tmpdir="/tmp/$filename" #temporary olcation for files
mkdir $tmpdir > /dev/null 2>&1

if [[ ! -z ${cutdirs+x} ]]; then
	WGETOPTIONS="${WGETOPTIONS} --cut-dirs=$cutdirs"
fi
if [ ! -z ${SECURE} ] && [ -z ${port} ] ; then
	port="22"
elif [ -z ${port} ]; then
	port="21"
fi

#http://www.dslreports.com/forum/r23739041-Bash-Script-path-correcting
LEN=${#BACKUPDIR}-1
 
if [ "${BACKUPDIR:LEN}" != "/" ]; then
  BACKUPDIR=$BACKUPDIR"/"
fi
#create the backup directory if it doesnt exist
if [ ! -e $BACKUPDIR ]; then
    mkdir $BACKUPDIR > /dev/null 2>&1
fi
####################################################################################################################
############################# Check for errors before continuaing ##################################################
####################################################################################################################
if [ ${error} ] ; then
	echo "[$(date +%Y%m%d%H%M%S)] Error occured : exiting...." >>$log && exit 1;
fi
IFS=","
#$(echo $RDIRECTORY | sed -e 's/, /, /g')
for DIRECTORY in $RDIRECTORY; do
	echo "[$(date +%Y%m%d%H%M%S)] Info:  Retrieving $DIRECTORY">>$log

	####################################################################################################################
	############################# Check remote site size ###############################################################
	####################################################################################################################
	echo "[$(date +%Y%m%d%H%M%S)] Info: calculating remote folder size">>$log
	if [ ! ${SECURE} ]; then
	#List all files in remote directory recursively to a temporary file
			$FTP -n $REMOTEHOST $port << END_SCRIPT > ${tmplog} 2>&1
			quote USER $USER
			quote PASS $PASSWORD

			cd $DIRECTORY
			ls -lR

			quit
END_SCRIPT


		if [[ $? != 0 ]] ; then
			echo "[$(date +%Y%m%d%H%M%S)] Error:  Failed to connect via FTP, exited with error code : $?">>$log
			exit 1;
		fi

		#Get remote directory size * 1.6
		$CAT $tmplog | \
		$GREP ^- | \
		sed s/\ /{space}/ | \
		$AWK '{sum+= $5}END{print sum*1.6;}' | \
		sed s/{space}/\ / > $tmpsize;

	else
		#https://www.exratione.com/2014/08/bash-script-ssh-automation-without-a-password-prompt/
		#----------------------------------------------------------------------
		# Create a temp script to echo the SSH password, used by SSH_ASKPASS
		#----------------------------------------------------------------------
		 
		SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
		$CAT > ${SSH_ASKPASS_SCRIPT} <<EOL
	#!/bin/bash
	echo "${PASSWORD}"
EOL
		$CHMOD u+x ${SSH_ASKPASS_SCRIPT}
			# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
		export DISPLAY=:0
		 
		# Tell SSH to read in the output of the provided script as the password.
		# We still have to use setsid to eliminate access to a terminal and thus avoid
		# it ignoring this and asking for a password.
		export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}
		 
		# LogLevel error is to suppress the hosts warning. The others are
		# necessary if working with development servers with self-signed
		# certificates.
		$SETSID $SSH -oLogLevel=error -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -p ${port} ${USER}@${REMOTEHOST} "ls -lR $DIRECTORY" >> $tmplog
		if [[ $? != 0 ]] ; then
			echo "[$(date +%Y%m%d%H%M%S)] Error:  Failed to connect via FTP, exited with error code : $?">>$log
			exit 1;
		fi

		#Get remote directory size * 1.6
		$CAT $tmplog | \
		$GREP ^- | \
		sed s/\ /{space}/ | \
		$AWK '{sum+= $5}END{print sum*1.6;}' | \
		sed s/{space}/\ / > $tmpsize;
	fi

	if [[ ! -f $tmpsize ]]; then
		echo "[$(date +%Y%m%d%H%M%S)] Error: temporary file for directory size wasn't created, cannot continue">>$log
		exit 1;
	fi

	#Get local filestystem available bytes
	# http://stackoverflow.com/questions/19703621/get-free-disk-space-with-df-to-just-display-free-space-in-kb
	echo "[$(date +%Y%m%d%H%M%S)] Info: calculating local folder size">>$log
	$DF -k $BACKUPDIR | \
	$GREP -v 'Use%' |\
	$TR -d '\n' |\
	$AWK '{print $4}' >> $tmpsize;

	#remote size is in 1st line of $tmpsize
	REMOTESIZE=$($HEAD -n 1 $tmpsize | $AWK '{printf "%.0f",$1/1024}')
	#local size is in 2nd/last line of file $tmpsize
	LOCALSIZE=$($TAIL -n 1 $tmpsize | $AWK '{printf "%.0f",$1}')

	if [ $REMOTESIZE -gt $LOCALSIZE ]; then
		echo "[$(date +%Y%m%d%H%M%S)] Error: size available on local disk is insufficient, exited with error code : $?">>$log
		exit 1;
	fi

	####################################################################################################################
	############################# Download files by ftp or sftp ########################################################
	####################################################################################################################
	echo "[$(date +%Y%m%d%H%M%S)] Info: started downloading files">>$log
	if [ ! -z ${SECURE} ]; then
		#----------------------------------------------------------------------
		# Create a temp script to echo the SSH password, used by SSH_ASKPASS
		#----------------------------------------------------------------------
		 
		SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
		cat > ${SSH_ASKPASS_SCRIPT} <<EOL
	#!/bin/bash
	echo "${PASSWORD}"
EOL
		$CHMOD u+x ${SSH_ASKPASS_SCRIPT}
			# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
		export DISPLAY=:0
		 
		# Tell SSH to read in the output of the provided script as the password.
		# We still have to use setsid to eliminate access to a terminal and thus avoid
		# it ignoring this and asking for a password.
		export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}
		 
		# LogLevel error is to suppress the hosts warning. The others are
		# necessary if working with development servers with self-signed
		# certificates.
		c="$SCP -oLogLevel=error -r -C -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -P ${port} -pv $USER@$REMOTEHOST:$DIRECTORY $tmpdir"
		echo "[$(date +%Y%m%d%H%M%S)] Info: downloading command = $c">>$log
		$SETSID $SCP -oLogLevel=error -r -C -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -P ${port} -pv $USER@$REMOTEHOST:$DIRECTORY $tmpdir >> $log 2>&1
	else
		echo "[$(date +%Y%m%d%H%M%S)] Info: downloading command = $WGET -vr -nc -nH -x -np -P $tmpdir --cut-dirs=$cutdirs ftp://$USER:$PASSWORD@$REMOTEHOST/$DIRECTORY">>$log
		$WGET -vr -nc -nH -x -np -P $tmpdir --cut-dirs=$cutdirs ftp://$USER:$PASSWORD@$REMOTEHOST/$DIRECTORY >> $log 2>&1
	fi
	#check exit code of wget
	if [[ $? != 0 ]]; then
		echo "[$(date +%Y%m%d%H%M%S)] Error:  Failed to download exited with code : $?">>$log
		exit 1;
	fi

done
####################################################################################################################
############################# Archive ##############################################################################
####################################################################################################################
if [ ! -z ${nozip} ]; then
	#no archiving moving files instead
	$MV -vfn $tmpdir $BACKUPDIR
else
	#archiving
	echo "[$(date +%Y%m%d%H%M%S)] Info: started archiving">>$log
	$TAR -vcf $BACKUPDIR$filename.tar $tmpdir >> $log 2>&1
	$BZIP -9v $BACKUPDIR$filename.tar >> $log 2>&1
	#check exit code of tar
	if [[ $? != 0 ]]; then
		echo "[$(date +%Y%m%d%H%M%S)] Error: Failed to compress exited with code : $?">>$log
		exit 1;
	fi
fi

####################################################################################################################
echo "[$(date +%Y%m%d%H%M%S)] Info: finishing and cleaning up.....">>$log
exit 0;