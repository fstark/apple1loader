#!/bin/sh -e

# Build assembly sources

( cd src && make )

# Build patches

( cd patches && make )

# Download mandelbrot65.o65

( cd software && rm -f mandelbrot65.o65 && wget https://github.com/fstark/mandelbrot65/raw/refs/heads/main/mandelbrot65.o65 )

# Build the ROM

python makerom.py silicrom.json silicrom.rom


# Flash rom

# minipro -p X28C256 -w silicrom.rom -y

( cd src && make clean )

( cd patches && make clean )

rm -f software/mandelbrot65.o65

# ~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp 
rm a.snp
