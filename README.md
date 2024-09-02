# apple1loader

A loader of Apple 1 software on ROM

type 1 = direct jump to assembly
type 2 = copy to RAM and execute
type 3 = Basic software


DO NOT TRUST THE MAKEFILE -- USE IT TO KNOW WHAT COMMAND TO MANUALLY LAUNCH

Most stuff after is obsolete.

In the 'dist' directory is the .bin file with the assembled loader + a text file dumpable in WozMon



<!-- make obj/silicrom.rom -->



grep /usr/local/share/minipro/infoic.xml



The loader (loader.asm) is the program that displays and manages the menu

It is built by:

make obj/loader.o65
cp obj/loader.o65 dist/loader.bin

The rom is created with the makerom.py script, that takes a json file and creates the corresponding rom:

make fred.rom

A snapshot named 'a.snp' will be placed next to the rom


~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp 
