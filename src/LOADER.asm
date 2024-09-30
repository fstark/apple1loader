;* = $280

*= $5000

VERSION = $03

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
WOZMON = $FF00

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

; Entry points
  JMP RESET
  JMP HWCHECK

RESET:
.(

    ; Set up the Apple1 if we replace the WOZMON

  CLD             ; Clear decimal arithmetic mode.
  CLI
  LDY #$7F        ; Mask for DSP data direction register.
  STY DSP         ; Set it up.
  LDA #$A7        ; KBD and DSP control register mask.
  STA KBDCR       ; Enable interrupts, set CA1, CB1, for
  STA DSPCR       ; positive edge sense/output mode.

    ; Check if ZP and SP memory are available

    ; Check ZP
  LDA $00     ; Whatever is in $00
  TAX
  EOR #$FF
  STA $00     ; Is EOR and stored back
  TXA
  CMP $00     ; Then compared
  BEQ NOZP    ; If equal, it cannot be written
  EOR #$FF
  CMP $00     ; Then compare with correct EOR
  BEQ ZPOK

  ; We could not write to address 0
  ; Or we did not read back the EOR value
  ; Print "ZP?" in a loop
NOZP:
.(
    LDA #'Z'+$80
L1: BIT DSP
    BMI L1
    STA DSP
    LDA #'P'+$80
L2: BIT DSP
    BMI L2
    STA DSP
    LDA #'?'+$80
L3: BIT DSP
    BMI L3
    STA DSP
    JMP NOZP
.)
  ; Check if the stack is available
ZPOK:
    JSR NEXT
NEXT:
    PLA
    CMP #<(NEXT-1)
    BNE NOSP
    PLA
    CMP #>NEXT
    BEQ CONTINUE

    ; We don't have a stack
    ; Print "ZP?" in a loop
NOSP:
.(
    LDA #'S'+$80
L1: BIT DSP
    BMI L1
    STA DSP
    LDA #'P'+$80
L2: BIT DSP
    BMI L2
    STA DSP
    LDA #'?'+$80
L3: BIT DSP
    BMI L3
    STA DSP
    JMP NOSP
.)

CONTINUE:

    ; First sync
  JSR WAITANDPRINT

  JSR CLRCOUNTER

    ; Wait for 2 cursors
  JSR WAITANDPRINT
  JSR WAITANDPRINT

    ; Single cursor takes 16ms, which lets the counter go to around 01AE
    ; So two single cursors would be around 035D
    ; In no case a single cursor would be more than 02FF
  LDA COUNTER+1
  CMP #$02
  BCC SKIP
  JMP DISPLAYMENU

SKIP:
    ; Screen not inited correctly, jumping to wozmon
  JMP WOZMON
.)

; WAIT AND PRINT
WAITANDPRINT:
.(
  JSR INCCOUNTER
  BIT DSP         ; bit (B7) cleared yet?
  BMI WAITANDPRINT; No

                  ; Send a space
  LDA #' '+$80
  STA DSP
  RTS
.)

; Clears COUNTER
CLRCOUNTER:
.(
  LDA #$00        ; Clear counter.
  STA COUNTER
  STA COUNTER+1
  ; #### MISSING RTS!!!
.)

; Increments COUNTER
; Destroys A and Flags
INCCOUNTER:
.(
  LDA COUNTER
  CLC
  ADC #$01
  STA COUNTER
  LDA COUNTER+1
  ADC #$00
  STA COUNTER+1
  RTS
.)

DISPLAYMENU:
.(
  ; CR
  LDA #$D
  JSR ECHO

  ; LDA #VERSION
  ; JSR PRBYTE
  ; LDA #$D
  ; JSR ECHO
  
  LDA #<BANNER
  STA PTR
  LDA #>BANNER
  STA PTR+1
  LDY #$00

LOOP0:
  JSR TESTKEY
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

; Looks if a key is pressed
; If yes directly jumps to menu execution code
TESTKEY:
  LDA KBDCR       ; Key ready?
  BPL DONETESTKEY ; Nope
  LDA #$0d
  JSR ECHO
  JMP MENUKEY
DONETESTKEY:
  RTS

; Adds Y to PTR, Clear Y
ADDPTRY:
  TYA
  CLC
  ADC PTR
  STA PTR
  LDA PTR+1
  ADC #0
  STA PTR+1
  LDY #0
  RTS

DISPLAYLABEL:
  LDA (PTR),Y
  INY
  JSR ECHO
  LDA #$29 ; ')'
  JSR ECHO
  LDA #$20 ; ' '
  JSR ECHO
  ; Display name of entry
  LDX #18
LOOP1:
  JSR TESTKEY
  LDA (PTR),Y
  DEX
  INY
  JSR ECHO
  CMP #$00
  BNE LOOP1

  ; Need X spaces
LOOP11:
  JSR TESTKEY
  LDA #' '
  JSR ECHO
  DEX
  BNE LOOP11

  RTS


START:
  ; DISPLAY MENU
  LDA #<MENU
  STA PTR
  LDA #>MENU
  STA PTR+1
  LDY #$0

ENTRY:
  JSR ADDPTRY
  LDA (PTR),Y
  BEQ DONE
  INY
  INY
  INY
  INY
  INY
  INY
  INY

  CMP #$04    ; Empty entry
  BNE NOTEMPTY
  LDA #' '
  LDX #20
NOTEMPTYLOOP:
  JSR ECHO
  DEX
  BNE NOTEMPTYLOOP
  INY ; Skip key
  INY ; Skip label end
  JMP ENTRY

NOTEMPTY:

  JSR DISPLAYLABEL

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
MENUKEY:
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
  JSR ADDPTRY
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
  ; Scan label
LOOP5:
  INY
  LDA (PTR),Y
  CMP #$00
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
.)

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
.(
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
.)

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
    ; .byte $00
