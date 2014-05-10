#!/bin/bash
#set -x 
######################################################################################
#
# channel_report.sh 
# v2014.05.10.r2
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

if [ "$1" = "" ]
then
echo "Usage: channel_report.sh datafile ( chans | chanreport | briefchanreport | [search term] )"
exit
fi

DataFile="$1"
Arg2="$2"

WideHeader () {
echo ""
echo -e 'Timestamp\t\tRF\tStrnght\tQuality\tSymbol\tVirtual\tName'
echo "-----------------------------------------------------------------------"
}

BriefHeader () {
echo -e 'RF\tVirtual\tName'
echo "-------------------------"
}

UniqueChans () {
BriefHeader
awk -F, '{print $2"\t"$6"\t"$7}' $DataFile | sort -n | uniq
}

ChanReport () {
for i in `awk -F, '{print $7}' $DataFile | sort -n | uniq`
do
WideHeader
grep $i $DataFile | awk -F, '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}'
done
}

BriefChanReport () {
for i in `awk -F, '{print $7}' $DataFile | sort -n | uniq`
do
WideHeader
grep $i $DataFile | awk -F, '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}' | tail -12
done
}

SearchReport () {
WideHeader
grep -F "$Arg2" $DataFile | awk -F, '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}'
}

ListAllData () {
WideHeader
awk -F, '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}' $DataFile
}

if [ "$2" = "" ]
then
ListAllData
elif [ "$2" = "chans" ]
then
UniqueChans
elif [ "$2" = "chanreport" ]
then
ChanReport
elif [ "$2" = "briefchanreport" ]
then
BriefChanReport
else
SearchReport
fi
