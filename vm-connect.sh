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
    LOG_FILE=
    
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

get_vmlist() {
    SSH_ERR_FILE=$(mktemp)
    if [ "$SSH_USER" != "" ] ; then
        SSH_CMD="${SSH_USER}@${SSH_HOST}"
    else
        SSH_CMD="${SSH_HOST}"
    fi
    VMLIST=`ssh -oBatchMode=yes ${SSH_CMD} 'onevm list -l ID,NAME --csv' 2> $SSH_ERR_FILE | sed 1d | tr ',' '\n'`
    SSH_ERROR=`cat $SSH_ERR_FILE`
    if [ "$SSH_ERROR" != "" ] ; then error "SSH Connection failure:\n$SSH_ERROR"; exit 1 ; fi
    rm -f $SSH_ERR_FILE
}

select_vm() {
    get_vmlist
    IFS=$'\n'
    SELECTED_VM=`zenity --list --title='Choose vm' --column="ID" --column="NAME" ${VMLIST[@]}`
}

get_vminfo() {
    SSH_ERR_FILE=$(mktemp)
    if [ "$SSH_USER" != "" ] ; then
        SSH_CMD="${SSH_USER}@${SSH_HOST}"
    else
        SSH_CMD="${SSH_HOST}"
    fi
    VMINFO=`ssh -oBatchMode=yes ${SSH_CMD} "onevm show $SELECTED_VM --xml" 2> $SSH_ERR_FILE`
    SSH_ERROR=`cat $SSH_ERR_FILE`
    if [ "$SSH_ERROR" != "" ] ; then error "SSH Connection failure:\n$SSH_ERROR"; exit 1 ; fi
    rm -f $SSH_ERR_FILE
}

connect_vm() {
    select_vm
    get_vminfo
    HOST=`echo $VMINFO | grep -Po '(?<=\<HOSTNAME\>)[0-9a-zA-Z-]*(?=\</HOSTNAME\>)' | head -n1`
    PORT=`echo $VMINFO | grep -Po '(?<=\<PORT\>\<!\[CDATA\[)[0-9]*(?=\]\]\>\</PORT\>)' | head -n1`
    PASSWD=`echo $VMINFO | grep -Po '(?<=\<PASSWD\>\<!\[CDATA\[)[0-9a-zA-Z-]*(?=\]\]\>\</PASSWD\>)' | head -n1`
    echo $VMINFO
    echo HOST: $HOST PORT:  $PORT PASSWD:  $PASSWD

    VV_FILE=$(mktemp)
    cat > $VV_FILE <<EOF
[virt-viewer]
type=spice
host=$HOST
port=$PORT
password=$PASSWD
delete-this-file=1
fullscreen=0
title=win7x86_2:%d
toggle-fullscreen=shift+f11
release-cursor=shift+f12
secure-attention=ctrl+alt+end
EOF

    remote-viewer $VV_FILE
}
loadkeys $@
connect_vm
