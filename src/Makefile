all: LOADER WOZMON2 LABYRINTH A2MON

clean:
	rm -f LOADER WOZMON2 LABYRINTH A2MON appleiimonitor.lst appleiimonitor.o appleiimonitor.map

LOADER: loader.s
	xa -o LOADER loader.s

WOZMON2: wozmon.s
	xa -o WOZMON2 wozmon.s

CRC8: crc8.s
	xa -o CRC8 crc8.s

REGS: regs.s
	xa -o REGS regs.s

LABYRINTH: labyrinth.s
	xa -o LABYRINTH labyrinth.s

A2MON: appleiimonitor.s
	ca65 -g -l appleiimonitor.lst appleiimonitor.s
	ld65 -C /usr/share/cc65/cfg/none.cfg -vm -m appleiimonitor.map -o A2MON appleiimonitor.o
