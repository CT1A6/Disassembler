*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    MOVEA.L #$1234,A1   *Starting adress
    MOVE.B  #'A',(A1)+  *Throw some letters on there.
    MOVE.B  #'B',(A1)+
    MOVE.B  #'C',(A1)+
    MOVE.B  #'D',(A1)+
    MOVE.B  #$0,(A1)+   *NULL terminate the string.
    MOVEA.L #$1234,A1   *Go back to the beginning of the string.
    
    MOVE.B  #13,D0 *Trap task 13 will print the NULL terminated string pointed to by (A1).
    TRAP    #15

    


    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
