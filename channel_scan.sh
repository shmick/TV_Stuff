#!/bin/bash
#set -x 
######################################################################################
#
# channel_scan.sh 
# v2015.04.06.r1
#
# This script will scan a HDHomeRun for ATSC channels and print a formatted list
#
# Use the -help option for additional runtime options
#
# A note about deciphering the results here:
# http://www.silicondust.com/forum2/viewtopic.php?t=4474
#
# Twitter:// @shmick
#
######################################################################################

#Specify the full path to your hdhomerun_config binary if it's not found
HDHRConfig=""

###############################################
# There are no options to set below this line #
###############################################

DetectOS () {
MACOS="/usr/bin/hdhomerun_config"
LINUX="/usr/local/bin/hdhomerun_config"

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
}

DisplayHelp () {
	echo ""
	echo "Usage: $(basename $0) [option]"
	echo ""
	echo "Options are:"
	echo ""
	echo "-d <device id> (Provide a device ID instead of using auto discovery)"
	echo "-t <tuner id> (Provide a tuner ID instead of using auto discovery)"
	echo "-c Output scan results in CSV format"
	echo "-l <filename> Log the output to <filename>"
	echo "-n Report only what device and tuner would be used without running a scan"
	echo "-h This help info"
	echo ""
	exit
}

ReportLockStatus () {
	echo ""
	for Unit in $Devices
	do
	for Tuner in 0 1
	do 
	echo -n "Lock status for Device $Unit Tuner $Tuner: "
	echo "$($HDHRConfig $Unit get /tuner$Tuner/lockkey)"
	done
	done
}

CheckOpts () {
local OPTIND
while getopts ":hnd:t:l:c" OPTIONS
do
	case "$OPTIONS" in
	h) DisplayHelp exit ;;
	n)
	DiscoverDevices
	CheckTunerLockStatus
	ReportLockStatus
	echo ""
	echo "Selecting Device $ScanDev Tuner $ScanTuner"
	echo ""
	exit
	;;
	d)
	Devices=$OPTARG
	if [ "$(echo ${#Devices})" != "8" ]
	then
	NoDevID
	exit 1
	fi
	;;
	t) 
	ScanTuner=$OPTARG 
	;;
	l)
	DataLog=$OPTARG
	;;
	c)
	CSV="y"
	;;
	:)
	echo "Option -$OPTARG requires an argument." >&2
	DisplayHelp
	exit 1
	;;
	esac
done
}

NoDevID () {
	echo "You must specify a proper device ID"
}

DiscoverDevices () {
# Attempt to discover HDHR devices on the LAN
#
	if [ -z "$Devices" ]
	then
	Devices=$($HDHRConfig discover | sort -nr | awk '/^hdhomerun device/ {print $3}')
	fi


# Exit if no device are found
#
	if [ "$Devices" = "found" ]
	then
	echo "No HDHomeRun units detected, exiting"
	exit
	fi
}

CheckTunerLockStatus () {
	if [ -z "$ScanTuner" ]
	then
		for Unit in $Devices
		do
			for Tuner in 0 1
				do 
				if [ $($HDHRConfig $Unit get /tuner$Tuner/lockkey) = "none" ]
				then
				ScanDev=$Unit
				ScanTuner=$Tuner
				break
				fi
				done
			if [ -n "$ScanDev" ]
			then
			break
			fi 
		done

		if [ -z "$ScanDev" ]
		then
		echo ""
		echo "Sorry, all tuners are in use right now. Try again later."
		echo ""
		exit
		fi
	else
	ScanDev=$Devices
	fi
}

GetScanData () {
# GetScanData : Run a scan, parse the output and
# store the results in $ScanTuner

	echo ""
	echo "Beginning scan on $ScanDev, tuner $ScanTuner at $(date '+%D %T')"
	echo ""
	ScanResults=$($HDHRConfig $ScanDev scan $ScanTuner \
	| tr -s "\n()=:" " " \
	| sed 's/SCANNING/\'$'\n/g' \
	| grep "seq 100" )

	NumChannels=$(wc -l <<< "$ScanResults")
#echo "${NumChannels// }" channels found
	echo "$NumChannels channels found"
}

LogOutput () {
# LogOutput : Re-parse the $ScanResults data and
# append it to $DataLog

	timestamp=$(date "+%Y-%m-%d %H:%M")
	awk -v ts="$timestamp" '{OFS="," ; print ts,$3,$7,($7 * 60 / 100 -60),($7 * 60 / 100 -60 -48.75),$9,$11,$16,$17}' \
	<<< "$ScanResults" \
	| sort -n >> $DataLog
}

StdOutput () {
# StdOutput : This is the standard output when no options are used

	echo -e 'RF\tStrngth\tdBmV\tdBm\tQuality\tSymbol\tVirt#1\tName\t\tVirt#2\tName\t\tVirt#3\tName\t\tVirt#4\tName\t\tVirt#5\tName'
	printf '%.0s-' {1..72}; echo
	awk -v OFS='\t' '{print $3,$7,($7 * 60 / 100 - 60),($7 * 60 / 100 -60 -48.75),$9,$11,$16,$17,"\t"$20,$21,"\t"$24,$25,"\t"$28,$29,"\t"$32,$33,"\t"$36,$37}' \
	<<< "$ScanResults" \
	| sort -n
}

CSVOutput () {
# CSVOutput : Same as standard output, but in CSV format
	awk -v OFS=',' '{print $3,$7,($7 * 60 / 100 - 60),($7 * 60 / 100 -60 -48.75),$9,$11,$16,$17,"\t"$20,$21,"\t"$24,$25,"\t"$28,$29,"\t"$32,$33,"\t"$36,$37}' \
	<<< "$ScanResults" \
	| sort -n
}

FinalOutput () {
if [ -n "$LogOutput" ]
then
LogOutput
elif [ -n "$CSV" ]
then
CSVOutput
else
StdOutput
fi
}

# Calls the above functions in the correct order 
DetectOS
CheckOpts "$@"
DiscoverDevices
CheckTunerLockStatus
GetScanData
FinalOutput
