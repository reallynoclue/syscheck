#!/bin/bash

SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}" # use default if  unset
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;exit ; fi

## Import common definitions ##
source $SYSCHECK_HOME/config/related-scripts.conf

# script name, used when integrating with nagios/icinga
SCRIPTNAME=export_revocation

# uniq ID of script (please use in the name of this file also for convinice for finding next availavle number)
SCRIPTID=901

# how many info/warn/error messages
NO_OF_ERR=3

initscript $SCRIPTID $NO_OF_ERR

# get command line arguments
INPUTARGS=`/usr/bin/getopt --options "hsvc" --long "help,screen,verbose,cert" -- "$@"`
if [ $? != 0 ] ; then schelp ; fi
#echo "TEMP: >$TEMP<"
eval set -- "$INPUTARGS"

while true; do
  case "$1" in
    -s|--screen  ) PRINTTOSCREEN=1; shift;;
    -v|--verbose ) PRINTVERBOSESCREEN=1 ; shift;;
    -c|--cert )   CERTFILE=$2; shift 2;;
    -h|--help )   schelp;exit;shift;;
    --) break;;
  esac
done

# main part of script

if [ ! -d ${OUTPATH2} ] ; then
    mkdir -p ${OUTPATH2}
fi


if [ "x$CERTFILE" = "x" -o ! -r "$CERTFILE" ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
	printtoscreen $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
	exit
fi

# for inital checks
SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)

date >> ${REVLOG}
CERTSERIAL=`openssl x509 -inform der -in "$CERTFILE" -serial -noout | sed 's/serial=//'`
if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
	# we really need a serial
	exit
fi


CERTSUBJECT=$(openssl x509 -inform der -in "$CERTFILE" -subject -noout | sed 's/\//_/gi' | sed 's/subject=//gi' | sed s/=/-/gi | sed  's/\ /_/gi')
if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
	# also without subject we cant continiue
	exit
fi

echo "CERTSERIAL: $CERTSERIAL" >> ${REVLOG}
echo "CERTSUBJECT: $CERTSUBJECT" >> ${REVLOG}
CERT=`openssl x509 -inform der -in "$CERTFILE"`
if [ $? -ne 0 ] ; then
	printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
	# if we cant parse the cert
	exit
fi

CERTSTRING=$(echo $CERT| tr '\n' ';')

echo "CERTSTRING: $CERTSTRING " >> ${REVLOG}
echo                            >> ${REVLOG}

SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
OUTFILE="${OUTPATH2}/revoked-cert-${DATE}-${CERTSUBJECT}-${CERTSERIAL}"
openssl x509 -inform der -in "$CERTFILE" > ${OUTFILE}
if [ $? -eq 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $INFO -e ${ERRNO[1]} -d "${DESCR[1]}" -1 "$?"
else
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[3]}" -1 "$?"
fi

for (( j=0; j < ${#REMOTE_HOST[@]} ; j++ )){
    printtoscreen "Copying file: ${OUTFILE} to:${REMOTE_HOST[$j]} dir:${REMOTE_DIR[$j]} remotreuser:${REMOTE_USER[$j]} sshkey:${SSHKEY[$j]}"
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    ${SYSCHECK_HOME}/related-enabled/917_archive_file.sh ${OUTFILE} ${REMOTE_HOST[$j]} ${REMOTE_DIR[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]}
}
