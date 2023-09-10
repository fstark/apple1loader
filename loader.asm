;* = $280

*= $7000

PTR = $30
ADRS = $32

SIZE = $34
FROM = $36
TO = $38


KBD    = $D010	; Keyboard I/O
KBDCR  = $D011
ECHO   = $FFEF
PRBYTE = $FFDC


TBASIC=3

  ; CR
  LDA #$D
  JSR ECHO

  LDA #<BANNER
  STA PTR
  LDA #>BANNER
  STA PTR+1
  LDY #$00
LOOP0:
  LDA (PTR),Y
  CMP #$00
  BEQ START
  INY
  JSR ECHO
  JMP LOOP0
BANNER:
    .byte $0d, $0d
    .byte " **** APPLE 1 DEMO LOADER ****"
    .byte $0d, $00
START:
  ; DISPLAY MENU
  LDA #<MENU
  STA PTR
  LDA #>MENU
  STA PTR+1
  LDA #$0d
  LDY #$0
  JSR ECHO
  JSR ECHO
ENTRY:
  LDA (PTR),Y
  BEQ DONE
  INY
  INY
  INY
  INY
  INY
  INY
  INY
  LDA (PTR),Y
  INY
  JSR ECHO
  LDA #$29 ; ')'
  JSR ECHO
  LDA #$20 ; ' '
  JSR ECHO
LOOP1:
  LDA (PTR),Y
  INY
  JSR ECHO
  CMP #$D
  BNE LOOP1
  JMP ENTRY
DONE:
  LDA #<PROMPT
  STA PTR
  LDA #>PROMPT
  STA PTR+1
  LDY #0
LOOP2:
  LDA (PTR),Y
  INY
  CMP #$00
  BEQ END
  JSR ECHO
  JMP LOOP2
END:
LOOP3:
  LDA KBDCR       ; Key ready?
  BPL LOOP3       ; Loop until ready.
  LDA KBD         ; Load character.
  EOR #$80        ; Clear bit 7

  JSR ECHO

; Search for entry
  TAX
  LDA #<MENU
  STA PTR
  LDA #>MENU
  STA PTR+1
  LDY #$0
  
LOOP4:
  LDA (PTR),Y    ; Entry type

  CMP #$00       ; Last entry?
  BEQ START      ; Menu again
  TXA
  INY
  INY
  INY
  INY
  INY
  INY
  INY
  CMP (PTR),Y
  BEQ FOUND
LOOP5:
  INY
  LDA (PTR),Y
  CMP #$0d
  BNE LOOP5
  INY
  JMP LOOP4
FOUND:
  LDA #$0d
  JSR ECHO
  JSR ECHO

  DEY
  DEY
  DEY
  DEY
  DEY
  DEY
  DEY
  LDA (PTR),Y
  CMP #1        ; Assembly direct jump
  BEQ TYPE1
  CMP #2        ; Assembly copy + jump
  BEQ TYPE2
  CMP #TBASIC   ; Basic
  BEQ TYPE3
  JMP START     ; ### Should print err

TYPE1:
  INY
  LDA (PTR),Y
  STA ADRS
  INY
  LDA (PTR),Y
  STA ADRS+1
  JMP (ADRS)

TYPE2:
  
  INY
  LDA (PTR),Y
  STA FROM
;  JSR DBGHEX
  INY
  LDA (PTR),Y
  STA FROM+1
;  JSR DBGHEX

  INY
  LDA (PTR),Y
  STA SIZE
;  JSR DBGHEX
  INY
  LDA (PTR),Y
  STA SIZE+1
;  JSR DBGHEX

  INY
  LDA (PTR),Y
  STA TO
  STA ADRS
;  JSR DBGHEX
  INY
  LDA (PTR),Y
  STA TO+1
  STA ADRS+1
;  JSR DBGHEX

  JSR MEMCPY

  JMP (ADRS)

TYPE3:
  INY

  ; Copy the $4A-$FF region

  ; Source of data
  LDA (PTR),Y
  STA FROM
  INY
  LDA (PTR),Y
  STA FROM+1

  ; Copy $B6 bytes
  LDA #($100-$4A)
  STA SIZE
  LDA #$00
  STA SIZE+1

  ; Copy in $4A
  LDA #$4A
  STA TO
  LDA #$00
  STA TO+1

  TYA
  PHA
  ; Copy ZP
  JSR MEMCPY
  PLA
  TAY

  ; Copy the rest

  ; Get the original source
  DEY
  LDA (PTR),Y
  STA FROM
  INY
  LDA (PTR),Y
  STA FROM+1

  ; Add $B6
  CLC
  LDA #$B6
  ADC FROM
  STA FROM
  BCC SKIP
  INC FROM+1
SKIP:

  ; Get size
  INY
  LDA (PTR),Y
  STA SIZE
  INY
  LDA (PTR),Y
  STA SIZE+1

  ; Get destination
  INY
  LDA (PTR),Y
  STA TO
  STA ADRS
  INY
  LDA (PTR),Y
  STA TO+1
  STA ADRS+1

  ; Copy source
  JSR MEMCPY

  ; RUN PROGRAM
  JMP $EFEC

; FROM = source start address
;   TO = destination start address
; SIZE = number of bytes to move

MEMCPY   LDY #0
         LDX SIZE+1
         BEQ MD2
MD1      LDA (FROM),Y ; move a page at a time
         STA (TO),Y
         INY
         BNE MD1
         INC FROM+1
         INC TO+1
         DEX
         BNE MD1
MD2      LDX SIZE
         BEQ MD4
MD3      LDA (FROM),Y ; move the remaining bytes
         STA (TO),Y
         INY
         DEX
         BNE MD3
MD4      RTS


DBGHEX:
  PHA
  JSR PRBYTE
  PLA
  RTS

PROMPT:
    .byte $0d
    .byte "Your Choice -> "
    .byte $00

; Relocatable assembly
; Can be executed in-place
; EXAMPLE1:
; EX1PTR = $30
;     LDA #<EX1DATA
;     STA EX1PTR
;     LDA #>EX1DATA
;     STA EX1PTR+1
;     LDY #$0
; EX1LOOP:
;     LDA (PTR),Y
;     JSR $FFEF
;     INY
;     TYA
;     CMP #16
;     BNE EX1LOOP
;     RTS
; EX1DATA:
;     .byte "Hello, World ROM"

; Non-relocatable assembly
; Must be executed from $280
; EXAMPLE2:
; EX2PTR = $30
;     JMP $283
;     LDA #<EX2DATA
;     STA EX2PTR
;     LDA #>EX2DATA
;     STA EX2PTR+1
;     LDY #$0
; EX2LOOP:
;     LDA (PTR),Y
;     JSR $FFEF
;     INY
;     TYA
;     CMP #16
;     BNE EX2LOOP
;     RTS
; EX2DATA:
;     .byte "Hello, World RAM"


; EXAMPLE3:

MENU:
  ; The menu needs to be just after the loader
