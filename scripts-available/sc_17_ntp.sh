#!/bin/bash
# Script to check if the NTP client is running and is synchronized.

# Set SYSCHECK_HOME if not already set.

# 1. First check if SYSCHECK_HOME is set then use that
if [ "x${SYSCHECK_HOME}" = "x" ] ; then
# 2. Check if /etc/syscheck.conf exists then source that (put SYSCHECK_HOME=/path/to/syscheck in ther)
    if [ -e /etc/syscheck.conf ] ; then 
	source /etc/syscheck.conf 
    else
# 3. last resort use default path
	SYSCHECK_HOME="/opt/syscheck"
    fi
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "$0: Can't find syscheck.sh in SYSCHECK_HOME ($SYSCHECK_HOME)" ;exit ; fi

## Import common definitions ##
. $SYSCHECK_HOME/config/syscheck-scripts.conf

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=17

# Index is used to uniquely identify one test done by the script (a harddrive, crl or cert)
SCRIPTINDEX=00

getlangfiles $SCRIPTID
getconfig $SCRIPTID

ERRNO_1=01
ERRNO_2=02
ERRNO_3=03
ERRNO_4=04
ERRNO_5=05


# help
if [ "x$1" = "x--help" ] ; then
    echo "$0 $HELP"
    echo "$ERRNO_1/$DESCR_1 - $HELP_1"
    echo "$ERRNO_2/$DESCR_2 - $HELP_2"
    echo "$ERRNO_3/$DESCR_3 - $HELP_3"
    echo "$ERRNO_4/$DESCR_4 - $HELP_4"
    echo "$ERRNO_5/$DESCR_5 - $HELP_5"
    exit
elif [ "x$1" = "x-s" -o  "x$1" = "x--screen" ] ; then
    PRINTTOSCREEN=1
fi

checkntp () {
	NTPSERVER=$1
	SCRIPTINDEX=$2 
	if [ "x${NTPSERVER}" = "x" ] ; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_5 "$DESCR_5" "ntpserver not set"
		return
	fi
	

	XNTPDPID=`ps -ef | grep ntpd | grep -v grep | awk '{print $2}'`
	if [ x"$XNTPDPID" = "x" ]; then
		printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_2 "$DESCR_2"
		exit
	fi	

	# Get information about ntp
    result=$(echo "peers" | ${NTPBIN} -n 2>&1| grep ${NTPSERVER} | egrep "^(\*)" )
    STATUS=${STATUS:-$result}

}

# check with the IP:s of all ntp servers

STATUS=""

for (( i = 0 ;  i < ${#NTPSERVER[@]} ; i++ )) ; do
    checkntp ${NTPSERVER[$i]} $SCRIPTINDEX
done

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

if [ "x${result}" = "x" ] ; then
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $ERROR $ERRNO_3 "$DESCR_3" "$NTPSERVER ($result)" 
else
        printlogmess ${SCRIPTNAME} ${SCRIPTID} ${SCRIPTINDEX}   $INFO $ERRNO_1 "$DESCR_1" "$NTPSERVER"
fi

