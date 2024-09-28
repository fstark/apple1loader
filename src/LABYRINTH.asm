; C64 labyrinth, siliconinsider

* = $280
seed = $31
PTR = $30

LDA #<BANNER
STA PTR
LDA #>BANNER
STA PTR+1
LDY #$00
Bannerdisplay:
LDA (PTR),Y
CMP #$00
BEQ Seedloop
INY
JSR $FFEF
JMP Bannerdisplay

BANNER:
.byte $0d, $0d
.byte "PRESS KEY TO START"
.byte $0d, $00


Seedloop: ;generate random seed
INX
LDA $D011 ;wait for keypress
BPL Seedloop

STX seed
LDA #$8D ;carriage return
JSR $FFEF

loop: ;generate gallois24 PRNG
LDY #8
LDA seed+0
Point1:
ASL
ROL seed+1
ROL seed+2
BCC Point2
EOR #$1B
Point2:
DEY
BNE Point1
STA seed+0
CMP #0

AND #$01
BNE bit0set
LDA #$2F
JSR $FFEF
JMP loop

bit0set:
LDA #$5C
JSR $FFEF
JMP loop
