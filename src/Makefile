OBJECTS=LOADER WOZMON2 LABYRINTH A2MON TICTACTOE LITTLETOWER MEMCHECK MASTERMIND

all: $(OBJECTS)

clean:
	rm -f $(OBJECTS)

# All .asm files are built by running xa on them
%: %.asm
	xa -XCA65 -o $@ $<

A2MON: A2MON.asm
	# ca65 -g -l A2MON.lst A2MON.s
	ca65 A2MON.asm
	ld65 -C none.cfg -vm -o A2MON A2MON.o
	@rm A2MON.o

LITTLETOWER: LITTLETOWER.asm
	# ca65 -l LITTLETOWER.lst  LITTLETOWER.asm
	ca65 LITTLETOWER.asm
	ld65 -C none.cfg -vm -o LITTLETOWER LITTLETOWER.o
	@rm LITTLETOWER.o

TICTACTOE: TICTACTOE.core
	python3 ../utils/core2bin.py TICTACTOE.core TICTACTOE
