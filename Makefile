# Makes the silicon rom
all: 32KA1COMPIL.BIN

# Create the EEPROM and copies it to an X28C256
eeprom: 32KA1COMPIL.BIN
	@echo "Copy of binary into a 28256 via MiniPro"
	minipro -p X28C256 -w 32KA1COMPIL.BIN

SOFTS_SRC = src/LABYRINTH src/LOADER src/WOZMON2 src/A2MON src/TICTACTOE src/LITTLETOWER src/MASTERMIND
SOFTS_BIN = software/APPLE30TH software/BASIC software/CELLULAR software/DISPLAY.bin software/LUNARLANDER software/MASTERMIND software/MEMORYTEST software/MICROCHESS2 software/NIM.04AF software/PASART.FIXED software/TYPINGTUTOR.FIXED software/WOZMON software/mandelbrot65.o65
PATCHES = patches/4KMEMTEST patches/8KMEMTEST patches/NIM

# Declare the targets as phony
.PHONY: $(SOFTS_SRC) $(SOFTS_BIN) $(PATCHES)

# All files in the src directory are built by going into the src directory and running make with their filename
$(SOFTS_SRC): 
	@$(MAKE) -C src $(notdir $@)

# Same for patchs
$(PATCHES):
	@$(MAKE) -C patches $(notdir $@)

# Mandelbrot is downloaded from the github repo if it does not exist
software/mandelbrot65.o65:
	wget https://github.com/fstark/mandelbrot65/raw/refs/heads/main/mandelbrot65.o65 -O software/mandelbrot65.o65

# All files in the software directory are already built

32KA1COMPIL.BIN: 32KA1COMPIL.json $(SOFTS_BIN) $(SOFTS_SRC) $(PATCHES) makerom.py
	@echo "Building the 32KA1COMPIL rom"
	@python3 makerom.py $< $@

clean:
	rm -f a.snp
	@$(MAKE) -C src clean
	@$(MAKE) -C patches clean
	rm -f software/mandelbrot65.o65

# This only works on my machine :-)
mame: 32KA1COMPIL.BIN
	~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp
