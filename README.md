TV Stuff
========
Scripts and other misc data for my TV setup.

[channel_scan.sh](channel_scan.sh) - A utility to scan for ATSC channels on HDHomeRun ATSC devices ie: HDHR3 / HDHDR Dual / HDHR Plus/Extend

Also available as a self contained Docker container [here](https://github.com/shmick/hdhomerun-scan)

###### Usage: 'channel_scan.sh -h' will display available options

If no options are given, a full channel scan will be performed on the first available tuner found.

The scan output will look like this:

```
$ ./channel_scan.sh

Beginning scan on 87654321, tuner 0 at 12/31/13 09:00:00

18 channels found
RF		Strngth	dBmV	dBm			Quality	Symbol	Virt#1	Name 		Virt#2	Name		Virt#3	Name		Virt#4	Name		Virt#5	Name
------------------------------------------------------------------------
9		100		0		-48.75		98		100		9.1		CFTO															
14		93		-4.2	-52.95		90		100		29.1	WUTV-HD		29.2	TCN			29.3	GritTV									
15		83		-10.2	-58.95		46		100		11.1	CHCH-DT															
19		100		0		-48.75		85		100		19.1	TVO															
20		100		0		-48.75		85		100		5.1		CBLT-DT															
23		73		-16.2	-64.95		56		100		51.1	ION			51.2	qubo		51.3	IONLife		51.4	Shop		51.5	QVC		51.6	HSN
25		100		0		-48.75		100		100		25.1	CBLFTDT															
32		100		0		-48.75		100		100		23.1	WNLO-HD		23.2	Bounce												
33		100		0		-48.75		85		100		2.1		WGRZ-HD		2.2		WGRZ2.2		2.3		WGRZ2.3									
36		100		0		-48.75		78		100		36.1	CITS-HD															
38		100		0		-48.75		100		100		7.1		WKBW-HD															
39		100		0		-48.75		98		100		4.1		WIVB-HD															
40		100		0		-48.75		100		100		40.1	CJMT															
41		100		0		-48.75		100		100		41.1	CIII-HD		41.2	CIII-SD												
43		100		0		-48.75		100		100		17.1	WNED-HD		17.2	Think		0										
44		100		0		-48.75		100		100		57.1	CITYTV															
47		100		0		-48.75		98		100		47.1	CFMT															
49		100		0		-48.75		98		100		49.1	WNYO-HD		49.2	GetTV												
```

[channel_report.sh](channel_report.sh) - Generate reports from the output of the datalog file created by [channel_scan.sh](channel_scan.sh)

###### Usage: 'channel_report.sh -h' will display available options

Other software and hardware in use
-----------------------------------

* [Apple Mac Mini](https://www.apple.com/ca/mac-mini/)

* [Plex](https://www.plex.tv/)

* [Remote Buddy](https://www.iospirit.com/products/remotebuddy/)

* [Silicon Dust HDHomeRun tuners](https://www.silicondust.com/#)

~~* [EyeTV](http://www.elgato.com/eyetv/eyetv-3)~~ (replaced with Plex as the new owners of EyeTV, Geniatech, have decided to drop support for the HDHomeRun tuners) 

Licensing: This is distributed unider the Creative Commons 3.0 Non-commecrial, Attribution, Share-Alike license. You can use the code for noncommercial purposes. You may NOT sell it. If you do use it, then you must make an attribution to me (i.e. Include my name and thank me for the hours I spent on this)
