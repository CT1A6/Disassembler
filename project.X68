*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
* Result from HEXGET is stored in D6.
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* -------- Begin Program --------
MAIN    LEA     MESSAGE1,A1 *Prompts user for beginning address.
        MOVE.B  #14,D0      *Displays what's in A1, without CR, and LF.
        TRAP    #15
        MOVEA   #0,A1          *May not be necessary, but seems like good housekeeping.      
        MOVE.W  #2,D0       *Trap task 2 reads a string from input, stores in A1, it's NUL terminated.
        TRAP    #15
        
        JSR     HEXGET
        MOVE.L  D6,A7       *Move starting address to A7.
        
ENDA    LEA     MESSAGE2,A1 *Prompts user for ending address.
        MOVE.B  #14,D0      *Displays what's in A1, without CR, and LF.
        TRAP    #15
        MOVEA   #0,A1          *May not be necessary, but seems like good housekeeping      
        MOVE.W  #2,D0       *Trap task 2 reads a string from input, stores in A1, it's NUL terminated.
        TRAP    #15
        
        JSR     HEXGET
        MOVE.L  D6,A6       *Move ending address into A6.
        
        SIMHALT       
        
*---- Hex Conversion Routines ----      
HEXGET  CLR     D7          *Clear these registers at the very beginning to avoid any weird stuff.
        CLR     D6
LOOP    MOVE.B  (A1)+,D7    *Get first byte from input so it can be decoded, increment on the address, so the next byte can be read.
        JSR     CONVERT     *Convert ASCII to hex.
        ADD.L   D7,D6       *Add converted value to the hex total/sum.
        CMPI.B  #$0,(A1)    *If zero, then the register is empty.
        BEQ     EXIT        *Exit.
        LSL.L   #$4,D6      *Else shift the converted value over one 16th place.
        BRA     LOOP      *There's more to convert, continue. 
EXIT    RTS        
                
CONVERT  CMP.B   #$39,D7    *Check if byte is in the 0-9 range.
         BLE     ZTHRU9     *If so subtract $30 to get it's hex equivalent.
         CMP.B   #$46,D7    *Check if byte is A-F.
         BLE     ATHRUF     *If so subtract $37 to get it's hex equivalent.
         SUB.B   #$57,D7    *If it's come this far than the input is a-f, get correct hex.
         BRA     RETGET
ZTHRU9   SUB.B   #$30,D7
         BRA     RETGET
ATHRUF   SUB.B   #$37,D7
RETGET   RTS                *Goes back to ADD.L in HEXGET.

    SIMHALT             ; halt simulator

* Put variables and constants here
CR          EQU     $0D
LF          EQU     $0A
MESSAGE1    DC.B    'Enter starting memory address:',CR,LF,0
MESSAGE2    DC.B    'Enter an ending memory address:',CR,LF,0
NOP         EQU     $4E71

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
