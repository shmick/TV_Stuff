#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin

# This is a dirty hack to keep the media user logged in.
# For some reason it keeps getting kicked out to the login
# prompt, which means EyeTV is not able to record shows.

# We check to see if the Dock app is running
# If not, wait 30 seconds and check again
# If it's still not running, we reboot the mac and let the
# account auto login as it normally should

LOG="$HOME/reboot.log"

check() {
TEST=$(pgrep -U $(whoami) Dock)
RESULT="$?"
}

check
if [ "$RESULT" = 0 ]
then
echo "$(date) Dock found" >> $LOG
exit 
else
echo "$(date) Dock not found, wating 30 seconds" >> $LOG
sleep 30
check
    if [ "$RESULT" = 0 ]
    then
    exit
    else
    echo "$(date) Dock still not found, rebooting NOW" >> $LOG
    sudo reboot
    fi
fi
