# apple1loader

A loader of Apple 1 software on ROM

type 1 = direct jump to assembly
type 2 = copy to RAM and execute
type 3 = Basic software


DO NOT TRUST THE MAKEFILE -- USE IT TO KNOW WHAT COMMAND TO MANUALLY LAUNCH

Most stuff after is obsolete.

In the 'dist' directory is the .bin file with the assembled loader + a text file dumpable in WozMon



make obj/silicrom.rom

~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp 


grep /usr/local/share/minipro/infoic.xml