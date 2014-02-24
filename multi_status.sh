#!/bin/bash
#set -x 
#
# Follow me on Twitter https://twitter.com/shmick

# multi_status.sh - display the current status of up to 2 HDHomeRun units
# 
# Use this to compare channel & signal strength stats in real time
#
# You'll need to set the channels on each tuner with the HDHomeRun Config util

#Linux users - you will need to adjust the below path to hdhomerun_config
#
HDHRConfig=/usr/bin/hdhomerun_config

#This script will run every second. Change this to whatever you want.
SECONDS=1

# Gather the IDs of the units and parse the results

Units=`$HDHRConfig discover | awk '{print $3}'`

# Define how many seconds to sleep between 
if [ "$Units" == "found" ]
then
echo "No HDHomeRun units detected, exiting"
exit
fi

# Split the 2 scanned units into variables
a=( $Units )
Unit1=${a[0]}
Unit2=${a[1]}

clear

while true
do
date
# Query the debug info of the first unit
echo "$Unit1, tuner 0"
$HDHRConfig $Unit1 get /tuner0/status
echo "$Unit1, tuner 1"
$HDHRConfig $Unit1 get /tuner1/status

# If a 2nd unit was found, query the lock status 
if [ "$Unit2" != "" ]
then
echo "$Unit2, tuner 0"
$HDHRConfig $Unit2 get /tuner0/status
echo "$Unit2, tuner 1"
$HDHRConfig $Unit2 get /tuner1/status
fi
sleep $SECONDS
clear
done
