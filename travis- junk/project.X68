*-----------------------------------------------------------
* Title      :  Dissassmbler Project
* Written by :  Cate Yochum & Travis Henderson
* Date       : 17/04/22
* Description:
*
* Result from HEXGET is stored in D6.
* Starting address is stored in A7.
* Ending address is stored in A6.
*
* THINGS THE PROGRAM DOES SO FAR:
* - Takes a starting address, and ending address, and stores
* them into Address Registers.
* - Can iterate the starting address A7 to be equal to the
* ending address A6.
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
        
*----- Loop Moves Through Contiguous Memory -----  
        *MOVE.W  NOP,$3010  *For testing, I just wanted to see if SEARCH could find
        *MOVE.W  NOP,D1     * NOP at a given address, it cannot.
SEARCH  CMP.W   A7,A6       *Check if A7 has reached the ending address, A6.
        BEQ     END         *If equal just end program.
        *JSR     FIND       *JSR causes the program to crash, why?
        ADDA.W  #$1,A7
        BRA     SEARCH

FIND    MOVE.W  NOP,D1  *Move variable into data register for comparison.
        CMP.W   (A7),D1 *Is value pointed to equal to NOP?
        BEQ     PRINT   *If so, print NOP.
RET     RTS
        
PRINT   LEA     PTNOP,A1    *Prints NOP.
        MOVE.B  #14,D0
        TRAP    #15
        BRA     RET
        
END     SIMHALT       
        
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
NOP         DC.W     $4E71
PTNOP       DC.B    'NOP',CR,LF,0

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
