*-----------------------------------------------------------
* Title      : 
* Written by : Cate Yochum & Travis Henderson
* Date       : April 23, 2017
* Description: Test Program for NOP and RTS
               *Step 1: Run this program
               *Step 2: "Open Data" from this S68 within Disassembler
*-----------------------------------------------------------
    ORG    $4000
START:                  ; first instruction of program

* Put program code here
    JSR   TEST
    SIMHALT
    
TEST    
        NOP
        RTS
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
