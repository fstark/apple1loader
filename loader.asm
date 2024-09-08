;* = $280

*= $5000

VERSION = $02

PTR = $30
ADRS = $32

SIZE = $34
FROM = $36
TO = $38

COUNTER=$30     ; Counts time for screen output
STEP=$32

KBD    = $D010	; Keyboard I/O
KBDCR  = $D011
ECHO   = $FFEF
PRBYTE = $FFDC


TBASIC=3

; We want the loader to be activable via the reset vector at $FFFC
; However, the Apple1 is not ready to run at startup
; We first need to initialize the PIAs, set interrupts, etc
; The other problem is that the Apple1 is not usable until the user
; clears the screen (as there may be multiple cursor bits set)
; If we write before the screen is cleared, we will get data written
; all over the screen
; We detect if the screen has been cleared by looking at how long there
; is between two consecutive cursors 

; KBDCR           = $D011         ;  PIA.A keyboard control register
DSP             = $D012         ;  PIA.B display output register
DSPCR           = $D013         ;  PIA.B display control register

RESET:
  CLD             ; Clear decimal arithmetic mode.
  CLI
  LDY #$7F        ; Mask for DSP data direction register.
  STY DSP         ; Set it up.
  LDA #$A7        ; KBD and DSP control register mask.
  STA KBDCR       ; Enable interrupts, set CA1, CB1, for
  STA DSPCR       ; positive edge sense/output mode.

    ; Fill $1000 to $10ff with $ff
  LDX #$00
  LDA #$FF
FILL:
  STA $1000,X
  INX
  INX
  BNE FILL

  ; LDA #$00
  ; STA STEP

    ; First sync
  JSR WAITANDPRINT

WAITFORPAGE:
  JSR CLRCOUNTER

    ; Wait for 2 cursors
  JSR WAITANDPRINT
  JSR WAITANDPRINT

    ; Store the counter in $1000 + (STEP)
  ; LDX STEP
  ; LDA COUNTER
  ; STA $1000,X
  ; LDA COUNTER+1
  ; STA $1000+1,X
  ; INX
  ; INX
  ; STX STEP
  ; TXA
  ; CMP #$00
  ; BEQ TIMEOUT

    ; Single cursor takes 16ms, which lets the counter go to around 01AE
    ; So two single cursors would be 035D
    ; In no case a single cursor would be more than 02FF
  LDA COUNTER+1
  CMP #$02
  BCS TIMEOUT
  JSR WAIT        ; Higher probability that the user
                  ; clears the page without any writing occurring
  BRA WAITFORPAGE

TIMEOUT:

    ; Took more than 0300, so we are ready to go

  ; CR
  LDA #$D
  JSR ECHO

  LDA #VERSION
  JSR PRBYTE
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
  JSR ECHO
  ; increment 16 bits value in PTR, PTR+1
  CLC
  LDA PTR
  ADC #$01
  STA PTR
  BCC LOOP0
  INC PTR+1
  JMP LOOP0

; Wait a good fraction of a second
WAIT:
       LDX #$20
REDOX: LDY #$FF
REDOY: LDA #$FF
REDOA: SBC #$1
       BNE REDOA
       DEY
       BNE REDOY
       DEX
       BNE REDOX
       RTS

; WAIT AND PRINT
WAITANDPRINT:
  JSR INCCOUNTER
  BIT DSP         ; bit (B7) cleared yet?
  BMI WAITANDPRINT; No

                  ; Send a space
  LDA #' '+$80
  STA DSP
  RTS

; Clears COUNTER
CLRCOUNTER:
  LDA #$00        ; Clear counter.
  STA COUNTER
  STA COUNTER+1

; Increments COUNTER
; Destroys A and Flags
INCCOUNTER:
  LDA COUNTER
  CLC
  ADC #$01
  STA COUNTER
  LDA COUNTER+1
  ADC #$00
  STA COUNTER+1
  RTS

START:
  ; DISPLAY MENU
  LDA #<MENU
  STA PTR
  LDA #>MENU
  STA PTR+1
  LDY #$0
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

BANNER:
    .byte $00
;          12345678901234567890123456789012345678901234567890
    .byte "    ___    ____  ____  __    ______   __"
    .byte "   /   !  / __ \/ __ \/ /   / ____/  / /"
    .byte "  / /! ! / /_/ / /_/ / /   / __/    / /", $0d
    .byte " / ___ !/ ____/ ____/ /___/ /___   / /", $0d
    .byte "/_/  !_/_/   /_/   /_____/_____/  /_/", $0d
    .byte "      __   ____  ___   ___  ________", $0d
    .byte " \   / /  / __ \/ _ ! / _ \/ ___/ _ \ / "
    .byte "--  / /__/ /_/ / __ !/ // /  __/ , _/ --"
    .byte " / /____/\____/_/ !_/____/|___/ /!_!  \ "
    .byte $0d
    .byte "   FREDERIC STARK & ANTOINE BERCOVICI", $0d
    .byte "========================================",
    .byte $00

PROMPT:
    .byte "========================================",
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
