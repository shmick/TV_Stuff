TV Stuff
========
Scripts and other misc data for my TV setup.

channel_scan.sh - A utility to scan for ATSC channels on HDHomeRun ATSC devices ie: HDHR3 / HDHDR Dual / HDHR Plus

###### Useage: 'channel_scan.sh --help' will display available options

If no options are given, a full channel scan will be performed on the first available tuner found.

The scan output will look like this:

![Alt text](/../screenshots/screenshots/scan-ouput.png?raw=true)

channel_report.sh - Generate reports from the output of the datalog file created by channel_scan.sh

###### Useage: 'channel_report.sh --help' will display available options

Other software and hardware in use:

[Apple Mac Mini](http://www.apple.com/ca/mac-mini/)

[Silicon Dust HDHomeRun tuners](http://www.silicondust.com/products_new/)

[Elgato EyeTV](http://www.elgato.com/eyetv/eyetv-3)

[Remote Buddy](http://www.iospirit.com/products/remotebuddy/)


Licensing: This is distributed unider the Creative Commons 3.0 Non-commecrial, Attribution, Share-Alike license. You can use the code for noncommercial purposes. You may NOT sell it. If you do use it, then you must make an attribution to me (i.e. Include my name and thank me for the hours I spent on this)


```
Beginning scan on 10396549, tuner 0 at 06/08/14 13:42:20

18 channels found
RF		Strnght	Quality	Symbol	Virtual	Name		Virt#2	Name
------------------------------------------------------------------------
9		87		89		100	9.1	CFTO						
14		59		71		100	29.1	WUTV-HD		29.2	TCN								
15		54		54		100	11.1	CHCH-DT											
19		83		82		100	19.1	TVO											
20		83		80		100	5.1	CBLT-DT											
25		94		92		100	25.1	CBLFTDT											
32		93		89		100	23.1	WNLO-HD		23.2	Bounce								
33		64		83		100	2.1	WGRZ-HD		2.2	WGRZ-WN		2.3	WGRZ-AT					
36		63		64		100	36.1	CITS-HD											
38		57		68		100	7.1	WKBW-HD											
39		69		73		100	4.1	WIVB-HD											
40		87		95		100	40.1	CJMT											
41		100		86		100	41.1	CIII-HD		41.2	CIII-SD								
43		79		91		100	17.1	WNED-HD		17.2	Think		0						
44		89		93		100	57.1	CITYTV											
45		40		49		100	8.1	WROC-HD		8.2	Bounce								
47		87		89		100	47.1	CFMT											
49		68		84		100	49.1	WNYO-HD											
```
