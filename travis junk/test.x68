*-----------------------------------------------------------
* Title      :
* Written by : 
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $4000
START:                  ; first instruction of program

* Put program code here
    ADD.L   D1,-(A4)
    ADD.W   D5,(A1)+  
    ADD.B   D7,(A6)    
        
    JSR TEST
    SIMHALT

TEST

    NOP
    RTS
    SIMHALT             ; halt simulator

* Put variables and constants here

    END START ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
