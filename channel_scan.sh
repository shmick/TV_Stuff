#!/bin/bash
#set -x 
######################################################################################
#
# channel_scan.sh 
# v2014.06.14.r1
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
	echo "Usage: $(basename 0) [option]"
	echo ""
	echo "Options are:"
	echo ""
	echo "-devid 12349876 : Provide a device ID instead of using auto discovery"
	echo "-datalog /path/to/filename : Useful for scheduling scans and logging the data"
	echo ""
	echo "The -devid and -datalog options can be used at the same time"
	echo ""
	echo "-noscan : Report only what device and tuner would be used without running a scan"
	echo ""
	echo "-help : This help info"
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

CheckOptions () {
	case "$Arg1" in
		--help|-help|-h|help)
			DisplayHelp
		;;
		-datalog)
			if [ -z "$Arg2" ]
			then
			NoDatalog
			exit 1
			else
			DataLog="$Arg2"
			fi
		;;
		-devid)
			if [ -z "$Arg2" ]
			then
			NoDevID
			exit 1
			else
			Devices="$Arg2"
			fi
		;;
		-n|-noscan|noscan)
			DiscoverDevices
			CheckTunerLockStatus
			ReportLockStatus
			echo ""
			echo "Selecting Device $ScanDev Tuner $ScanTuner"
			echo ""
			exit
	esac

	case "$Arg2" in
		-datalog)
			NoDevID
			exit 1
		;;
		-devid)
			NoDatalog
			exit 1
	esac

	case "$Arg3" in
		-datalog)
			if [ -z "$Arg4" ]
			then
			NoDatalog
			exit 1
			else
			DataLog="$Arg4"
			fi
		;;
		-devid)
			if [ -z "$Arg4" ]
			then
			NoDevID
			exit 1
			else
			Devices="$Arg4"
			fi
	esac

	if [ -n "$Devices" ]
	then
		if [ "$(echo ${#Devices})" != "8" ]
		then
		NoDevID
		exit 1
		fi
	fi

}

NoDatalog () {
	echo "You must specify a datalog file ie: $(basename 0) -datalog datalogfile"
}

NoDevID () {
	echo "You must specify a device ID"
}

DiscoverDevices () {
# Attempt to discover HDHR devices on the LAN
#
	if [ -z "$Devices" ]
	then
	Devices=$($HDHRConfig discover | awk '{print $3}')
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
	awk -v ts="$timestamp" '{OFS="," ; print ts,$3,$7,$9,$11,$16,$17}' \
	<<< "$ScanResults" \
	| sort -n >> $DataLog
}

StdOutput () {
# StdOutput : This is the standard output when no options are used

	echo -e 'RF\tStrnght\tQuality\tSymbol\tVirtual\tName\t\tVirt#2\tName'
	printf '%.0s-' {1..72}; echo
	awk -v OFS='\t' '{print $3,$7,$9,$11,$16,$17,"\t"$20,$21,"\t"$24,$25,"\t"$28,$29,"\t"$32,$33,"\t"$36,$37}' \
	<<< "$ScanResults" \
	| sort -n
}

CSVOutput () {
# CSVOutput : Same as standard output, but in CSV format
	awk -v OFS=',' '{print $3,$7,$9,$11,$16,$17,$20,$21,$24,$25,$28,$29,$32,$33,$36,$37}' \
	<<< "$ScanResults" \
	| sort -n
}

FinalOutput () {
# FinalOutput : Output in CSV, save to a log file
# or use the standard output method

	case "$Arg3" in
		-datalog)
			LogOutput
			exit
	esac

	case "$Arg1" in
		-datalog)
			LogOutput
			exit
	;;
		-csv)
			CSVOutput
			exit 
	;;
		*)
			StdOutput
	esac
}

# Declare some global variables
Arg0=$0
Arg1=$1
Arg2=$2
Arg3=$3
Arg4=$4

# Calls the above functions in the correct order 
DetectOS
CheckOptions
DiscoverDevices
CheckTunerLockStatus
GetScanData
FinalOutput
