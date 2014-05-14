#!/bin/bash
#set -x 
######################################################################################
#
# channel_scan.sh 
# v2014.05.14.r1
#
# This script will scan a HDHomeRun for ATSC channels and print a formatted list
#
# Use the --help option for additional runtime options
#
# A note about deciphering the results here:
# http://www.silicondust.com/forum2/viewtopic.php?t=4474
#
# Twitter:// @shmick
#
######################################################################################

#Specify the full path to your hdhomerun_config binary if it's not found
HDHRConfig=""

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

if [ "$1" = "--help" ]
then
echo ""
echo "Usage: $0 [option]"
echo ""
echo "Options are:"
echo ""
echo "-devid ID : Provide a device ID instead of using auto discovery"
echo "-datalog /path/to/filename : Useful for scheduling scans and logging the data"
echo ""
echo "You may use both the -devid and -datalog options at the same time"
echo ""
echo "-noscan : Report only what device and tuner would be used without running a scan"
echo ""
exit
fi

Arg1=$1
Arg2=$2
Arg3=$3
Arg4=$4

# Exit if -datalog option is called but no file is specified
if [[ "$Arg1" = "-datalog" && "$Arg2" = "" ]] ||  [[ "$Arg3" = "-datalog" && "$Arg4" = "" ]]
then
echo ""
echo "You must specify a datalog file ie: $0 -datalog datalogfile"
echo ""
exit
fi

# Override the auto detect function by specifying a device ID
# with the -devid option
if [[ "$Arg1" = "-devid" && "$Arg2" = "" ]] || [[ "$Arg3" = "-devid" && "$Arg4" = "" ]]
then
echo ""
echo "You must specify a device ID"
echo ""
exit
elif [ "$Arg1" = "-devid" ]
then
Devices="$Arg2"
elif [ "$Arg3" = "-devid" ]
then
Devices="$Arg4"
else
Devices=""
fi

DiscoverDevices () {
# Attempt to discover HDHR devices on the LAN
#
if [ "$Devices" = "" ]
then
Devices=$($HDHRConfig discover | awk '{print $3}')
fi

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
		if [ $($HDHRConfig $Unit get /tuner$Tuner/lockkey) = "none" ]
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

ReportLockStatus () {
	for Unit in $Devices
	do
		for Tuner in 0 1
		do 
		echo -n "Lock status for Device $Unit Tuner $Tuner: "
		echo "$($HDHRConfig $Unit get /tuner$Tuner/lockkey)"
		done
	done
}


CheckNoScan () {
if [ "$Arg1" = "-noscan" ]
echo ""
ReportLockStatus
then
echo ""
echo "Selecting Device $ScanDev Tuner $ScanTuner"
echo ""
exit
fi
}


# Perform a tuner scan, outputting the results to $ScanResults
#
FullScan () {

	echo ""
	echo "Beginning scan on $ScanDev, tuner $ScanTuner at $(date '+%D %T')"
	echo ""
	ScanResults=$($HDHRConfig $ScanDev scan $ScanTuner \
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
		    | sort -n)
# $1 through $6 are:
# RF, Strnght, Quality, Symbol, Virtual, Name
# $7 through $16 print up to 5 subchannels found

        NumChannels=$(wc -l <<< "$ScanResults")
	echo "${NumChannels// }" channels found
}

DiscoverDevices
CheckTunerLockStatus
CheckNoScan
FullScan

LogOutput () {
	timestamp=$(date "+%Y-%m-%d %H:%M")
	echo "$ScanResults" | awk -v ts="$timestamp" '{OFS="\t" ; print ts,$1,$2,$3,$4,$5,$6}' | sed $'s/\\\t/,/g' >> $DataLog
	}

StdOutput () {
	echo -e 'RF\tStrnght\tQuality\tSymbol\tVirtual\tName\t\tVirt#2\tName'
	printf '%.0s-' {1..72}; echo
	echo "$ScanResults"
	}

# Options are -csv or datalog 
if [ "$1" = "-csv" ]
	then
	echo "$ScanResults" | sed $'s/\\\t/,/g'
elif [ "$Arg1" = "-datalog" ]
	then
	DataLog="$Arg2"
	LogOutput
elif [ "$Arg3" = "-datalog" ]
	then
	DataLog="$Arg4"
	LogOutput
else
	StdOutput
fi
