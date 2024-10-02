; ---------------------------------------
; MASTERMIND, Steve Wozniak, 1976
; http://cini.classiccmp.org/pdf/DrDobbs/DrDobbs-1976-09-v1n8.pdf
; ---------------------------------------
; Moved ZP variables, as GUESS in $FB is wrong (FB+5>FF)
; ---------------------------------------
TRIES	=$E2
RNDL	=$E3
RNDH	=$E4
RND2L	=$E5
N		=$E6
GUESS	=$EB
COUT	=$FFEF
PRBYTE	=$FFDC
KBD		=$D010
STROBE	=$D011

*=$300

MSTMND:
	LDX #$8
MSGLP:
	LDA MSG-1,X
	JSR COUT			; PRINT 'READY?'
	DEX
	BNE MSGLP
	STX TRIES			; SET TRIES TO ZERO.
RNDLP:
	INC RNDL
	BNE RND2			; FORM 2-BYTE RANDOM NUMBER
	INC RNDH			; UNTIL KEY DOWN
RND2:
	LDA STROBE
	BPL RNDLP
	JSR CHARIN			; CLEAR STROBE.
	JSR CFGCHECK		; FReD: configure "easy mode" if key pressed is E
NXTRY:
	SEC
	SED
	TXA
	ADC TRIES			; ADD 1 TO TRIES IN DECIMAL NODE
	STA TRIES
	CLD
NXTLIN:
	JSR CRLF
	LDA TRIES			; OUTPUT CRLF AND TRIES (IN BCD)
	JSR PRBYTE
	LDA #$A0			; OUTPUT BLANK.
	TAY
	JSR COUT
	LDA RNDL
	STA RND2L
	LDA RNDH
	LDX #$5				; SET ARRAY N TO 5 DIGITS OF
DIGEN:
	STY N-1,X			; RANDOM NUMBER. DIGITS ARE
	LDY #$3				; 0 THROUGH 7.
BITGEN:
	LSR
	ROL RND2L
	ROL N-1,X
	DEY
	BNE BITGEN
TOGGLE:
	JMP CHECK			; Added by FReD: check N-1,X is different from previous numbers
CHECKOK:
	DEX
	BNE DIGEN
RDKEY:
	JSR CHARIN			; READ AND ECHO A CHARACTER.
	JSR COUT
	EOR #$B0			; CONVERTS DIGITS TO TRUE VALUE.
	CMP #$8				; IF NOT & TO 7 THEN. REPEAT LINE
	BCS NXTLIN			; WITH SAME TRIES VALUE.
	STA GUESS+4,X		; SAVE USER DIGIT.
	DEX
	CPX #$FB			; DONE 5 DIGITS?
	BNE RDKEY
	LDY #$FB			; WIN COUNT (FOR 5 MATCHES)
	LDA #$A0			; PRINT BLANK.
PLUS1:
	JSR COUT
PLUS2:
	LDA GUESS+5,X		; DOES GUESS MATCH RANDOM NUMBER
	CMP N+5,X			; FOR THIS DIGIT POSITION?
	BNE PLUS3			; NO, TRY NEXT POSITION.
	STY N+5,X			; SETS DIG OF RAND NUNGER, TO $FB
	LDA #$AB			; -$FF SO NO 'MINUS' MATCH.
	STA GUESS+5,X		; SET DIGIT OF GUESS TO AB $0
	INY					; *  NO 'MINUS' MATCH.
	BNE PLUS1			; INCR. WIN COUNTER AND LOOP.
	LDX #$11			; IF WIN OUTPUT WIN MESSAGE
	BNE MSGLP			; AND BEGIN NEW GAME.
PLUS3:
	INX					; NEXT DIGIT OF 'PLUS' SCAN.
	BNE PLUS2
	LDY #$FB
MINUS1:
	LDX GUESS+5,X		; GET DIGIT OF USER GUESS.
	TXA
	LDX #$FB
MINUS2:
	CMP N+5,X			; COMP TO DIGIT OF RAND NUMBER.
	BNE MINUS3			; NO MATCH.
	STY N+5,X			; SET RAND DIGIT TO $FB-$FF
	LDA #$AD			; SUBSTITUTE $AD FOR GUESS DIGIT
	JSR COUT
MINUS3:
	INX					; * NEXT RANDOM DIGIT.
	BNE MINUS2			; *    LOOP.
	INY					; * NEXT USER DIGIT.
	BNE MINUS1			; *    LOOP.
	BEQ NXTRY			; UPDATE TRIES FOR NEXT LINE.
MSG:
	.byte $BF
	.byte $D9
	.byte $C4
	.byte $C1
	.byte $C5
	.byte $D2
	.byte $8D
	.byte $8D
	.byte $CE
	.byte $C9
	.byte $D7
	.byte $A0
	.byte $D5
	.byte $CF
	.byte $D9
	.byte $A0
	.byte $AB
CRLF:
	LDA #$8D
	JMP COUT
CHARIN:
	LDA STROBE			; WAIT FOR STROBE
	BPL CHARIN
	LDA KBD				; READ KEY AND CLEAR STROBE.
	RTS

; ---------------------------------------
; Done at the end as not to pollute Wozniak's code
;
; FReD's patches. Ugly code, but I am not
; going to compete with the Woz anyway.
; Plus I do not want to change any of the
; bytes above that I can avoid changing.
; ---------------------------------------

; ---------------------------------------
; N-1,X is the new number to check
; it must be different from all N-1,Y, with X<Y<=5
; ---------------------------------------
CHECK:
	PHA
	TYA
	PHA

	TXA
	TAY
LOOP:
	CPY #5
	BEQ NODUPS
	INY
	LDA N-1,X
	CMP N-1,Y
	BEQ DUPS
	JMP LOOP

NODUPS:
	PLA
	TAY
	PLA
	JMP CHECKOK

DUPS:
	PLA
	TAY
	PLA
	JMP DIGEN

CFGCHECK:
	CMP #'M'+$80
	BNE DONE
	LDA #$60 ; JMP (4C) ^ BIT (2C)
	EOR TOGGLE
	STA TOGGLE
	JSR PRBYTE
	CLC
	ADC #$41		; '!' or 'A'
	LDA #'!'+$80
	JSR COUT
DONE:
	RTS

