#!/bin/bash
#set -x 
######################################################################################
#
# channel_report.sh 
# v2014.05.30.r1
#
# This script will Format the output of the logged data from channel_scan.sh
# available from https://github.com/shmick/TV_Stuff
#
# Use the 'chans' option to generate a list of unique channels found
# Use the 'chanreport' option to output the list sorted by channel
# Use the 'briefchanreport' option to output the list sorted by channel, limited to 12 entries per channel
# or provide a search term ie: date timestamp or channel name
#
# Twitter:// @shmick
#
######################################################################################

Help () {
echo ""
echo "Options are:"
echo ""
echo "last : Display results of the last scan"
echo "chans : Display a list of all channels in the datalog"
echo "chanreport : Display all stats, sorted by channel"
echo "briefchanreport : Similar to chanreport, limited to last 12 results per channel"
echo "lastseen : Display the most recent result of each channel in the datalog"
echo "[search term] : Provide a search term ie: TVO"
echo ""
Usage
}

Usage () {
echo "Usage: $(basename $0) datafile [option]"
echo ""
echo "Use -help for a list of options"
echo ""
exit 1
}

case "$1" in
--help|-help|-h|help)
Help
;;
*)
if [ ! -f "$1" ]
then
Usage
else
DataFile="$1"
fi
esac

Arg2="$2"

case "$3" in
.)
Arg3="."
;;
*)
Arg3="$3"
esac

AWKCMD1 () {
awk -F, '{OFS="\t" ; print $2,$6,$7}' $DataFile | sort -n | uniq
}

AWKCMD2 () {
awk -F, '{print $7}' $DataFile | sort -n | uniq
}

AWKCMD3 () {
awk -F, '{OFS="\t" ; print $1,$2,$3,$4,$5,$6,$7}' $1
}

ResultsCount () {
sort -n -k3 <<< "$results" | grep "$Arg3"
found=$(sort -n -k3 <<< "$results" | grep "$Arg3" | wc -l)
echo ""
echo "$found channels found"
echo ""
}

WideHeader () {
	echo ""
	echo -e 'Timestamp\t\tRF\tStrnght\tQuality\tSymbol\tVirtual\tName'
	printf '%.0s-' {1..72}; echo
}

BriefHeader () {
	echo -e 'RF\tVirtual\tName'
	printf '%.0s-' {1..26}; echo
}

Chans () {
	BriefHeader
        results=$(
	AWKCMD1 )
	ResultsCount 
}

ChanReport () {
	for i in $(AWKCMD2)
	do
	WideHeader
	grep $i $DataFile | AWKCMD3
	done
}

LastSeen () {
        results=$(
	for i in $(AWKCMD2)
	do
	grep $i $DataFile | AWKCMD3 | tail -1
	done)
	ResultsCount
	}


BriefChanReport () {
	for i in $(AWKCMD2)
	do
	WideHeader
	grep $i $DataFile | AWKCMD3 | tail -12
	done
}

SearchReport () {
	WideHeader
	results=$(
	grep -F "$Arg2" $DataFile | AWKCMD3 )
	ResultsCount
}

Last () {
	WideHeader
        results=$(
	Latest=$(tail -1 $DataFile | awk -F, '{print $1}')
	tail -50 $DataFile | grep -F "$Latest" | sort -n -t, -k2,2 | AWKCMD3 )
	ResultsCount
}

ListAllData () {
	WideHeader
	AWKCMD3 $DataFile
}

case "$2" in
'chans')
Chans
;;
'last')
Last
;;
'lastseen')
WideHeader
LastSeen
;;
'chanreport')
ChanReport
;;
'briefchanreport')
BriefChanReport
;;
--help|-help|-h|help)
Help
;;
*)
SearchReport
esac
