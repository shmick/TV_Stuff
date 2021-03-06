#!/bin/bash
#set -x
######################################################################################
#
# channel_scan.sh
# v2020.07.04.r1
#
# This script will scan a HDHomeRun for ATSC channels and print a formatted list
#
# Use the -h option for additional runtime options
#
# A note about deciphering the results here:
# http://www.silicondust.com/forum2/viewtopic.php?t=4474
#
# Twitter:// @shmick
# BitCoin:// 1BFSzGSSU5LazfYv8rYYxzT3M3GRf9EPov
######################################################################################

#Specify the full path to your hdhomerun_config binary if it's not found
HDHRConfig=""

###############################################
# There are no options to set below this line #
###############################################

DetectOS() {
	if [ -z "$HDHRConfig" ]; then
		case "$OSTYPE" in
		darwin*)
			HDHRConfig="$(which hdhomerun_config)"
			;;
		linux*)
			HDHRConfig="$(which hdhomerun_config)"
			;;
		esac
	fi

	if [ ! -x "$HDHRConfig" ]; then
		echo -e "\nUnable to locate the hdhomerun_config utility, please edit the HDHRConfig variable in this script"
		echo -e "\nIf it's not installed, download it from here: http://www.silicondust.com/support/hdhomerun/downloads\n"
		exit
	fi
}

DisplayHelp() {
	echo -e "\nUsage: $(basename $0) [option]"
	echo -e "\nOptions are:\n"
	echo "-d <device>	// Provide a device ID or IP instead of using auto discovery"
	echo "-t <tuner>	// Provide a tuner ID instead of using auto discovery"
	echo "-c 		// Output scan results in CSV format"
	echo "-l <filename>	// Log the output to <filename>"
	echo "-b 		// Brief mode. No dB info or secondary channels"
	echo "-D 		// Debug mode. To extrapolate SS values > 100%"
	echo "-A 		// Debug mode. To extrapolate SS values > 100% on all channels"
	echo "-n 		// Do not scan, only report devices and tuners available"
	echo -e "-h 		// This help info\n"
	exit
}

ReportLockStatus() {
	echo ""
	for Unit in $Devices; do
		for Tuner in 0 1; do
			echo -n "Lock status for Device $Unit Tuner $Tuner: "
			echo "$($HDHRConfig $Unit get /tuner$Tuner/lockkey)"
		done
	done
}

NoScan() {
	DiscoverDevices
	CheckTunerLockStatus
	ReportLockStatus
	echo -e "\nSelecting Device $ScanDev Tuner $ScanTuner\n"
	exit
}

CheckOpts() {
	local OPTIND
	while getopts ":hnd:t:l:cbDA" OPTIONS; do
		case "$OPTIONS" in
		h)
			DisplayHelp
			;;
		n)
			NoScan
			;;
		d)
			Devices=$OPTARG
			if [ "$(echo ${#Devices})" != "8" ]; then
				valid_ip ${Devices}
				if [ "$?" != "0" ]; then
					NoDevID
					exit 1
				fi
			fi
			;;
		t)
			ScanTuner=$OPTARG
			if [ "$ScanTuner" -ge "2" ]; then
				echo -e "\nTuner ID must be 0 or 1"
				DisplayHelp
			fi
			;;
		l)
			DataLog=$OPTARG
			;;
		c)
			CSV="y"
			;;
		b)
			BRIEF="y"
			;;
		D)
			DEBUG="y"
			LOCKKEY="12121212"
			OUTFILTER="seq 100"
			;;
		A)
			DEBUG="y"
			LOCKKEY="12121212"
			OUTFILTER="."
			;;
		:)
			echo -e "\nOption -$OPTARG requires an argument."
			DisplayHelp
			;;
		esac
	done
}

NoDevID() {
	echo "You must specify a proper device ID"
}

