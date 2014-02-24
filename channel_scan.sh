#!/bin/bash
#set -x 
######################################################################################
#
# channel_scan.sh 
# v2013.11.29.r1
#
# This script will scan a HDHomeRun for ATSC channels and print a formatted list
#
# Use the -csv option to print out CSV formatted results
#
# A note about deciphering the results here:
# http://www.silicondust.com/forum2/viewtopic.php?t=4474
#
# Follow me on Twitter https://twitter.com/shmick
#
######################################################################################

# Set the path to the hdhomerun_config utility here
#
HDHRConfig=/usr/bin/hdhomerun_config

if [ ! -x $HDHRConfig ]
then
echo ""
echo "Unable to locate the hdhomerun_config utility, please edit the HDHRConfig variable in this script"
echo ""
exit
fi

# Attempt to discover HDHR devices on the LAN
#
Devices=`$HDHRConfig discover | awk '{print $3}'`

# Exit if no device are found
#
if [ "$Devices" == "found" ]
then
echo "No HDHomeRun units detected, exiting"
exit
fi

# Create unique variables for each device found
#
FoundDev=( $Devices )
HDHRDev1=${FoundDev[0]}
HDHRDev2=${FoundDev[1]}

# Functions to check the lock status of each tuner
#
D1T0status () {
echo `$HDHRConfig $HDHRDev1 get /tuner0/lockkey`
}
D1T1status () {
echo `$HDHRConfig $HDHRDev1 get /tuner1/lockkey` 
}
D2T0status () {
echo `$HDHRConfig $HDHRDev2 get /tuner0/lockkey`
}
D2T1status () {
echo `$HDHRConfig $HDHRDev2 get /tuner1/lockkey`
}

# Determine which Device and Tuner we're going to use by looking for the first tuner that isn't locked
# If all tuners are locked, the script will exit
#

if [ "$(D1T0status)" = "none" ]
then 
        ScanDev=$HDHRDev1
        ScanTuner=0
elif [ "$(D1T1status)" = "none" ]
then 
        ScanDev=$HDHRDev1
        ScanTuner=1
elif [ "$(D2T0status)" = "none" ]
then 
        ScanDev=$HDHRDev2
        ScanTuner=0
elif [ "$(D2T1status)" = "none" ]
then 
        ScanDev=$HDHRDev2
        ScanTuner=1
else
        echo "Sorry, no tuners are available"
exit
fi

# Perform a tuner scan, outputting the results to $ScanResults
#
RunScan () {
ScanResults=`$HDHRConfig $ScanDev scan $ScanTuner \
| tr "\n" " " \
| tr "(" " " \
| tr ")" " " \
| sed -e 's/SCANNING....................../\'$'\n/g' \
| grep TSID \
| sed -e 's/PROGRAM....//g' \
-e 's/L.....8vsb.//g' \
-e 's/TSID.........//g' \
-e 's/ss=//g' \
-e 's/s.q=//g' \
| awk '{print  $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t\t"$7"\t"$8"\t\t"$9"\t"$10"\t\t"$11"\t"$12"\t\t"$13"\t"$14"\t\t"$15"\t"$16}'` 
}

# The above awk command formats the scan results into tabbed columns
# $1 through $6 are:
# RF, Strnght, Quality, Symbol, Virtual, Name
# $7 through $16 print up to 5 subchannels found

# Count the number of channels found from the $ScanResults variable
#
ChansFound () {
NumChannels=`wc -l <<< "$ScanResults"`
}

# Start doing some work
# 1) Print the "Beginning scan" header
# 2) Run the RunScan function
# 3) Run the ChansFound function
# 4) Display the number of channels found
#
echo "Beginning scan on $ScanDev, tuner $ScanTuner at `date '+%D %T'`"
RunScan
ChansFound
echo ""
echo "${NumChannels// }" channels found
echo -e 'RF\tStrnght\tQuality\tSymbol\tVirtual\tName\t\tVirt#2\tName'
echo "------------------------------------------------------------------------"

# 5) Check to see if the -csv option was used on the command line
# If so, then CSV format the $ScanResults output
# 
if [ "$1" = "-csv" ]
then
        echo "$ScanResults" | sed $'s/\\\t/,/g'
else
        echo "$ScanResults"
fi
