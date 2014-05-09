#!/bin/bash
#set -x 
######################################################################################
#
# channel_report.sh 
# v2014.05.09.r1
#
# This script will Format the output of the logged data from channel_scan.sh
# available from https://github.com/shmick/TV_Stuff
#
# Use the 'chans' option to generate a list of unique channels found
# or provide a search term ie: date timestamp or channel name
#
# Twitter:// @shmick
#
######################################################################################

if [ "$1" = "" ]
then
echo "Usage: channel_report.sh datafile (chans | [search term])"
exit
fi

if [ "$2" != "chans" ]
then
echo -e 'Timestamp\tRF\tStrnght\tQuality\tSymbol\tVirtual\tName'
echo "---------------------------------------------------------------"
fi

if [ "$2" = "chans" ]
then
echo -e 'RF\tVirtual\tName'
echo "-------------------------"
awk -F, '{print $2"\t"$6"\t"$7}' $1 | sort -n | uniq
elif [ "$2" = "" ]
then
cat $1 | awk -F, '{print  $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}'
else
grep -F "$2" $1 | awk -F, '{print  $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}'
