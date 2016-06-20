#!/bin/sh
prompt=$(echo $1 | sed s/_/__/g)
zenity --entry --title "ssh(1) Authentication" --text="$prompt" --hide-text
