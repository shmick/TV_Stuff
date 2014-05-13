#!/bin/bash
#set -x 
######################################################################################
#
# channel_scan.sh 
# v2014.05.13.r1
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

HDHRConfig=""

MACOS="/usr/bin/hdhomerun_config"
LINUX="/usr/local/bin/hdhomerun_config"

Arg1=$1
Arg2=$2

if [ -x "$MACOS" ]
then
HDHRConfig="$MACOS"
elif [ -x "$LINUX" ]
then
HDHRConfig="$LINUX"
elif [ ! -x "$HDHRConfig" ]
then
echo ""
echo "Unable to locate the hdhomerun_config utility, please edit the HDHRConfig variable in this script"
echo ""
echo "If it's not installed, download it from here: http://www.silicondust.com/support/hdhomerun/downloads"
echo ""
exit
fi

if [[ "$Arg1" = "-datalog" && "$Arg2" = "" ]]
then
echo ""
echo "You must specify a file ie: $0 $1 /path/to/datalog.txt"
echo ""
exit
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
echo ""
echo "Device $ScanDev selected with tuner $ScanTuner"
echo ""
exit
fi
}

# Perform a tuner scan, outputting the results to $ScanResults
#
FullScan () {

	echo ""
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
		    | awk -v OFS='\t' '{print $1,$2,$3,$4,$5,$6,"\t"$7,$8,"\t"$9,$10,"\t"$11,$12,"\t"$13,$14,"\t"$15,$16}' \
		    | sort -n`
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
	echo "$ScanResults" | awk -v ts="$timestamp" '{OFS="\t" ; print ts,$1,$2,$3,$4,$5,$6}' | sed $'s/\\\t/,/g' >> $Arg2
else
	echo -e 'RF\tStrnght\tQuality\tSymbol\tVirtual\tName\t\tVirt#2\tName'
	printf '%.0s-' {1..72}; echo
	echo "$ScanResults"
fi
