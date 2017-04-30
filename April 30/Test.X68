*-----------------------------------------------------------
* Title      :
* Written by : Cate Yochum
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $4000
START:                  ; first instruction of program

* Put program code here
    
    MOVEQ #12, D1
        
        
    JSR TEST
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
