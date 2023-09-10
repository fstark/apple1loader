
FROM	= $0
TO		= $2
MSG		= $4

CRC     = $6          ; current value of CRC
TMP		= $7


KBD    = $D010	; Keyboard I/O
KBDCR  = $D011
ECHO   = $FFEF
PRBYTE = $FFDC

*		= $7E00

MAIN:
		LDA #<PROMPT
		STA MSG
		LDA #>PROMPT
		STA MSG+1
		JSR PRINT

AGAIN:	LDA #<PRFROM
		STA MSG
		LDA #>PRFROM
		STA MSG+1
		JSR PRINT

		JSR GETHEX2
		STA FROM+1
		JSR GETHEX2
		STA FROM

		LDA #<PRTO
		STA MSG
		LDA #>PRTO
		STA MSG+1
		JSR PRINT

		JSR GETHEX2
		STA TO+1
		JSR GETHEX2
		STA TO

		JSR CRCRANGE

		LDA #<PRCRC
		STA MSG
		LDA #>PRCRC
		STA MSG+1
		JSR PRINT

		LDA CRC
		JSR PRBYTE

		LDA #$d
		JMP AGAIN

PROMPT:	.byte $d,"CRC8 FROM [ADRS1,ADRS2[",$d, 0

PRFROM: .byte $d,"FROM:",0
PRTO:	.byte " TO:",0
PRCRC:	.byte " CRC=",0

; From http //www.6502.org/source/integers/crc-more.html
CRC8:
        EOR CRC         ; A contained the data
        STA CRC         ; XOR it with the byte
        ASL             ; current contents of A will become x^2 term
        BCC UP1         ; if b7 = 1
        EOR #$07        ; then apply polynomial with feedback
UP1     EOR CRC         ; apply x^1
        ASL             ; C contains b7 ^ b6
        BCC UP2
        EOR #$07
UP2     EOR CRC         ; apply unity term
        STA CRC         ; save result
        RTS

; Computes CRC
CRCRANGE:
		LDA  #$00
		STA CRC
LOOP	LDA FROM
		CMP TO
		BNE CONT
		LDA FROM+1
		CMP TO+1
		BNE CONT
		RTS
CONT	LDY #0
		LDA (FROM),Y
		JSR CRC8
		INC FROM
		BNE LOOP
		INC FROM+1
		JMP LOOP

; Read hex digit
GETHEX1	JSR GET
		TAX
		CLC
		CMP #'0'
		BMI GETHEX1
		CMP #'9'+1
		BMI GOOD
		CMP #'A'
		BMI GETHEX1
		CMP #'F'+1
		BPL GETHEX1
		SBC #('A'-'0'-10)
GOOD	SBC #'0'-1
		PHA
		TXA
		JSR ECHO
		PLA
		RTS

; Read 2 hex digits
GETHEX2	JSR GETHEX1
		ASL
		ASL
		ASL
		ASL
		STA TMP
		JSR GETHEX1
		ORA TMP
		RTS

GET		LDA KBDCR       ; Key ready?
		BPL GET         ; Loop until ready.
		LDA KBD         ; Load character.
		EOR #$80        ; Clear bit 7
		RTS

PRINT:	LDY #0
LOOP2:	LDA (MSG),Y
		INY
		CMP #$00
		BEQ END
		JSR ECHO
		JMP LOOP2
END:	RTS
