#!/bin/sh -e

# Build assembly sources

( cd src && make )

# Build the ROM

python makerom.py silicrom.json silicrom.rom

# ~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp 
