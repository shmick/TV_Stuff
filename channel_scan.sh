#!/bin/bash
#set -x 
######################################################################################
#
# channel_scan.sh 
# v2014.05.10.r2
#
# This script will scan a HDHomeRun for ATSC channels and print a formatted list
#
# Use the -csv option to print out CSV formatted results
# Use the -datalog option to append the results to the DATALOG file defined below
# Use the -noscan option to select a HDHR Unit and Tuner but not perform a scan
#
# A note about deciphering the results here:
# http://www.silicondust.com/forum2/viewtopic.php?t=4474
#
# Twitter:// @shmick
#
######################################################################################

# Set the path to the hdhomerun_config utility here
#
# Common locations:
#
# Mac: /usr/bin/hdhomerun_config 
# Linux: /usr/local/bin/hdhomerun_config
HDHRConfig=/usr/local/bin/hdhomerun_config

# Set the filename to log to when using the -datalog function
DATALOG=""

Arg1=$1

if [ ! -x $HDHRConfig ]
then
echo ""
echo "Unable to locate the hdhomerun_config utility, please edit the HDHRConfig variable in this script"
echo ""
echo "If it's not installed, download it from here: http://www.silicondust.com/support/hdhomerun/downloads"
echo ""
exit
fi

if [ "$1" = "-datalog" ]
then
	if [ "$DATALOG" = "" ]
	then
	echo "You must define the DATALOG variable in this script for this function to work"
	exit
	fi
fi

DiscoverDevices () {
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
}

CheckTunerLockStatus () {
	for Unit in $Devices
	do
		for Tuner in 0 1
		do 
		if [ $(eval $HDHRConfig $Unit get /tuner$Tuner/lockkey) = "none" ]
		then
		ScanDev=$Unit
		ScanTuner=$Tuner
		break
		fi
	done
	if [ "$ScanDev" != "" ]
	then
	break
	fi 
	done

	if [ "$ScanDev" = "" ]
	then
	echo ""
	echo "Sorry, all tuners are in use right now. Try again later."
	echo ""
	exit
	fi
}

CheckNoScan () {
	if [ "$Arg1" = "-noscan" ]
	then
	echo "Device $ScanDev selected with tuner $ScanTuner"
	exit
	fi
}

# Perform a tuner scan, outputting the results to $ScanResults
#
FullScan () {

	echo "Beginning scan on $ScanDev, tuner $ScanTuner at `date '+%D %T'`"
	echo ""
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
# $1 through $6 are:
# RF, Strnght, Quality, Symbol, Virtual, Name
# $7 through $16 print up to 5 subchannels found

        NumChannels=`wc -l <<< "$ScanResults"`
	echo "${NumChannels// }" channels found
}

DiscoverDevices
CheckTunerLockStatus
CheckNoScan
FullScan

# Options are -csv or datalog 
if [ "$1" = "-csv" ]
	then
	echo "$ScanResults" | sed $'s/\\\t/,/g'
elif [ "$1" = "-datalog" ]
	then
	timestamp=`date "+%Y-%m-%d %H:%M"`
	echo "$ScanResults" | awk -v ts="$timestamp" '{print ts"\t"$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' | sed $'s/\\\t/,/g' >> $DATALOG
else
	echo -e 'RF\tStrnght\tQuality\tSymbol\tVirtual\tName\t\tVirt#2\tName'
	echo "------------------------------------------------------------------------"
	echo "$ScanResults"
fi
