# Makes the silicon rom


eeprom: silicrom.rom
	@echo "Copy of binary into a 27256/28256 via MiniPro"
	minipro -p D27256@DIP28 -w silicrom.rom

# eeprom: fred.rom
# 	@echo "Copy of binary into a 27256/28256 via MiniPro"
# 	# minipro -p X28C256 -w obj/silicrom.rom
# 	minipro -p D27256@DIP28 -w fred.rom

ROMS = src/CRC8

# obj/silicrom.rom: dist/loader.bin silicrom.json makerom.py $(ROMS)
# 	python 	makerom.py silicrom.json obj/silicrom.rom

# Runs in mame
run: obj/silicrom1.snp
	mame -debug apple1 -ui_active -resolution 640x480 -snapshot obj/silicrom1.snp

# Object file
obj/silicrom1.o65: silicrom1.asm software/BASIC.inc software/WOZMON.inc software/MEMORYTEST.inc software/APPLE30TH.inc software/LUNARLANDER.inc software/CODEBREAKER.REP.inc software/LITTLETOWER.inc software/TYPINGTUTOR.inc software/MICROCHESS2.inc software/PASART.inc software/CELLULAR.inc software/MASTERMIND.inc software/NIM.04AF.inc 
	mkdir -p obj
	xa -o obj/silicrom1.o65 silicrom1.asm

# Builds the mame snapshot
obj/silicrom1.snp: obj/silicrom1.o65
	( echo -e foo )
	( /bin/echo -en "LOAD:\x50\x00DATA:" ; cat obj/silicrom1.o65 ) > obj/silicrom1.snp



# Builds the binary file
obj/loader.o65: loader.asm
	mkdir -p obj
	xa -o obj/loader.o65 loader.asm

# Runs in mame
# run: obj/loader.snp
# 	mame -debug apple1 -ui_active -resolution 640x480 -snapshot obj/loader.snp

# Builds the mame snapshot
obj/loader.snp: obj/loader.o65
	( echo -e foo )
	( /bin/echo -en "LOAD:\x02\x80DATA:" ; cat obj/loader.o65 ) > obj/loader.snp

# Remove objects
clean:
	rm -rf obj

# distribution
dist: dist/loader.bin

dist/loader.bin: obj/loader.o65 bin2woz.py
	mkdir -p dist
	cp obj/loader.o65 dist/loader.bin
	python bin2woz.py obj/loader.o65 280 > dist/loader.txt

%.rom: %.json
	python makerom.py $< $@

# Define a pattern rule to build .inc files from their respective sources
%.inc: %
	python bin2inc.py $< > $@

# List of source files (without extensions) for which .inc files need to be generated
# SOURCES := file file2 foo

# # List of target .inc files
# INC_FILES := $(addsuffix .inc, $(SOURCES))

# # Default target to build all .inc files
# all: $(INC_FILES)

.PHONY: all

