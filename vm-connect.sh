#!/bin/bash

usage() {
      echo "Usage:    vm-connect.sh --host HOST [--username USERNAME]"
      echo
      echo "Arguments:"
      echo "    -H, --host                  OpenNebula hostname or IP"
      echo "    -u, --user                  Username for SSH-connection"
      echo "    -l, --log-file              Path to log file"
      echo "    -h, --help                  This message"
      exit
}

error() {
    echo -e $1
    if [ "$LOG_FILE" != "" ] ; then echo -e `date "+[%m-%d-%y %T] "` $1 >> $LOG_FILE ; fi
    zenity --error --text "\n$1\n"
}

loadkeys() {
    OPTS=`getopt -o hHul: --long help,host,user,log-file: -n 'parse-options' -- "$@"`
    
    if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
    
    HELP=
    SSH_HOST=
    SSH_USER=
    LOG_FILE=vm-connect.log
    
    while true; do
      case "$1" in
        -H | --host     ) SSH_HOST="$2"; shift ; shift ;;
        -u | --user     ) SSH_USER="$2"; shift ; shift ;;
        -l | --log-file ) LOG_FILE="$2"; shift ; shift ;;
        -h | --help     ) HELP=true; shift ;;
        -- ) shift; break ;;
        * ) break ;;
      esac
    done

    if [ "$HELP" == true ] ; then usage; break; fi
    if [ "$SSH_HOST" == "" ] ; then error "Host address is not set" break; exit 1; fi
}

## Ask login password
#ENTRY=`zenity --password --username`
#
#case $? in
#         0)
#	 	ONE_USER=`echo $ENTRY | cut -d'|' -f1`
#	 	ONE_PASS=`echo $ENTRY | cut -d'|' -f2`
#		;;
#         1)
#                echo "Stop login.";;
#        -1)
#                zenity --error
#esac


get_vmlist() {
    SSH_ERR_FILE=$(mktemp)
    VMLIST=`ssh -oBatchMode=yes $SSH_USER@$SSH_HOST 'onevm list -l ID,NAME --csv' 2> $SSH_ERR_FILE | sed 1d | tr ',' '\n'`
    SSH_ERROR=`cat $SSH_ERR_FILE`
    if [ "$SSH_ERROR" != "" ] ; then error "SSH Connection failure:\n$SSH_ERROR"; exit 1 ; fi
    rm -f $SSH_ERR_FILE
}

select_vm() {
    get_vmlist
    IFS=$'\n'
    SELECTED_VM=`zenity --list --title='Choose vm' --column="ID" --column="NAME" ${VMLIST[@]}`
}

loadkeys $@
select_vm
