# Loader for the Apple1

This is the loader for aberco/SiliconInsider 32K ROM for the Apple1

It contains an assortment of software for the Apple1.

The rom file is [silicrom.rom](silicrom.rom).

If you have the right tools, it can be built using the ``doit.sh`` script (to be turned into a Makefile soon)

A snapshot named 'a.snp' will be placed next to the rom. It can be loaded in mame using: ``~/Development/mame/mame -debug apple1 -ui_active -resolution 640x480 -snapshot a.snp``
