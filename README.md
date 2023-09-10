# apple1loader
A loader of Apple 1 software on ROM

Only type 1 (direct jump to assembly) and type 2 (copy to RAM and execute) are currently implemented.

In the 'dist' directory is the .bin file with the assembled loader + a text file dumpable in WozMon



make obj/silicrom.rom

~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp 