# From https://www.linuxjournal.com/content/validating-ip-address-bash-script
valid_ip() {
	local ip=$1
	local stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && \
		${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

DiscoverDevices() {
	# Attempt to discover HDHR devices on the LAN
	# Not used if you specify a device ID with the -d flag

	if [ -z "$Devices" ]; then
		Devices=$($HDHRConfig discover | sort -nr | awk '/^hdhomerun device/ {print $3}')
	fi

	# Exit if no device are found
	if [ "$Devices" = "found" ]; then
		echo "No HDHomeRun units detected, exiting"
		exit
	fi
}

CheckTunerLockStatus() {
	for Unit in $Devices; do
		if [ -n "$ScanTuner" ]; then # If a tuner was specified on the command line
			# with the -t option, use that, otherwise try
			# tuner 0 and 1
			TryTuners=$ScanTuner
		else
			TryTuners="0 1"
		fi
		for Tuner in $TryTuners; do
			if [ $($HDHRConfig $Unit get /tuner$Tuner/lockkey) = "none" ]; then
				ScanDev=$Unit
				ScanTuner=$Tuner
				break
			fi
		done
		if [ -n "$ScanDev" ]; then
			break
		fi
	done

	if [ -z "$ScanDev" ]; then
		echo -e "\nSorry, all tuners are in use right now. Try again later.\n"
		exit
	fi
}

GetScanData() {
	# GetScanData : Run a scan, parse the output and
	# store the results in $ScanResults

	echo -e "\nBeginning scan on $ScanDev, tuner $ScanTuner at $(date '+%D %T')\n"
	ScanResults=$($HDHRConfig $ScanDev scan $ScanTuner |
		tr -s "\n()=:" " " |
		sed 's/SCANNING/\'$'\n/g' |
		grep "seq 100")

	NumChannels=$(wc -l <<<"$ScanResults")
	echo "$NumChannels channels found"
}

GetDebugData() {
	# GetDebugData : Tune each channel, and grab stats using debug mode so we can extrapolate strong signals above SS = 100%
	# parse the output and plotting 'dbg = xxx' (X axis)  vs SS, dBmV (Y axis) in excel within the usable 0-100 SS range
	# yields a linear relationship
	# My tuner (HDHR3-US) worked out to having a slope = 0.139874758, round to .14. and an intercept = 58.7553810994, round to 58.8
	# HDHR4 looks to be: slope = .00991, intercept = 45.3

	echo -e "\nBeginning scan on $ScanDev, tuner $ScanTuner at $(date '+%D %T')\n"
	echo -e "Locking $ScanDev, tuner $ScanTuner with key $LOCKKEY\n"
	$HDHRConfig $ScanDev set /tuner$ScanTuner/lockkey $LOCKKEY
	ScanResults=$(for CHANNEL in {2..51}; do
		$HDHRConfig $ScanDev key $LOCKKEY set /tuner$ScanTuner/channel auto:$CHANNEL
		sleep 1
		RESULTS=$($HDHRConfig $ScanDev get /tuner$ScanTuner/debug |
			grep "tun" |
			tr "/()=:" " " |
			sed 's/none/none none/g' |
			grep "$OUTFILTER")
		echo $RESULTS
	done)
	echo -e "Unocking $ScanDev, tuner $ScanTuner with key $LOCKKEY\n"
	$HDHRConfig $ScanDev key $LOCKKEY set /tuner$ScanTuner/lockkey none
	if [ "$OUTFILTER" != "." ]; then
		ScanResults=$(echo "$ScanResults" | grep ^tun)
	fi
	NumChannels=$(wc -l <<<"$ScanResults")
	echo "$NumChannels channels found"
}

LogOutput() {
	# LogOutput : Re-parse the $ScanResults data and
	# append it to $DataLog

	timestamp=$(date "+%Y-%m-%d %H:%M")
	awk -v ts="$timestamp" '{OFS="," ; print ts,$3,$7 \
	,($7 * 60 / 100 -60) \
	,($7 * 60 / 100 -60 -48.75) \
	,$9,$11,$16,$17}' \
		<<<"$ScanResults" |
		sort -n >>$DataLog
}

BriefOutput() {
	# No dBmV, dBm or secondary channel info

	echo -e "RF\tStrngth\tQuality\tSymbol\tVirt #\tName"
	printf '%.0s-' {1..49}
	echo
	awk -v OFS='\t' '{print $3,$7,$9,$11,$16,$17}' \
		<<<"$ScanResults" |
		sort -n
}

StdOutput() {
	# StdOutput : This is the standard output when no options are used

	echo -e "RF\tStrngth\tdBmV\tdBm\tQuality\tSymbol\tVirt#1\tName \
	\tVirt#2\tName\t\tVirt#3\tName\t\tVirt#4\tName\t\tVirt#5\tName"
	printf '%.0s-' {1..72}
	echo
	awk -v OFS='\t' '{print $3,$7 \
	,($7 * 60 / 100 - 60) \
	,($7 * 60 / 100 -60 -48.75) \
	,$9,$11,$16,$17,"\t"$20,$21,"\t"$24,$25,"\t"$28,$29,"\t"$32,$33,"\t"$36,$37}' \
		<<<"$ScanResults" |
		sort -n
}

CSVOutput() {
	# CSVOutput : Same as standard output, but in CSV format

	awk -v OFS=',' '{print $3,$7 \
	,($7 * 60 / 100 - 60) \
	,($7 * 60 / 100 -60 -48.75) \
	,$9,$11,$16,$17,"\t"$20,$21,"\t"$24,$25,"\t"$28,$29,"\t"$32,$33,"\t"$36,$37}' \
		<<<"$ScanResults" |
		sort -n
}

DebugOutput() {
	# DebugOutput : Used when selecting debug mode
	# If the dbg= value is less than 5 characters, it uses the calc .14 * $15 + 58.8
	# If the dbg= value is 5 characters, it's a newer HDHR4 or HDTC unit and uses
	# the calc .00991 * $15 + 45.3

	echo -e "RF\tStrngth\tdBmV\tdBm\tQuality\tSNR\tSymbol\tdbg\tCalc_dBmV\tCalc_dBm"
	printf '%.0s-' {1..92}
	echo
	awk -v OFS='\t' \
		'{ \
	if (length($15) < 5) \
	{ printf "%u\t%u\t%3.1f\t%3.1f\t%u\t%2.1f\t%u\t%s\t%2.1f\t\t%2.1f\n", $4,$9 \
	,($9 * 60 / 100 - 60) \
	,($9 * 60 / 100 -60 -48.75) \
	,$11,($11 / 100 * 33),$13,$15,(.14 * $15 + 58.8),"\t"(.14 * $15 + 58.8 - 48.75) } \
	else
	{ printf "%u\t%u\t%3.1f\t%3.1f\t%u\t%2.1f\t%u\t%s\t%2.1f\t\t%2.1f\n", $4,$9 \
	,($9 * 60 / 100 - 60) \
	,($9 * 60 / 100 -60 -48.75) \
	,$11,($11 / 100 * 33),$13,$15,(.00991 * $15 + 45.3),"\t"(.00991 * $15 + 45.3 - 48.75) } \
	}' \
		<<<"$ScanResults" |
		sort -n
}

ScanType() {
	if [ -n "$DEBUG" ]; then
		echo "debug mode"
		GetDebugData
	else
		GetScanData
	fi
}

FinalOutput() {
	if [ -n "$DEBUG" ]; then
		DebugOutput
	elif [ -n "$DataLog" ]; then
		LogOutput
	elif [ -n "$CSV" ]; then
		CSVOutput
	elif [ -n "$BRIEF" ]; then
		BriefOutput
	else
		StdOutput
	fi
}

# Calls the above functions in the correct order
DetectOS
CheckOpts "$@"
DiscoverDevices
CheckTunerLockStatus
ScanType
FinalOutput
