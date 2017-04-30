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
MAIN    
        LEA     MESSAGE1,A1 *Prompts user for beginning address.
        MOVE.B  #14,D0      *Displays what's in A1, without CR, and LF.
        TRAP    #15
        MOVEA   #0,A1          *May not be necessary, but seems like good housekeeping.      
        MOVE.W  #2,D0       *Trap task 2 reads a string from input, stores in A1, it's NUL terminated.
        TRAP    #15
        
        JSR     HEXGET
        MOVE.L  D6,A7       *Move starting address to A7.
        
ENDA    
        LEA     MESSAGE2,A1 *Prompts user for ending address.
        MOVE.B  #14,D0      *Displays what's in A1, without CR, and LF.
        TRAP    #15
        MOVEA   #0,A1          *May not be necessary, but seems like good housekeeping      
        MOVE.W  #2,D0       *Trap task 2 reads a string from input, stores in A1, it's NUL terminated.
        TRAP    #15
        
        JSR     HEXGET
        MOVE.L  D6,A6       *Move ending address into A6.
        
*----- Loop Moves Through Contiguous Memory -----    
SEARCH      
        CMP.W   A7,A6        *Check if A7 has reached the ending address, A6.
        BEQ     END          *If equal just end program.
        
        MOVE.W  (A7)+, D2    *Move data from current place in memory into D2 for comparison, increments A7 by 2
        
        CMP.W   NOP_OP, D2   *see if D2 is NOP machine code
        BEQ     NOP_OUT
        
        CMP.W   RTS_OP, D2   *see if D2 is RTS machine code
        BEQ     RTS_OUT
        
        ROL.W   #8,D2       *To check the MSByte first, a rotation needs to be performed.
        CMP.B   JSR_OP,D2   *see if D2 begins with the opcode for JSR
        BEQ     CHECKNB     *Branch to check next bytes
        
        *CMP.B   SUBI_OP, D2
        *BEQ    SUBI_ROUTINE
        *CMP.B  BRA_OP, D2
        *BEQ    BRA_ROUTINE
        
        ROL.W   #8,D2       *Otherwise restore the data in D2 to how it was before the comparison.
        

        MOVE.W  D2,D3       *Copy D2 to D3
        ASR.W   #8,D3      *shift D3 right 12 times so that it is now just the first nybble of D2
        ASR.W   #4,D3
        *ASR.W   #4,D3
        
        CMP.B   #$7,D3      *See if first nybble is 7, the first nybble of MOVEQ
        BEQ     MOVEQ_OUT   
        
        *Skeleton for Op_Code "switch"**********
        *CMP.B   ADD_OP, D3
        *BEQ    ADD_ROUTINE
        *CMP.B   AND_OP, D3
        *BEQ    AND_ROUTINE
        *CMP.B  MOVE_OP,D3
        *BEQ    MOVE_ROUTINE
        *CMP.B  SHIFT_OP,D3
        *BEQ    SHIFT_ROUTINE
        *CMP.B  SUB_OP,D3
        *BEQ    SUB_ROUTINE
        
        
        BNE     ERROR_OUT        
        BRA     SEARCH
NOP_OUT
        LEA     NOP_STRING,A1 *outputs "NOP"
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        BRA     SEARCH
RTS_OUT
        LEA     RTS_STRING,A1 *outputs "RTS"
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        BRA     SEARCH
JSR_OUT
        LEA     JSR_STRING,A1 *outputs "JSR"
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        BRA     MODE          *Need to find mode, and reg now for this instruction.
ERROR_OUT
        LEA     ERROR_STRING,A1 *outputs "Not implemented yet"
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        BRA     SEARCH    
END     SIMHALT  

MOVEQ_OUT
*MOVEQ#<DATA>,Dn

        LEA      MOVEQ_STRING,A1    *Outputs "MOVEQ"
        MOVE.B   #14, D0
        TRAP     #15
        
        LEA     POUND,A1
        MOVE.B  #14, D0
        TRAP    #15

        MOVE.B   D2,D1              *Output <data> (last byte of the op code)
        MOVE.B   #3,D0
        TRAP     #15

        CLR     D3
        MOVE.W  D2,D3    *Copy D2 to D3
        
        
        
        ASL.W   #4,D3   *Overwrite the 4 bits (0111) to the left of the register code
     
        *shift the 3 register bits to the end so it's now 0000 0000 0000 0XXX     
        ASR.W   #4,D3
        ASR.W   #4,D3
        ASR.W   #4,D3
        ASR.W   #1,D3
        
        LEA     COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        LEA     D_REG,A1        *outputs "D"
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        
        MOVE.L D3, D1         *Outputs the register number
        MOVE.B #3, D0
        TRAP   #15
        
        
        BRA LOOP

