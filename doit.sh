#!/bin/sh

make obj/loader.o65
cp obj/loader.o65 dist/loader.bin
make fred.rom
~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp 
