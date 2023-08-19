# Builds the binary file
obj/loader.o65: loader.asm
	mkdir -p obj
	xa -o obj/loader.o65 loader.asm

# Runs in mame
run: obj/loader.snp
	mame -debug apple1 -ui_active -resolution 640x480 -snapshot obj/loader.snp

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