;          12345678901234567890123456789012345678901234567890
    .byte "    ___    ____  ____  __    ______   __"
    .byte "   /   !  / __ \\/ __ \\/ /   / ____/  / /"
    .byte "  / /! ! / /_/ / /_/ / /   / __/    / /", $0d
    .byte " / ___ !/ ____/ ____/ /___/ /___   / /", $0d
    .byte "/_/  !_/_/   /_/   /_____/_____/  /_/", $0d
    .byte "      __   ____  ___   ___  ________", $0d
    .byte " \\   / /  / __ \\/ _ ! / _ \\/ ___/ _ \\ / "
    .byte "--  / /__/ /_/ / __ !/ // /  __/ , _/ --"
    .byte " / /____/\\____/_/ !_/____/|___/_/!_!  \\ "
    .byte $0d
    .byte "   FREDERIC STARK & ANTOINE BERCOVICI", $0d
    .byte "========================================",
    .byte $00

PROMPT:
    .byte "===================================V1.2=",
    .byte "Your Choice -> "
    .byte $00



; This is the minimum set of tests to detect if we can run

MEMSIZE=$02
; PTR=$03         ; Need another name
CRC = $6           ; 2 bytes in ZP
CRCLO = $600       ; Two 256-byte tables for quick lookup
CRCHI = $700       ; (should be page-aligned for speed)
RAMTYPE=$500



PAGE_RAM='W'    ; This page is RAM
PAGE_ROM='R'    ; This page is ROM
PAGE_CON='.'    ; This page is ROM constant (ie: not mapped)
PAGE_IO ='I'    ; This page is reserved for I/O

; DSP             = $D012
; WOZMON          = $FF00

; * = $280

; Display HW check
HWCHECK:
.(
  LDA #$d
  JSR ECHO
  JSR MEMMAP
  JSR PRINTMAP

    ; Wait for a keypress
LOOP:
  LDA KBDCR       ; Key ready?
  BPL LOOP
  LDA KBD
  JMP RESET
.)

; Maps the usage of memory
MEMMAP:
.(
    LDA #$00
LOOP:
    PHA
    JSR TESTPAGE
    PLA
    CLC
    ADC #1
    BNE LOOP
    RTS
.)

TESTPAGE:
        ; Hard-code "dangerous" pages
    TAX
    CMP #$00
    BEQ IS_RAM
    CMP #$01
    BEQ IS_RAM
    PHA
    AND #$F0
    CMP #$D0
    BEQ IS_IO
    PLA
        ; Test for RAM
    STA PTR+1
    LDA #$00
    STA PTR
    LDY #$00
    LDA (PTR),Y
    EOR #$FF
    STA (PTR),Y
    CMP (PTR),Y
    BNE NOT_RAM
        ; This page is RAM, restore it
    EOR #$FF
    STA (PTR),Y
    JMP IS_RAM

NOT_RAM:
    ; Let's look if it is constant
    LDA (PTR),Y
    JSR CHKPAGE
    BEQ IS_CON

    ; Normal ROM
    JMP IS_ROM

CHKPAGE:
.(
    LDY #$00
LOOP:
    CMP (PTR),Y
    BNE DONE        ; Different value
    DEY
    BNE LOOP
DONE:
    RTS
.)

IS_RAM:
    LDA #PAGE_RAM
    JMP STORE
IS_ROM:
    LDA #PAGE_ROM
    JMP STORE
IS_CON:
    LDA #PAGE_CON
    JMP STORE
IS_IO:
    PLA
    LDA #PAGE_IO
STORE:
    STA RAMTYPE,X
    RTS

