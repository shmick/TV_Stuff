#!/bin/bash
#set -x 
######################################################################################
#
# channel_report.sh 
# v2014.06.14.r1
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

FindUniqueChans () {
awk -F, '{OFS="\t" ; print $2,$6,$7}' $DataFile | sort -n | uniq
}

GetChannelNames () {
awk -F, '{print $7}' $DataFile | sort -n | uniq
}

OutputWideData () {
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
        results=$(FindUniqueChans)
	ResultsCount 
}

ChanReport () {
	for i in $(GetChannelNames)
	do
	WideHeader
	grep $i $DataFile | OutputWideData
	done
}

FirstSeen () {
        results=$(
	for i in $(GetChannelNames)
	do
	grep -m 1 $i $DataFile | OutputWideData
	done)
	ResultsCount
	}

LastSeen () {
        results=$(
	for i in $(GetChannelNames)
	do
	tac $DataFile | grep -m 1 $i | OutputWideData
	done)
	ResultsCount
	}

BriefChanReport () {
	for i in $(GetChannelNames)
	do
	WideHeader
	grep $i $DataFile | OutputWideData | tail -12
	done
}

SearchReport () {
	WideHeader
	results=$(grep -F "$Arg2" $DataFile | OutputWideData)
	ResultsCount
}

Last () {
	WideHeader
        results=$(
	Latest=$(tail -1 $DataFile | awk -F, '{print $1}')
	tail -50 $DataFile | grep -F "$Latest" | sort -n -t, -k2,2 | OutputWideData )
	ResultsCount
}

ListAllData () {
	WideHeader
	OutputWideData $DataFile
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
'firstseen')
WideHeader
FirstSeen
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
