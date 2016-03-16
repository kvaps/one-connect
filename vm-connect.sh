#!/bin/bash

usage() {
      echo "Usage:    vm-connect.sh --host HOST [--username USERNAME]"
      echo
      echo "Arguments:"
      echo "    -H, --host                  OpenNebula hostname or IP"
      echo "    -u, --user                  Username for SSH-connection"
      echo "    -l, --log-file              Path to log file"
      echo "    -d, --debug                 Enable debug output"
      echo "    -h, --help                  This message"
      exit
}

debug() {
    echo -e "[DEBUG] $1"
    if [ "$LOG_FILE" != "" ] ; then echo -e `date "+[%m-%d-%y %T][DEBUG] "` $1 >> $LOG_FILE ; fi
}
error() {
    echo -e "[ERR] $1"
    if [ "$LOG_FILE" != "" ] ; then echo -e `date "+[%m-%d-%y %T][ERROR] "` $1 >> $LOG_FILE ; fi
    zenity --error --text "\n$1\n"
}

loadkeys() {
    OPTS=`getopt -o hHuld: --long help,host,user,log-file,debug: -n 'parse-options' -- "$@"`
    
    if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
    
    HELP=
    SSH_HOST=
    SSH_USER=
    LOG_FILE=
    DEBUG=
    
    while true; do
      case "$1" in
        -H | --host     ) SSH_HOST="$2"; shift ; shift ;;
        -u | --user     ) SSH_USER="$2"; shift ; shift ;;
        -l | --log-file ) LOG_FILE="$2"; shift ; shift ;;
        -h | --help     ) HELP=true; shift ;;
        -d | --debug    ) DEBUG=true; shift ;;
        -- ) shift; break ;;
        * ) break ;;
      esac
    done

    if [ "$HELP" == true ] ; then usage; break; fi
    if [ "$SSH_HOST" == "" ] ; then error "Host address is not set" break; exit 1; fi
}

ssh_exec() {
    SSH_ERR_FILE=$(mktemp)
    if [ "$SSH_USER" != "" ] ; then
        SSH_BASE="${SSH_USER}@${SSH_HOST}"
    else
        SSH_BASE="${SSH_HOST}"
    fi

        SSH_CMD="ssh -oBatchMode=yes ${SSH_BASE}"
    if [ -z "$2" ] ; then
        debug "executing: $SSH_CMD $1"
        eval "SSH_STDOUT=\`$SSH_CMD $1 2> $SSH_ERR_FILE\`"
        eval 'debug "received: $'$SSH_STDOUT'"'
    else
        debug "executing: $1=\`$SSH_CMD $2\`"
        eval "$1=\`$SSH_CMD $2 2> $SSH_ERR_FILE\`"
        eval 'debug "received: $'$1'"'
    fi

    SSH_ERROR=`cat $SSH_ERR_FILE`
    if [ "$SSH_ERROR" != "" ] ; then error "SSH Connection failure:\n$SSH_ERROR"; exit 1 ; fi
    rm -f $SSH_ERR_FILE
}

get_vmlist() {
    ssh_exec 'VMLIST' "onevm list -l ID,NAME --csv"
    IFS='' VMLIST=`echo $VMLIST | sed 1d | tr ',' '\n'`
}

select_vm() {
    get_vmlist
    IFS=$'\n' SELECTED_VM=`zenity --list --title='Choose vm' --column="ID" --column="NAME" ${VMLIST[@]}`
}

start_vm() {
    ssh_exec "onevm resume $SELECTED_VM"
}

stop_vm() {
    ssh_exec "onevm poweroff $SELECTED_VM"
}

get_vminfo() {
    ssh_exec 'VMINFO' "onevm show $SELECTED_VM --xml"
}

connect_vm() {
    get_vminfo
    HOST=`echo $VMINFO | grep -Po '(?<=\<HOSTNAME\>)[0-9a-zA-Z-]*(?=\</HOSTNAME\>)' | head -n1`
    PORT=`echo $VMINFO | grep -Po '(?<=\<PORT\>\<!\[CDATA\[)[0-9]*(?=\]\]\>\</PORT\>)' | head -n1`
    PASSWD=`echo $VMINFO | grep -Po '(?<=\<PASSWD\>\<!\[CDATA\[)[0-9a-zA-Z-]*(?=\]\]\>\</PASSWD\>)' | head -n1`
    TYPE=`echo $VMINFO | grep -Po '(?<=\<TYPE\>\<!\[CDATA\[)(vnc|spice|VNC|SPICE)(?=\]\]\>\</TYPE\>)' | head -n1`
    VV_FILE=$(mktemp)
    cat > $VV_FILE <<EOF
[virt-viewer]
type=$TYPE
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

    debug "VV file: \n`cat $VV_FILE`"
    remote-viewer $VV_FILE
}
loadkeys $@
select_vm
#start_vm
sleep 10
connect_vm
#stop_vm
