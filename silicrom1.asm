; This is the first SiliconInsider ROM for Apple1

; ENTRY POINTS
; Wozmon (FF00)
; Basic (E000)
; BASIC re-entry (E2B3)

; TEST TOOLS
; Memory test 4k (charger dans 0000 00 05 00 10 00 avant de lancer)
; Memory test 8k (charger dans 0000 00 05 00 20 00 avant de lancer)
; Woz display test 0000 A9 00 AA 20 EF FF E8 8A 4C 02 00

; PROGRAMS
; Lunar Lander
; Code Breaker
; Little Tower
; Typing Tutor
; Microchess
; NIM
; Apple 30th
; Cellular
; Pasart
; Mastermind
; Wozmon in ROM (7F00)

; WWOZMON
; BBASIC
; MMEMORY TEST
; 1APPLE 30TH
; 2LUNAR LANDER
; 3CODE BREAKER
; 4LITTLE TOWER
; 5TYPE TUTOR
; 6MICROCHESS
; 7PASART
; 8CELLULAR
; 9MASTERMIND
; 0NIM

RAM_START = $280

* = $5000

#include "loader.asm"

MENU:
    .byte 01        ; assembly
    .word $FF00, 0, 0
    .byte "WWozMon"
    .byte $0d

    .byte 01        ; assembly
    .word $E000, 0, 0
    .byte "BBasic"
    .byte $0d

    .byte 01        ; assembly
    .word $E2B3, 0, 0
    .byte "CBasic Warm"
    .byte $0d

    .byte 02        ; assembly copy
    .word MEMORY_TEST, MEMORY_TEST_LEN, RAM_START
    .byte "MMemory Test"
    .byte $0d

    .byte 02        ; assembly copy
    .word APPLE30TH, APPLE30TH_LEN, RAM_START
    .byte "1APPLE 30TH"
    .byte $0d

    .byte 02        ; assembly copy
    .word LUNARLANDER, LUNARLANDER_LEN, RAM_START
    .byte "2LUNAR LANDER"
    .byte $0d

    .byte 02        ; assembly copy
    .word CODEBREAKER, CODEBREAKER_LEN, RAM_START
    .byte "3CODE BREAKER"
    .byte $0d

    .byte 02        ; assembly copy
    .word LITTLETOWER, LITTLETOWER_LEN, RAM_START
    .byte "4LITTLE TOWER"
    .byte $0d

    .byte 02        ; assembly copy
    .word TYPINGTUTOR, TYPINGTUTOR_LEN, RAM_START
    .byte "5TYPE TUTOR"
    .byte $0d

    .byte 02        ; assembly copy
    .word MICROCHESS2, MICROCHESS2_LEN, RAM_START
    .byte "6MICROCHESS"
    .byte $0d

    .byte 02        ; assembly copy
    .word PASART, PASART_LEN, RAM_START
    .byte "7PASART"
    .byte $0d

    .byte 02        ; assembly copy
    .word CELLULAR, CELLULAR_LEN, RAM_START
    .byte "8CELLULAR"
    .byte $0d

    .byte 02        ; assembly copy
    .word MASTERMIND, MASTERMIND_LEN, RAM_START
    .byte "9MASTERMIND"
    .byte $0d

    .byte 02        ; assembly copy
    .word NIM, NIM_LEN, RAM_START
    .byte "0NIM"
    .byte $0d

    .byte 00

APPLE30TH:
.bin 0,0,"software/APPLE30TH"
APPLE30TH_LEN = *-APPLE30TH

;   Fills with 0 until $6000
.dsb $6000-*, $00
#include "software/BASIC.inc"

MEMORY_TEST:
#include "software/MEMORYTEST.inc"
MEMORY_TEST_LEN = *-MEMORY_TEST

LUNARLANDER:
#include "software/LUNARLANDER.inc"
LUNARLANDER_LEN = *-LUNARLANDER

CODEBREAKER:
#include "software/CODEBREAKER.REP.inc"
CODEBREAKER_LEN = *-CODEBREAKER

LITTLETOWER:
#include "software/LITTLETOWER.inc"
LITTLETOWER_LEN = *-LITTLETOWER

TYPINGTUTOR:
#include "software/TYPINGTUTOR.inc"
TYPINGTUTOR_LEN = *-TYPINGTUTOR

MICROCHESS2:
#include "software/MICROCHESS2.inc"
MICROCHESS2_LEN = *-MICROCHESS2

PASART:
#include "software/PASART.inc"
PASART_LEN = *-PASART

CELLULAR:
#include "software/CELLULAR.inc"
CELLULAR_LEN = *-CELLULAR

MASTERMIND:
#include "software/MASTERMIND.inc"
MASTERMIND_LEN = *-MASTERMIND

NIM:
#include "software/NIM.04AF.inc"
NIM_LEN = *-NIM

.dsb $cf00-*, $00
#include "software/WOZMON.inc"
