; trace tt.trace,,,{tracelog "A=%02X X=%02X Y=%02X P=%02X ",a,x,y,p}

RA		= $0
RX		= $1
RY		= $2
RP 		= $3

; KBD    = $D010	; Keyboard I/O
; KBDCR  = $D011
ECHO   = $FFEF
PRBYTE = $FFDC

*		= $9D00

MAIN:

		PHP
		STA RA
		PLA
		STA RP
		TXA
		STA RX
		TYA
		STA RY

		LDA #$d
		JSR ECHO

		LDA #'A'
		JSR ECHO
		LDA #'='
		JSR ECHO
		LDA RA
		JSR PRBYTE
		LDA #' '
		JSR ECHO

		LDA #'X'
		JSR ECHO
		LDA #'='
		JSR ECHO
		LDA RX
		JSR PRBYTE
		LDA #' '
		JSR ECHO

		LDA #'Y'
		JSR ECHO
		LDA #'='
		JSR ECHO
		LDA RY
		JSR PRBYTE
		LDA #' '
		JSR ECHO

		LDA #'P'
		JSR ECHO
		LDA #'='
		JSR ECHO
		LDA RP
		JSR PRBYTE
		LDA #'='
		JSR ECHO

		LDA RP
		LDX #'-'
		AND #$80
		BEQ NFLAG
		LDX #'N'
NFLAG:	TXA
		JSR ECHO

		LDA RP
		LDX #'-'
		AND #$40
		BEQ VFLAG
		LDX #'V'
VFLAG:	TXA
		JSR ECHO
		
		LDA #'-'
		JSR ECHO

		LDA RP
		LDX #'-'
		AND #$10
		BEQ BFLAG
		LDX #'B'
BFLAG:	TXA
		JSR ECHO

		LDA RP
		LDX #'-'
		AND #$08
		BEQ DFLAG
		LDX #'D'
DFLAG:	TXA
		JSR ECHO

		LDA RP
		LDX #'-'
		AND #$04
		BEQ IFLAG
		LDX #'I'
IFLAG:	TXA
		JSR ECHO

		LDA RP
		LDX #'-'
		AND #$02
		BEQ ZFLAG
		LDX #'Z'
ZFLAG:	TXA
		JSR ECHO

		LDA RP
		LDX #'-'
		AND #$01
		BEQ CFLAG
		LDX #'C'
CFLAG:	TXA
		JSR ECHO

		LDA #$D
		JSR ECHO

		JMP $FF00

; PRINT	LDY #0
; LOOP2	LDA (MSG),Y
; 		INY
; 		CMP #$00
; 		BEQ END
; 		JSR ECHO
; 		JMP LOOP2
; END	RTS
