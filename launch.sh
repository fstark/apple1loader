head -c $((12 + 0xA000)) a.snp > a40.snp
mame apple1 -ramsize 48K -ui_active -window -nomaximize -resolution 640x480 -snapshot a40.snp
