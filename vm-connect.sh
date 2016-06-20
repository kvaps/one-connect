#!/bin/bash

usage() {
      echo "Usage:    vm-connect.sh --host HOST [--username USERNAME]"
      echo
      echo "Arguments:"
      echo "    -H, --host                  OpenNebula hostname or IP"
      echo "    -u, --user                  Username for SSH-connection"
      echo "    -k, --key-file              Path to ssh identity file"
      echo "    -n, --no-suspend            No suspend vm after disconnect"
      echo "    -l, --log-file              Path to log file"
      echo "    -d, --debug                 Enable debug output"
      echo "    -h, --help                  This message"
      exit
}

debug() {
    if [ "$DEBUG" == true ] ; then
        echo -e "[DEBUG] $1"
        if [ ! -z "$LOG_FILE" ] ; then echo -e `date "+[%m-%d-%y %T][DEBUG] "` $1 >> $LOG_FILE ; fi
    fi
}
error() {
    echo -e "[ERR] $1"
    if [ ! -z "$LOG_FILE" ] ; then echo -e `date "+[%m-%d-%y %T][ERROR] "` $1 >> $LOG_FILE ; fi
    zenity --title=$TITLE --error --text "\n$1\n"
}

loadkeys() {
    OPTS=`getopt -o hdnHukl: --long help,debug,no-suspend,host,user,key-file,log-file: -n 'parse-options' -- "$@"`
    
    if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
    
    HELP=
    SSH_HOST=
    SSH_USER=
    LOG_FILE=
    DEBUG=
    NO_SUSPEND=
    TITLE=`basename "$0"`
    TEMPDIR="$(mktemp -d /tmp/vm-connect-XXXXXXXXXX)"
    
    while true; do
      case "$1" in
        -h | --help       ) HELP=true; shift ;;
        -d | --debug      ) DEBUG=true; shift ;;
        -n | --no-suspend ) NO_SUSPEND=true; shift ;;
        -H | --host       ) SSH_HOST="$2"; shift ; shift ;;
        -u | --user       ) SSH_USER="$2"; shift ; shift ;;
        -u | --user       ) SSH_USER="$2"; shift ; shift ;;
        -k | --key-file   ) KEY_FILE="$2"; shift ; shift ;;
        -l | --log-file   ) LOG_FILE="$2"; shift ; shift ;;
        -- ) shift; break ;;
        * ) break ;;
      esac
    done

    if [ "$HELP" == true ] ; then usage; break; fi
    if [ -z "$SSH_HOST" ] ; then error "Host address is not set" break; exit 1; fi
}


create_sshask_script(){
   cat > "$1" <<EOF
#!/bin/sh
prompt=\$(echo \$1 | sed s/_/__/g)
zenity --entry --title "ssh(1) Authentication" --text="\$prompt" --hide-text
EOF
    chmod u+x "$1"
}

ssh_login() {
    # Create SSH_ASKPASS script
    SSH_ASKPASS_SCRIPT="${TEMPDIR}/ssh-askpass.sh"
    create_sshask_script $SSH_ASKPASS_SCRIPT
    export SSH_ASKPASS=$SSH_ASKPASS_SCRIPT

    eval `ssh-agent`
    echo | setsid ssh-add $KEY_FILE
    rm -f "$SSH_ASKPASS_SCRIPT"
}

ssh_logout() {
    eval `ssh-agent -k`
    rmdir "$TEMPDIR"
    exit 0
}

ssh_exec() {
    SSH_ERR_FILE="$(mktemp ${TEMPDIR}/ssh-err-XXXXX)"
    SSH_OUT_FILE="$(mktemp ${TEMPDIR}/ssh-out-XXXXX)"

    if [ -z "$SSH_USER" ] ; then
        SSH_BASE="${SSH_HOST}"
    else
        SSH_BASE="${SSH_USER}@${SSH_HOST}"
    fi

    if [ ! -z "$KEY_FILE" ] ; then
	    if [ "$(uname -o)" == "Cygwin" ] ; then
	        KEY_FILE="$(cygpath $KEY_FILE)"
	    fi
        SSH_BASE="${SSH_BASE}"
    fi

        SSH_CMD="ssh -oBatchMode=yes ${SSH_BASE}"

    if [ -z "$3" ] ; then
        COMMAND="$1"
        DESCRIPTION="$2"
    else
        COMMAND="$2"
        DESCRIPTION="$3"
    fi

    debug "executing: $SSH_CMD '$COMMAND'"
    eval "$SSH_CMD '$COMMAND' 1> $SSH_OUT_FILE 2> $SSH_ERR_FILE" | zenity --title=$TITLE --text="$DESCRIPTION" --progress --auto-close


    SSH_OUT=`cat $SSH_OUT_FILE`
    rm -f $SSH_OUT_FILE
    SSH_ERR=`cat $SSH_ERR_FILE | grep -v ^Gtk`
    rm -f $SSH_ERR_FILE

    debug "received: $SSH_OUT"

    if [ ! -z "$SSH_ERR" ] ; then
        error "SSH Connection failure:\n$SSH_ERR"
        exit 1
    fi

    if [ ! -z "$3" ] ; then
        eval $1='`echo "$SSH_OUT"`'
    fi

}

