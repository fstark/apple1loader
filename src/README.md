# Source files for content

Sources files from which part of the content of the ROM is built.

This contains the source of:

## LOADER

This is the menu/loader assembly code

## WOZMON2

This is wozmon, changed to have the reset vector pointing to $2000, the address of the menu/loader.
I also added the '#' command to jump to wozmon

## A2MON

This is the Apple 2 monitor, changed to assemble to $73FA to be placed in the $7000-$7fff bank of memory, before wozmon at $7f00 (memory at $7xxx can be optionally mapped to $fxxx)

## LABYRINTH

A simple labyrinth assembly program, writen by Aberco/SiliconInsider

## TICTACTOE

The BASIC tic tac toe program. Unfortunately, the source code floating around is wrong. This is a corrected working version. It has been loaded with a patched version of napple1 (https://github.com/fstark/napple1) and saved as a memory dump. From that dump a suitable TICTACTOE file is extracted.

## LITTLETOWER

The version of Little Tower floating around is broken. Here is a version I fixed.

## MEMCHECK

This is the first standalone version of the "Memory Map" option from the loader. The source code is now integrated into LOADER.asm

## MASTERMIND

tr '0-9' 'A-Z' | sed -e 's/^...//g' | sed -e 's/ *$//g' | sed -e 's/ -/ 0-/g' | sed -e 's/\+$/+0/g' | sed -e 's/\([A-Z]\)$/\100/g' | sed -e 's/-----/5/g' | sed -e 's/----/4/g' | sed -e 's/---/3/g' | sed -e 's/--/2/g' | sed -e 's/-/1/g' | sed -e 's/\+\+\+\+\+/5/g' | sed -e 's/\+\+\+\+/4/g' | sed -e 's/\+\+\+/3/g' | sed -e 's/\+\+/2/g' | sed -e 's/\+/1/g'
https://www.dcode.fr/mastermind-solver
