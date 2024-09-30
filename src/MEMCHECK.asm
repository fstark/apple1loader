; This is the minimum set of tests to detect if we can run

MEMSIZE=$02
PTR=$03
CRC = $6           ; 2 bytes in ZP
CRCLO = $600       ; Two 256-byte tables for quick lookup
CRCHI = $700       ; (should be page-aligned for speed)
RAMTYPE=$500



PAGE_RAM='.'    ; This page is RAM
PAGE_ROM='*'    ; This page is ROM
PAGE_ZER='0'    ; This page is ROM filled with ZERO
PAGE_FF ='F'    ; This page is ROM filled with FF
PAGE_IO ='I'    ; This page is reserved for I/O

DSP             = $D012
WOZMON          = $FF00

* = $280

; Check if page zero is RAM
SANITY:
.(
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
NOZP:
    LDA #'Z'+$80
L1: BIT DSP
    BMI L1
    STA DSP
PQ:
    LDA #'P'+$80
L2: BIT DSP
    BMI L2
    STA DSP
    LDA #'?'+$80
L3: BIT DSP
    BMI L3
    STA DSP
    JMP WOZMON

; Here we can assume ZP is ok, bu we don't know about the stack yet
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
NOSP:
    LDA #'S'+$80
L4: BIT DSP
    BMI L4
    STA DSP
    JMP PQ      ; Print 'P?'

CONTINUE:
    JSR MEMMAP
    JSR PRINTMAP
    JMP WOZMON
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
    ; Let's look if it contains $00
    LDA #$00
    JSR CHKPAGE
    BEQ IS_ZER

    ; Or $FF
    LDA #$FF
    JSR CHKPAGE
    BEQ IS_FF

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
IS_ZER:
    LDA #PAGE_ZER
    JMP STORE
IS_FF:
    LDA #PAGE_FF
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

    TYA
    JSR PRBYTE
    LDA #$00
    JSR PRBYTE
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

    RTS
.)

PRINTMAP4:
    JSR PRINTMAP1
    JSR PRINTMAP1
    JSR PRINTMAP1
    JSR PRINTMAP1
    LDA #' '
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

PRBYTE:
    PHA
    LSR
    LSR
    LSR
    LSR
    JSR PRHEX
    PLA
PRHEX:
    AND #$0F
    ORA #'0'+$80
    CMP #$BA
    BCC ECHO
    ADC #$06
ECHO:
    BIT DSP
    BMI ECHO
    STA DSP
    RTS

HEADER:
.byte $d
.byte ".:RAM  *:ROM  0:$00  F:$FF  I:I/O", $d, $d
.byte "ADRS  0000 0400 0800 0C00  CRC", $d
.byte "      ---- ---- ---- ----", $d,0

RAMSTR:
.byte $d,"TOTAL RAM:$",0
BYTESSTR:
.byte " BYTES",$d,0

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