get_vmlist() {
    ssh_exec 'VMLIST' 'onevm list -l ID,NAME,STAT --csv' 'Getting VMs list...'
    IFS=''
    VMLIST=`echo $VMLIST | sed 1d | tr ',' '\n'`
    unset IFS
}

select_vm() {
    get_vmlist
    IFS=$'\n'
    SELECTED_VM=`zenity --list --title=$TITLE --width=600 --height=700 --text='Choose vm:' --hide-column=1 --column="ID" --column="NAME" --column="STAT" ${VMLIST[@]}`
    if [ -z "$SELECTED_VM" ] ; then 
        debug 'aborted'
        exit 0
    fi
    unset IFS
}

start_vm() {
    debug "start vm"
    #wait for LCM_STATE == 0 or 3, and write it to variable
    ssh_exec 'LCM_STATE' '
        get_state="onevm show '$SELECTED_VM' --xml | grep --color=never -o \<LCM_STATE\>[0-9]*\<\/LCM_STATE\> | grep -oP [0-9]*"
        until [ "`eval $get_state`" == "0" ] || [ "`eval $get_state`" == "3" ] ; do
            sleep 1
        done
        eval $get_state
    ' 'Waiting for operable state...'

    if [ "$LCM_STATE" == "0" ] ; then
        ssh_exec "
            # if STATE=HOLD
            if [ ! -z \"\$(onevm show 59 --xml | grep --color=never -E -o \<STATE\>\(2\|6\)\<\/STATE\>)\" ] ; then
                onevm release $SELECTED_VM
            else
                onevm resume $SELECTED_VM
            fi
        " 'Resuming VM...'
    fi
}

stop_vm() {
    if [ "$NO_SUSPEND" != true ] ; then
        ssh_exec "onevm suspend $SELECTED_VM" 'Suspending VM...'
    fi
}

get_vminfo() {
    ssh_exec 'VMINFO' "onevm show $SELECTED_VM --xml" 'Getting VM address...'
}

connect_vm() {
    # wait for LCM_STATE == 3, and connect
    ssh_exec 'VMINFO' '
        get_state="onevm show '$SELECTED_VM' --xml | grep --color=never -o \<LCM_STATE\>[0-9]*\<\/LCM_STATE\> | grep -oP [0-9]*"
        until [ "`eval $get_state`" == "3" ] ; do
            sleep 1
        done
    ' 'Waiting for connect state...'
    get_vminfo

    HOST=`echo $VMINFO | grep -Po '(?<=\<HOSTNAME\>)[0-9a-zA-Z-_.]*(?=\</HOSTNAME\>)' | head -n1`
    PORT=`echo $VMINFO | grep -Po '(?<=\<PORT\>\<!\[CDATA\[)[0-9]*(?=\]\]\>\</PORT\>)' | head -n1`
    PASSWD=`echo $VMINFO | grep -Po '(?<=\<PASSWD\>\<!\[CDATA\[).*(?=\]\]\>\</PASSWD\>)' | head -n1`
    TYPE=`echo $VMINFO | grep -Po '(?<=\<TYPE\>\<!\[CDATA\[)(vnc|spice|VNC|SPICE)(?=\]\]\>\</TYPE\>)' | head -n1`
    NAME=`echo $VMINFO | grep -Po '(?<=\<NAME\>).*(?=\</NAME\>)' | head -n1`
    if which recode >/dev/null; then
        NAME=`echo $NAME | recode html..utf8`
    fi

    VV_FILE=$(mktemp --suffix=.vv ${TEMPDIR}/vm-XXXXX)
    cat > $VV_FILE <<EOF
[virt-viewer]
type=$TYPE
host=$HOST
port=$PORT
password=$PASSWD
delete-this-file=1
fullscreen=0
title=$NAME
toggle-fullscreen=shift+f11
release-cursor=shift+f12
secure-attention=ctrl+alt+end
EOF

    debug "VV file: \n`cat $VV_FILE`"
	if [ "$(uname -o)" == "Cygwin" ] ; then
	    VV_FILE="$(cygpath -w $VV_FILE)"
	fi
    remote-viewer "$VV_FILE"
}

loadkeys $@
ssh_login
trap ssh_logout EXIT INT
select_vm
start_vm
connect_vm
stop_vm
