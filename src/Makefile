OBJECTS=LOADER WOZMON2 LABYRINTH A2MON

all: $(OBJECTS)

clean:
	rm -f $(OBJECTS)

# All .asm files are built by running xa on them
%: %.asm
	xa -o $@ $<

A2MON: A2MON.asm
	# ca65 -g -l appleiimonitor.lst appleiimonitor.s
	ca65 A2MON.asm
	ld65 -C /usr/share/cc65/cfg/none.cfg -vm -o A2MON A2MON.o
	@rm A2MON.o