; Prints the memory map
PRINTMAP:
.(
    JSR MAKECRCTABLE
    LDA #0
    STA MEMSIZE
    JSR PRHEADER
    LDY #0
LOOP:
    LDA #$FF
    STA CRC
    STA CRC+1

    LDA #' '
    JSR ECHO
    TYA
    JSR PRBYTE
    LDA #$00
    JSR PRBYTE
    LDA #' '
    JSR ECHO
    LDA #':'
    JSR ECHO
    LDA #' '
    JSR ECHO
    JSR PRINTMAP4
    JSR PRINTMAP4
    JSR PRINTMAP4
    JSR PRINTMAP4
    LDA CRC
    CMP #$FF
    BNE PRINTCRC
    LDA CRC+1
    CMP #$FF
    BEQ SKIP
PRINTCRC:
    LDA #' '
    JSR ECHO
    LDA CRC+1
    JSR PRBYTE
    LDA CRC
    JSR PRBYTE
SKIP:
    LDA #$d
    JSR ECHO
    TYA
    BNE LOOP

      ; Print RAM size
    LDA #<RAMSTR
    STA PTR
    LDA #>RAMSTR
    STA PTR+1
    JSR PRSTR
    LDA MEMSIZE
    JSR PRBYTE
    LDA #$00
    JSR PRBYTE
    LDA #<BYTESSTR
    STA PTR
    LDA #>BYTESSTR
    STA PTR+1
    JSR PRSTR

      ; Print BOOT
    LDA #<BOOTSTR
    STA PTR
    LDA #>BOOTSTR
    STA PTR+1
    JSR PRSTR

    LDA $FFFC+1
    CMP #$FF          ; WOZMON
    BEQ ISWOZMON
    CMP #$50          ; Apple1Loader
    BEQ ISLOADER
    RTS

ISWOZMON:
    LDA #<WOZMONSTR
    STA PTR
    LDA #>WOZMONSTR
    STA PTR+1
    JMP PRSTR

ISLOADER:
    LDA #<LOADERSTR
    STA PTR
    LDA #>LOADERSTR
    STA PTR+1
    JMP PRSTR
.)

PRINTMAP4:
    JSR PRINTMAP1
    JSR PRINTMAP1
    JSR PRINTMAP1
    JSR PRINTMAP1
    LDA #' '
    JSR ECHO
    JMP ECHO

PRINTMAP1:
.(
    LDA RAMTYPE,Y
    JSR ECHO
    CMP #PAGE_RAM
    BNE SKIP
    INC MEMSIZE
SKIP:
    CMP #PAGE_ROM
    BEQ UPDCRCROM
    INY
    RTS
.)

UPDCRCROM:
.(
    TYA
    PHA
    STA PTR+1
    LDA #$00
    STA PTR
    LDY #0
LOOP:
    LDA (PTR),Y
    JSR UPDCRC
    DEY
    BNE LOOP
    PLA
    TAY
    INY
    RTS
.)

; Local version of Wozmon in case wozmon isn't available
; Need to update call sites
LPRBYTE:
    PHA
    LSR
    LSR
    LSR
    LSR
    JSR LPRHEX
    PLA
LPRHEX:
    AND #$0F
    ORA #'0'+$80
    CMP #$BA
    BCC LECHO
    ADC #$06
LECHO:
    BIT DSP
    BMI LECHO
    STA DSP
    RTS

HEADER:
.byte $d
.byte "LEGEND: W=RAM   R=ROM   I=I/O   .=OTHER", $d, $d
.byte " ADRS   0000  0400  0800  0C00   CRC", $d
.byte "        ----  ----  ----  ----", $d,0

RAMSTR:
.byte $d,"      TOTAL RAM: $",0
BYTESSTR:
.byte " BYTES",$d,0
BOOTSTR:
.byte    "    BOOT VECTOR: ",0
WOZMONSTR:
.byte "WOZMON",$d,0
LOADERSTR:
.byte "LOADER",$d,0

PRHEADER:
.(
    LDA #<HEADER
    STA PTR
    LDA #>HEADER
    STA PTR+1
.)
PRSTR:
.(
    LDY #0
LOOP:
    LDA (PTR),Y
    BNE CONTINUE
    RTS
CONTINUE:
    JSR ECHO
    INY
    JMP LOOP
.)


MAKECRCTABLE:
         LDX #0          ; X counts from 0 to 255
BYTELOOP LDA #0          ; A contains the low 8 bits of the CRC-16
         STX CRC         ; and CRC contains the high 8 bits
         LDY #8          ; Y counts bits in a byte
BITLOOP  ASL
         ROL CRC         ; Shift CRC left
         BCC NOADD       ; Do nothing if no overflow
         EOR #$21        ; else add CRC-16 polynomial $1021
         PHA             ; Save low byte
         LDA CRC         ; Do high byte
         EOR #$10
         STA CRC
         PLA             ; Restore low byte
NOADD    DEY
         BNE BITLOOP     ; Do next bit
         STA CRCLO,X     ; Save CRC into table, low byte
         LDA CRC         ; then high byte
         STA CRCHI,X
         INX
         BNE BYTELOOP    ; Do next byte
         RTS

UPDCRC:
         EOR CRC+1       ; Quick CRC computation with lookup tables
         TAX
         LDA CRC
         EOR CRCHI,X
         STA CRC+1
         LDA CRCLO,X
         STA CRC
         RTS










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


; MENU structure
; TYPE    0x00 End of menu
;         0x01 Direct jump
;         0x02 Copy + jump
;         0x03 Basic
;         0x04 <empty>
; TYPE 1  ADRS, 4*UNSUSED 
; TYPE 2  FROM, SIZE, TO
; TYPE 3  FROM, SIZE, TO
; KEY     Key to activate menu item
; LABEL   String to display, 0x00 terminated