CHECKNB
        ROL.W   #8,D2       *Put the data back the way it was, so the LSByte can be compared now.
        LSL.B   #1,D2       *Shift the next two bits to know what exact instruction we're dealing with.
        BCC     ERROR_OUT
        LSL.B   #1,D2
        BCS     ERROR_OUT
        BRA     JSR_OUT     *If it passed all these compares then it is JSR.

MODE
        LSL.B   #1,D2       *This sub routine should determine the mode, but as it is now, it will only find (xxx) as a mode.
        BCC     ERROR_OUT
        LSL.B   #1,D2
        BCC     ERROR_OUT
        LSL.B   #1,D2
        BRA     XXXWL       *If it passes all these tests, then it is an address mode, this probably needs to be fixed, though, once more modes are implemented.
        
XXXWL
        LSL.B   #1,D2       *This subroutine determines if (xxx) is either long or word.
        BCS     ERROR_OUT
        LSL.B   #1,D2
        BCS     ERROR_OUT
        LSL.B   #1,D2
        BCC     WORDADDR    *Branch to find the word address
        BRA     LONGADDR    *Otherwise find the long address
WORDADDR      
        BRA     ERROR_OUT   *Not implemented yet, but will need to print the next 2 bytes in memory.
LONGADDR
         MOVE.W (A7)+,D1    *This subroutine prints the long address of for a (xxx).L mode.
         CLR    D2
         MOVE.B #16,D2      *For the trap task, putting 16 in D2 prints what's in D1 in base 16.
         MOVE.B #15,D0      *Trap task 15 displays D1 in base whatever is in D2.
         TRAP   #15
         MOVE.W (A7),D1     *No need to increment again, that will happen in SEARCH.
         MOVE.B #15,D0      *Trap task 15 displays D1 in base whatever is in D2.
         TRAP   #15
         LEA    NEW_LINE,A1   *Essentially just puts '\n' on the screen.
         MOVE.B #14,D0        *Displays what's in A1
         TRAP   #15
         BRA    SEARCH   
        
*---- Hex Conversion Routines ----      
HEXGET  
        CLR     D7          *Clear these registers at the very beginning to avoid any weird stuff.
        CLR     D6
LOOP    
        MOVE.B  (A1)+,D7    *Get first byte from input so it can be decoded, increment on the address, so the next byte can be read.
        JSR     CONVERT     *Convert ASCII to hex.
        ADD.L   D7,D6       *Add converted value to the hex total/sum.
        CMPI.B  #$0,(A1)    *If zero, then the register is empty.
        BEQ     EXIT        *Exit.
        LSL.L   #$4,D6      *Else shift the converted value over one 16th place.
        BRA     LOOP      *There's more to convert, continue. 
EXIT    
        RTS        
                
CONVERT  
         CMP.B   #$39,D7    *Check if byte is in the 0-9 range.
         BLE     ZTHRU9     *If so subtract $30 to get it's hex equivalent.
         CMP.B   #$46,D7    *Check if byte is A-F.
         BLE     ATHRUF     *If so subtract $37 to get it's hex equivalent.
         SUB.B   #$57,D7    *If it's come this far than the input is a-f, get correct hex.
         BRA     RETGET
ZTHRU9   
         SUB.B   #$30,D7
         BRA     RETGET
ATHRUF   
         SUB.B   #$37,D7
RETGET   
         RTS                *Goes back to ADD.L in HEXGET.

    SIMHALT             ; halt simulator

* Put variables and constants here
CR          EQU     $0D
LF          EQU     $0
COMMA       DC.B    ', ',0
D_REG       DC.B    'D',0
MESSAGE1    DC.B    'Enter starting memory address:',CR,LF,0
MESSAGE2    DC.B    'Enter an ending memory address:',CR,LF,0
POUND       DC.B    '#',0


;OP CODES

ADD_OP      DC.B     $D     *Op Code for ADD, ADDA, but NOT ADDI and ADDQ
AND_OP      DC.B     $C     *Op Code for AND
BRA_OP      DC.B     $60    *Op Code for branching 
JSR_OP      DC.B     $4E    *First two bytes of JSR
*MOVE_OP     DC.B     $0     *Op Code for Move, MoveQ
NOP_OP      DC.W     $4E71
RTS_OP      DC.W     $4E75
SHIFT_OP    DC.B     $E     *LSL, LSR, ASL, ASR, ROL, ROR
SUB_OP      DC.B     $9     *Op Code for SUB   
SUBI_OP     DC.B     $04
LEA_OP      DC.B     $4

;ASSEMBLY OUTPUT


MOVEQ_STRING    DC.B    'MOVEQ  ',0 
NOP_STRING      DC.B    'NOP',CR,LF,0
RTS_STRING      DC.B    'RTS',CR,LF,0
JSR_STRING      DC.B    'JSR ',0
ERROR_STRING    DC.B    'Not implemented yet',CR,LF,0
NEW_LINE        DC.B    CR,LF,0

    END START ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
