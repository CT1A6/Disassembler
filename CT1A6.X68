*-----------------------------------------------------------
* Title      :  Dissassembler Project
* Written by :  Cate Yochum & Travis Henderson
* Date       :  June 2, 2017
*
*
* Result from HEXGET is stored in D6.
* Starting address is stored in A7.
* Ending address is stored in A6.
* Working register for comparisons is D7.
* Register that contains address for printing is D6.
*
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
        
        *Quick Testing---------------------------------------*
        *LEA $00, A7

        *LEA $4C, A6
        *JSR PRINTCOUNT
        
ENDA    
        LEA     MESSAGE2,A1 *Prompts user for ending address.
        MOVE.B  #14,D0      *Displays what's in A1, without CR, and LF.
        TRAP    #15
        MOVEA   #0,A1          *May not be necessary, but seems like good housekeeping      
        MOVE.W  #2,D0       *Trap task 2 reads a string from input, stores in A1, it's NUL terminated.
        TRAP    #15
        
        JSR     HEXGET
        MOVE.L  D6,A6       *Move ending address into A6.
        
*-------------------------------------- Loop Moves Through Contiguous Memory ----------------------------------------------------
PRINTCOUNT
        MOVE.B  #0,COUNTER       *Resets count for printing.
SEARCH   
        CMP.B   #8,COUNTER       *If we've printed 8 elements, ask the user if they want to see the next 8 elements.
        BEQ     PRINTMORE
        ADD.B   #1,COUNTER  
        CMP.W   A7,A6        *Check if A7 has reached the ending address, A6.
        BEQ     END          *If equal just end program.
        MOVE.W  A7,D6        *This moves the current address into a data register for printing the address to the console.
        MOVE.W  (A7)+,D7    *Move data from current place in memory into D7 for comparison, increments A7 by 2
        
        LEA    NEW_LINE,A1   *Essentially just puts '\n' on the screen.
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        
        BRA     COMPARE
        
PRINTMORE
        LEA     MESSAGE3,A1 *Ask user if more memory should be printed.
        MOVE.B  #14,D0
        TRAP    #15
        LEA     MESSAGE4,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        CLR     D1
        MOVE.B  #4,D0       *Read user input to see if to continue or end.
        TRAP    #15
        CMP.B   #1,D1
        BEQ     PRINTCOUNT
        BRA     END

*-------------------------------------- COMPARE ROUTINES ----------------------------------------------------
COMPARE 
        MOVE.W  D6,D1       *Move the address into D1 for printing.
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        
        CMP.W   #$FFFF,D7   *Bit masking on all one's does not work, so need to check for this condition.
        BEQ     ERROR_OUT
        
        CMP.W   NOP_OP,D7   *see if D7 is NOP machine code
        BEQ     NOP_OUT
        
        CMP.W   RTS_OP,D7   *see if D7 is RTS machine code
        BEQ     RTS_OUT
        
        ROL.W   #8,D7       *Comparison for JSR, to check the MSByte first, a rotation needs to be performed.
        CMP.B   JSR_OP,D7   *see if D7 begins with the opcode for JSR
        BEQ     CHECKNB     *Branch to check next bytes
        CMP.B   SUBI_OP, D7
        BEQ     SUBI_OUT
        ROR.W   #8,D7       *Otherwise restore the data in D7 to how it was before the comparison.
    
        ROL.W   #4,D7       *Rotate so first 4 bits are on the right
        MOVE.B  NIBBLEMASK, D5
        AND.B   D7, D5
        
        CMP.B   SHIFT_OP,D5 *See if the first 4 bits matches the first 4 bits of the Shift Op Codes
        BEQ     SHIFT       *Go to shift subroutine
        
        CMP.B   BXX_OP, D5   
        BEQ     BXX 
        
        CMP.B   SUB_OP, D5
        BEQ     SUB_OUT
        
        CMP.B   #$3, D5    *Word Move or MoveA
        BEQ     MOVE_OUT
        
        CMP.B   #$2,D5     *Long Move or MoveA
        BEQ     MOVE_OUT
        
        CMP.B   #$1, D5    *Byte Move
        BEQ     MOVE_OUT
        
        CMP.B   #$7, D5
        BEQ     MOVEQ_OUT
        
        CMP.B   #$5, D5
        BEQ     ADDQ_OUT
      
        CMP.B   #$D, D5   *Add/Adda
        BEQ     ADD_OUT

        CMP.B   LEA_OP, D5
        BEQ     LEA_OUT  

        CMP.B   OR_DIVU_OP, D5
        BEQ     OR_DIVU_OUT

        CMP.B   AND_MULS_OP, D5
        BEQ     AND_MULS_OUT     
        
        ROR.W   #4, D7      *Restore to orginal order     
        

        
        *MOVE.W  ADDA_OP,D5 *See if current output looks like ADDA by using bit mask.
        *AND.W   D7,D5
        *CMP.W   ADDA_OP,D5
        *BEQ     NOP_OUT     *Place holder
        
        *MOVE.W  ADD_OP,D5   *mask contents to see if it's ADD.
        *AND.W   D7,D5
        *CMP.W   ADD_OP,D5
        *BEQ     ADDEA       *If so, print accordingly.
        

        BNE     ERROR_OUT        
        BRA     SEARCH
        
CHECKNB
        ROL.W   #8,D7       *Put the data back the way it was, so the LSByte can be compared now.
        LSL.B   #1,D7       *Shift the next two bits to know what exact instruction we're dealing with.
        BCC     ERROR_OUT
        LSL.B   #1,D7
        BCS     ERROR_OUT
        BRA     JSR_OUT     *If it passed all these compares then it is JSR.


**PRE-CONDITION: MODE BITS SHOULD BE IN D4, REG BITS IN D5, OPCODE SHOULD BE IN ORIGINAL ORDER IN D7**
EA_MODES

    CMP.B   #$0, D4
    BEQ     DATA_REG
    
    CMP.B   #$1, D4
    BEQ     ADDRESS_DIRECT
    
    CMP.B   #$2, D4
    BEQ     ADDRESS_INDIRECT
    
    CMP.B   #$3, D4
    BEQ     INCREMENT
    
    CMP.B   #$4, D4
    BEQ     DECREMENT
    
    CMP.B   #$7, D4
    BEQ     ABSOLUTE_IMMEDIATE
    BNE     ERROR_OUT

    
    RTS
DATA_REG

    LEA     D_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
        
    MOVE.W  D5,D1    
    CLR     D2
    MOVE.B  #16,D2      *This allows printing in base 16.
    MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
    TRAP    #15    
        
    RTS

ADDRESS_INDIRECT

    LEA     PAREN_L_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    LEA     A_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    MOVE.W  D5,D1    
    CLR     D2
    MOVE.B  #16,D2      *This allows printing in base 16.
    MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
    TRAP    #15  
    
    LEA     PAREN_R_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
  
        
    RTS
INCREMENT
    LEA     PAREN_L_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    LEA     A_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    MOVE.W  D5,D1    
    CLR     D2
    MOVE.B  #16,D2      *This allows printing in base 16.
    MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
    TRAP    #15  
    
    LEA     PAREN_R_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    LEA     PLUS_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    RTS
DECREMENT
    LEA     MINUS_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    LEA     PAREN_L_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    LEA     A_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    
    MOVE.W  D5,D1    
    CLR     D2
    MOVE.B  #16,D2      *This allows printing in base 16.
    MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
    TRAP    #15  
    
    LEA     PAREN_R_STRING, A1
    MOVE.B  #14,D0          *Displays what's in A1
    TRAP    #15
    RTS
ABSOLUTE_IMMEDIATE
    CMP.B   #$0, D5
    BEQ     ABS_WORD
    CMP.B   #$1, D5
    BEQ     ABS_LONG
    CMP.B   #$4, D5
    BEQ     IMMEDIATE_DATA
ABS_WORD
    RTS
ABS_LONG
    RTS
IMMEDIATE_DATA
    RTS
ADDRESS_DIRECT
        LEA     A_STRING, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        
        MOVE.W  D5,D1    
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15    
        
        RTS


 
SIZE *Method determines .B/W/L
        CMP.B   #0,D5
        BEQ     BSIZE
        CMP.B   #1,D5
        BEQ     WSIZE
        CMP.B   #2,D5
        BNE     ERROR_OUT   *If it's not equal to anything, then it's the wrong size.
        
        MOVE.B  #'L',(A1)+
RETURN1
        LEA     LEA_STRING, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        *MOVE.B  #' ',(A1)+
        *RTS
BSIZE
        *MOVE.B  #'B',(A1)+
        LEA     BYTE_MODE_STR, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        BRA     RETURN1
WSIZE   
        *MOVE.B  #'W',(A1)+
        LEA     WORD_MODE_STR, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        BRA     RETURN1

*---------------------- SUB BEGIN ----------------------------------------------------
SUB_OUT

        LEA     SUB_STRING, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        
        ROL.W   #6,D7   *opmode to the right
        BRA     OPMODE
        
        BRA SEARCH

*---------------------------- BEGIN SUBI ------------------------------------------------
SUBI_OUT
        LEA     SUBI_STRING, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        
        BRA SEARCH

*---------------------------- END SUBI ------------------------------------------------

LEA_OUT
        ROL.W   #6, D7
        CLR     D5
        MOVE.B  THREE_BIT_MASK, D5
        AND.B   D7, D5
        CMP.B   #$7, D5      *Make sure this is LEA, and not some other opcode that starts with 4
        BNE     ERROR_OUT

        
        LEA     LEA_STRING, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15        
        
        ROL.W   #3, D7   *EA mode to the right
        CLR     D4
        MOVE.B  THREE_BIT_MASK,D4
        AND.B   D7,D4 
        
        ROL.W   #3, D7   *EA reg to the right
        CLR     D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7,D5
        JSR     EA_MODES

          
        *ROL.W   #3, D7          
                *Move register bits to the far right
        *CLR     D5
        *MOVE.B  NIBBLEMASK, D5
        *AND.B   D7, D5          *Get the register bits into D5
       
        LEA     COMMA_STRING, A1    *Displays A for address register
        MOVE.B  #14,D0
        TRAP    #15  
 
        LEA     A_STRING, A1    *Displays A for address register
        MOVE.B  #14,D0
        TRAP    #15   

        *MOVE.W  D5,D1    
        *CLR     D2
        *MOVE.B  #16,D2      *This allows printing in base 16.
        *MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        *TRAP    #15  
 
          
        
        BRA SEARCH

MOVE_OUT
        ROL.W   #6, D7   *Get bits 8,7,6 to the far right
        CLR     D5
        MOVE.B  THREE_BIT_MASK, D5
        AND.B   D7, D5
        CMP.B   #$1,D5
        BEQ     MOVEA_OUT
        
        **MOVE_OUT**
        LEA     MOVE_STRING,A1
        MOVE.B  #14, D0
        TRAP #15
        
        ROR.W   #6,D7
        CLR D5
        MOVE.B  TWO_BIT_MASK,D5
        AND.B   D7,D5
        CMP.B   #1,D5
        BEQ     MOVE_BYTE
        CMP.B   #2,D5
        BEQ     MOVE_LONG
        CMP.B   #3,D5
        BEQ     MOVE_WORD
        
MOVE_BYTE
        LEA     BYTE_MODE_STR,A1
        MOVE.B  #14, D0
        TRAP #15
        BRA MOVE_SOURCE
MOVE_LONG
        LEA     LONG_MODE_STR,A1
        MOVE.B  #14, D0
        TRAP #15
        BRA MOVE_SOURCE

MOVE_WORD
        LEA     WORD_MODE_STR,A1
        MOVE.B  #14, D0
        TRAP #15
MOVE_SOURCE 
        ROR.W   #4, D7      *Source Reg bits to the right
        CLR D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7, D5
        
        ROR.W   #3,D7  *Source mode bits to the right
        CLR     D4
        MOVE.B  THREE_BIT_MASK,D4
        AND.B   D7, D4
        
        ROL.W   #3,D7   *Put back in order
        JSR     EA_MODES
MOVE_DEST

        LEA     COMMA_STRING,A1   
        MOVE.B  #14, D0
        TRAP #15
        
        ROR.W   #6, D7      *Dest mode bits to the right
        CLR D5
        MOVE.B  THREE_BIT_MASK,D4
        AND.B   D7, D4
        
        ROR.W   #3,D7  *Dest reg bits to the right
        CLR     D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7, D5
        
        ROL.W   #3,D7   *Put back in order
        JSR     EA_MODES

        BRA SEARCH      
 *MOVEA----------------------------------------------* 
MOVEA_OUT
        LEA     MOVEA_STRING,A1
        MOVE.B  #14, D0
        TRAP #15
        
        ROR.W #6,D7  *Get size code to the right
        CLR D5
        MOVE.B  TWO_BIT_MASK, D5
        AND.B   D7, D5
        CMP.B   #3,D5
        BEQ     MOVEA_WORD
        
        CMP.B   #2,D5
        BEQ     MOVEA_LONG
        BNE     ERROR_OUT
        
MOVEA_WORD
        LEA     WORD_MODE_STR,A1
        MOVE.B  #14, D0
        TRAP    #15
        BRA     MOVEA_SOURCE
MOVEA_LONG
        LEA     LONG_MODE_STR,A1
        MOVE.B  #14, D0
        TRAP    #15
MOVEA_SOURCE
        ROR.W   #4, D7      *Source Reg bits to the right
        CLR D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7, D5
        
        ROR.W   #3,D7  *Source mode bits to the right
        CLR     D4
        MOVE.B  THREE_BIT_MASK,D4
        AND.B   D7, D4
        
        ROL.W   #3,D7   *Put back in order
        JSR     EA_MODES
MOVEA_DEST    

        LEA     COMMA_STRING,A1   
        MOVE.B  #14, D0
        TRAP #15
    
        LEA     A_STRING,A1   
        MOVE.B  #14, D0
        TRAP #15
        
                
        ROR.W   #8,D7    *Get the destination register (bits 11,10,9) to the right
        ROR.W   #1,D7
        CLR D5
        MOVE.B  THREE_BIT_MASK, D5
        AND.B   D7, D5
        
        MOVE.W  D5,D1    
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        

        BRA SEARCH

MOVEQ_OUT
        LEA     MOVEQ_STRING,A1
        MOVE.B  #14, D0
        TRAP #15
        
        ROR.W   #4, D7  *Move D7 back to original order so the data is on the right
        CLR     D5
        MOVE.B  BYTEMASK, D5
        AND.B   D7, D5   *Get the immediate data in D5
        
        MOVE.W  D5,D1    
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        
        LEA     COMMA_STRING,A1
        MOVE.B  #14, D0
        TRAP #15
        
        ROR.W   #8, D7
        ROR.W   #1, D7
        CLR D5
        MOVE.B  THREE_BIT_MASK, D5
        AND.B   D7,D5               *Gets the reg number into D5
        
        LEA     D_STRING,A1
        MOVE.B  #14, D0
        TRAP #15       

        MOVE.W  D5,D1    
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        

 

        BRA SEARCH        
OR_DIVU_OUT
        ROL.W   #6, D7 *Get bits 8,7,6 to the far right
        CLR  D5
        MOVE.B  THREE_BIT_MASK, D5
        AND.B   D7, D5
        CMP.B   #$3, D5
        BEQ     DIVU_OUT
OR_OUT
        ROR.W   #6, D7
        LEA     OR_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        
        ROL.W   #6,D7   *OPMODE/SIZE TO THE RIGHT

*PRE-CONDTION HAVE THE OPMODE BITS TO THE RIGHT*
OPMODE
        CLR     D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7,D5
        CMP.B   #$0,D5
        BEQ     OR_BYTE_A
        CMP.B   #$1,D5
        BEQ     OR_WORD_A
        CMP.B   #$2,D5
        BEQ     OR_LONG_A
        CMP.B   #$4,D5
        BEQ     OR_BYTE_B
        CMP.B   #$5,D5
        BEQ     OR_WORD_B
        CMP.B   #$6,D5
        BEQ     OR_LONG_B
        
OR_BYTE_A
        LEA     BYTE_MODE_STR, A1
        MOVE.B  #14, D0
        TRAP    #15 
        
        BRA     A_ORDER
OR_WORD_A  
        LEA     WORD_MODE_STR, A1
        MOVE.B  #14, D0
        TRAP    #15 
        BRA     A_ORDER
OR_LONG_A  
        LEA     LONG_MODE_STR, A1
        MOVE.B  #14, D0
        TRAP    #15    
        BRA     A_ORDER
OR_BYTE_B 
        LEA     BYTE_MODE_STR, A1
        MOVE.B  #14, D0
        TRAP    #15 
        BRA     B_ORDER
OR_WORD_B 
        LEA     WORD_MODE_STR, A1
        MOVE.B  #14, D0
        TRAP    #15  
        BRA     B_ORDER
OR_LONG_B  
        LEA     LONG_MODE_STR, A1
        MOVE.B  #14, D0
        TRAP    #15 
        BRA     B_ORDER   
A_ORDER
        ROL.W   #3,D7 *EA MODE RIGHT
        CLR D4
        MOVE.B  THREE_BIT_MASK,D4
        AND.B   D7,D4
        
        
        ROL.W  #3,D7 *EA REG RIGHT 
        CLR D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7,D5
        
        
        JSR     EA_MODES
        
        LEA     COMMA_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15 
        
        
        
        LEA     D_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        
        ROL.W   #7,D7   *get Dreg bits
        CLR D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7,D5
        
        MOVE.W  D5,D1    
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15         
   
        BRA     SEARCH
B_ORDER
        LEA     D_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        
        ROR.W   #3,D7   *get Dreg bits
        CLR D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7,D5
        
        MOVE.W  D5,D1    
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15         
   

        ROL.W   #6,D7 *EA MODE RIGHT
        CLR D4
        MOVE.B  THREE_BIT_MASK,D4
        AND.B   D7,D4
        
        
        ROL.W  #3,D7 *EA REG RIGHT 
        CLR D5
        MOVE.B  THREE_BIT_MASK,D5
        AND.B   D7,D5
        
        LEA     COMMA_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15 
                
        JSR     EA_MODES
             
        

        BRA     SEARCH
*---------------------------------------------------------------------------------------*        
DIVU_OUT
        LEA     DIVU_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        BRA     SEARCH
      
AND_MULS_OUT
        ROL.W   #6, D7 *Get bits 8,7,6 to the far right
        CLR  D5
        MOVE.B  THREE_BIT_MASK, D5
        AND.B   D7, D5
        CMP.B   #$7, D5
        BEQ     MULS_OUT
AND_OUT 
        LEA     AND_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        BRA     OPMODE
        BRA     SEARCH
               
        
MULS_OUT  
        LEA     MULS_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        BRA     SEARCH      


*Decodes BCC, BRA, BLT, BGE------------------------------------------------------------------------------------------------------------*
BXX
        ROL.W   #4,D7       *Rotate D7 left 4 to get the second 4 bits, the condition code (It was rotated so that 6 is to the far right)
        CLR     D5
        MOVE.B  NIBBLEMASK, D5
        AND.B   D7,D5
        CMP.B   #$0,D5      *BRA has 0 condition code
        BEQ     BRA_OUT
        CMP.B   #$4,d5      *BCC has 4 condition code 
        BEQ     BCC_OUT
        CMP.B   #$C,D5      *BGE has C condition code
        BEQ     BGE_OUT
        CMP.B   #$D,D5      *BLT has D condition code
        BEQ     BLT_OUT
        
        BRA     ERROR_OUT        
BRA_OUT
        LEA     BRA_STRING, A1
        MOVE.B  #14,D0
        TRAP    #15
        
        BRA     BXX_DISPLACEMENT
BCC_OUT
        LEA     BCC_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        
        BRA     BXX_DISPLACEMENT

BGE_OUT
        LEA     BGE_STRING,A1
        MOVE.B  #14, D0
        TRAP    #15 
        
        BRA     BXX_DISPLACEMENT

BLT_OUT
        LEA     BLT_STRING, A1
        MOVE.B  #14, D0
        TRAP    #15
        
        BRA     BXX_DISPLACEMENT
        
BXX_DISPLACEMENT
        ROR.W   #8, D7    *Put the op code back in original order
        CLR     D5
        MOVE.B  BYTEMASK, D5     
        
        CMP.B   #$00, D5   *See if the displacement is 00, that tells us it's a word
        BEQ     BXX_WORD
        
        *If it's not a word, it's a byte*              
BXX_BYTE        
        CLR     D5
        MOVE.B  D7, D5
        NOT.B   D5          *Get the two's complement of the 8 bit displacement  
        
        *SUB  
        MOVE.W  D5,D1    
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        
        MOVE.B  #$0,(A1)+   *This just allows a newline to be printed.
        MOVEA.L #$2,A1
        MOVE.B  #13,D0
        TRAP    #15
        BRA     SEARCH   
        

BXX_WORD
        
        MOVE.W  (A7)+,D1    *Now print the literal address.
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        
        MOVE.B  #$0,(A1)+   *This just allows a newline to be printed.
        MOVEA.L #$2,A1
        MOVE.B  #13,D0
        TRAP    #15
        
        BRA SEARCH
        
*END OF BXX -----------------------------------------------------------------------------------------------------------------------*

*Decodes LSL, LSR, ASL, ASR, ROL, and ROR------------------------------------------------------------------------------------------*
SHIFT
   
        ROL.W   #4,D7  *Rotate D7 left 4 to get the second 4 bits (It was rotated so that E is to the far right)
        CLR     D5
     
        MOVE.B  NIBBLEMASK, D5
        AND.B   D7,D5
        CMP.B   #$6,D5  
        BEQ     MEM_ROR_OUT *If equal, the opcode starts with E6, so it is a memory ROR
        CMP.B   #$7,D5 
        BEQ     MEM_ROL_OUT *If equal, the opcode starts with E7, so it is a memory ROL
        CMP.B   #$3, D5 
        BEQ     MEM_LSL_OUT *If equal, the opcode starts with E3, so it is a memory LSL
        CMP.B   #$2, D5 
        BEQ     MEM_LSR_OUT *If equal, the opcode starts with E2, so it is a memory LSR
        CMP.B   #0, D5
        BEQ     MEM_ASR_OUT *If equal, the opcode starts with E0, so it is a memory ASR
        CMP.B   #1, D5
        BEQ     MEM_ASL_OUT *If equal, the opcode starts with E1, so it is a memory ASL
        

        BRA SEARCH 
MEM_ROL_OUT
        LEA ROL_STRING, A1
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
      
        
        
        BRA    W_OR_L
        *BRA     LITADDR
MEM_ROR_OUT
        LEA ROR_STRING, A1
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        
        BRA     W_OR_L
        *BRA     LITADDR
MEM_LSL_OUT
        LEA     LSL_STRING, A1
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15

        BRA    W_OR_L
        *BRA     LITADDR
MEM_LSR_OUT
        LEA     LSR_STRING, A1
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        
        BRA    W_OR_L
        *BRA LITADDR
MEM_ASL_OUT
        LEA     ASL_STRING, A1
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        
        BRA    W_OR_L
        *BRA     LITADDR
MEM_ASR_OUT
        LEA     ASR_STRING, A1
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15

        BRA    W_OR_L
        *BRA     LITADDR
W_OR_L
        ROR.W   #8, D7     *Rotate back to the original order of the opcode*
        CLR     D5
        MOVE.B  NIBBLEMASK, D5
        AND.B   D7,D5
        CMP.B   #$8, D5    *If the register bits are 000, the word will be 1000, so it is a .W
        BEQ     WORD_OUT
        CMP.B   #$9, D5    *If the register bits are 001, the words will be 1001, so it is a .L 
        BEQ     LONG_OUT
        
WORD_OUT
        LEA     WORD_MODE_STR, A1
        MOVE.B  #14, D0
        TRAP    #15
        
        MOVE.W (A7)+, D7    *Move the next word from memory into D7
        
        *LEA     D7, A1
        *MOVE.B  #14, D0
        *TRAP    #15
        
        LEA    NEW_LINE,A1   *Essentially just puts '\n' on the screen.
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        
        BRA     SEARCH

LONG_OUT
        LEA     LONG_MODE_STR, A1
        MOVE.B  #14, D0
        
        MOVE.L  (A7)+, D7    *Move the next long from memory into D7
        
        LEA    NEW_LINE,A1   *Essentially just puts '\n' on the screen.
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        
        BRA     SEARCH
        
*Was trying to do this very last minute, didn't have time to finish*
REG_SHIFT
        ROR.W   #7,D7    *Get bits 3 and 4
        CLR     D5
        MOVE.B  TWO_BIT_MASK,D5
        AND.B   D7,D5
        CMP.B   #$0,D5   *Artithmetic
        BEQ     ASD
        CMP.B   #$1,D5  *Logical
        BEQ     LSD
        CMP.B   #$3,D5  *Rotate
        BEQ     ROD
ASD
        LEA    ASD_STRING,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        JSR DIRECTION
        BRA SEARCH
LSD
        LEA    LSD_STRING,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        JSR DIRECTION
        BRA SEARCH
ROD
        LEA    ROD_STRING,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        JSR DIRECTION
        BRA SEARCH
DIRECTION
        ROR.W   #5,D7
        CLR     D5
        MOVE.B  ONE_BIT_MASK,D5
        CMP.B   #$0,D5
        BEQ     RIGHT_OUT
        CMP.B   #$1,D5
        BEQ     LEFT_OUT
RIGHT_OUT
        LEA    RIGHT,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        RTS

LEFT_OUT
        LEA    LEFT,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        RTS


*END OF SHIFTING----------------------------------------------------------------------------------------------------------------------* 

ADDQ_OUT
        LEA    ADDQ_STRING,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        
        LEA    POUND_STRING,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        BRA     SEARCH
        
ADD_OUT
        LEA    ADD_STRING,A1   
        MOVE.B #14,D0        *Displays what's in A1
        TRAP   #15
        
        ROL.W   #6,D7   *OPMODE RIGHT
        BRA     OPMODE
        *LEA    D_STRING,A1   
        *MOVE.B #14,D0        *Displays what's in A1
        *TRAP   #15
        
        *ROL.W   #3,D7   *reg# to the right
        *CLR D5
        *MOVE.B  THREE_BIT_MASK,D5
        *AND.B   D7,D5
        
        *MOVE.W  D5,D1    
        *CLR     D2
        *MOVE.B  #16,D2      *This allows printing in base 16.
        *MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        *TRAP    #15
        
        *LEA    COMMA_STRING,A1   
        *MOVE.B #14,D0        *Displays what's in A1
        *TRAP   #15
        
        **ROL.W   #6,D7    *EA MODE
        *CLR     D4
        *MOVE.B  THREE_BIT_MASK,D4
        *AND.B   D7,D4
        
        *ROL.W   #3,D7    *EA REG
        *CLR     D5
        *MOVE.B  THREE_BIT_MASK,D5
        *AND.B   D7,D4
        
        *JSR EA_MODES
        
        

        BRA     SEARCH


            
*---------------------------------------------------------------------------------------------------------------------
*                                   OUTPUT ROUTINES
*---------------------------------------------------------------------------------------------------------------------
*--------------------------------------- NOP PRINTING ----------------------------------------------------
NOP_OUT
        LEA     NOP_STRING,A1 *outputs "NOP"
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        BRA     SEARCH
        
*--------------------------------------- RTS PRINTING ----------------------------------------------------
RTS_OUT
        LEA     RTS_STRING,A1 *outputs "RTS"
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        BRA     SEARCH
        
*--------------------------------------- JSR PRINTING ----------------------------------------------------
JSR_OUT       
        LEA     JSR_STRING,A1 *outputs "JSR"
        MOVE.B  #14,D0        *Displays what's in A1
        TRAP    #15
        BRA     MODE          *Need to find mode, and reg now for this instruction.
MODE
        LSL.B   #1,D7       *This sub routine should determine the mode, but as it is now, it will only find (xxx) as a mode.
        BCC     ERROR_OUT
        LSL.B   #1,D7
        BCC     ERROR_OUT
        LSL.B   #1,D7
        BRA     XXXWL       *If it passes all these tests, then it is an address mode, this probably needs to be fixed, though, once more modes are implemented.
        
XXXWL
        LSL.B   #1,D7       *This subroutine determines if (xxx) is either long or word.
        BCS     ERROR_OUT
        LSL.B   #1,D7
        BCS     ERROR_OUT
        LSL.B   #1,D7
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

*---------------------------------------  UNRECOGNIZED PRINT OUT ----------------------------------------------------
ERROR_OUT
        LEA     ERROR_STRING,A1 *outputs the string as specified by the assignment.
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        BRA     SEARCH    
        

END     SIMHALT  

  
        
*----------------------------------------------------------------------------------------------------------------------
*                                           Hex Conversion Routines 
*----------------------------------------------------------------------------------------------------------------------
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

*----------------------------------------------------------------------------------------------------------------------
*                                           CONSTANTS
*----------------------------------------------------------------------------------------------------------------------

* MESSAGES/VARIABLES
CR          EQU     $0D
LF          EQU     $0A
MESSAGE1    DC.B    'Enter starting memory address:',CR,LF,0
MESSAGE2    DC.B    'Enter an ending memory address:',CR,LF,0
MESSAGE3    DC.B    'Press 1 to see more memory',CR,LF,0
MESSAGE4    DC.B    'Press 0 to exit',CR,LF,0
TESTM       DC.B    'TEST',CR,LF,0
BYTEMASK    DC.B    $00FF
COUNTER     DC.B    0
NIBBLEMASK  DC.B    $000F
ONE_BIT_MASK DC.B   $1
SBITMASK    DC.B    $003F       *Six bit mask
TWO_BIT_MASK    DC.B    $0003
THREE_BIT_MASK  DC.B    $0007
        
;SIZES
BYTE    DC.B    $0
WORD    DC.B    $1
LONG    DC.B    $2

;OP CODES

ADDA_OP     DC.W     $D0C0      *Op Code for ADDA
ADD_OP      DC.W     $D000
AND_OP      DC.B     $0C        *Op Code for AND 
AND_MULS_OP DC.B     $C 
BXX_OP      DC.B     $6         *Op Code for branching 
JSR_OP      DC.B     $4E        *First two bytes of JSR
LEA_OP      DC.B     $4
MOVE_OP     DC.B     $0         *Op Code for Move, 


NOP_OP      DC.W     $4E71
OR_DIVU_OP  DC.B     $8     
RTS_OP      DC.W     $4E75
SHIFT_OP    DC.B     $E         *LSL, LSR, ASL, ASR, ROL, ROR
SUB_OP      DC.B     $9         *Op Code for SUB   
SUBI_OP     DC.B     $04

;ASSEMBLY OUTPUT
A_STRING        DC.B    ' A',0
ADD_STRING      DC.B    ' ADD',0
ADDQ_STRING     DC.B    ' ADDQ',0
AND_STRING      DC.B    ' AND',0
ASL_STRING      DC.B    ' ASL',0
ASD_STRING             DC.B    'AS',0
ASR_STRING      DC.B    ' ASR',0
BCC_STRING      DC.B    ' BCC',0
BGE_STRING      DC.B    ' BGE',0
BLT_STRING      DC.B    ' BLT',0
BRA_STRING      DC.B    ' BRA',0
BYTE_MODE_STR   DC.B    '.B ',0
COMMA_STRING    DC.B    ', ',0
D_STRING        DC.B    ' D',0
DIVU_STRING     DC.B    ' DIVU',0
JSR_STRING      DC.B    ' JSR',0
LEA_STRING      DC.B    ' LEA',0
LEFT            DC.B    'L',0
LONG_MODE_STR   DC.B    '.L ',0
LSD_STRING             DC.B    'LS',0
LSL_STRING      DC.B    ' LSL',0
LSR_STRING      DC.B    ' LSR',0
MINUS_STRING    DC.B    '-',0
MULS_STRING     DC.B    ' MULS',0
MOVE_STRING     DC.B    ' MOVE',0
MOVEA_STRING    DC.B    ' MOVEA',0
MOVEQ_STRING    DC.B    ' MOVEQ #',0
MOVEM_STRING    DC.B    ' MOVEM',0
NOP_STRING      DC.B    ' NOP',0
OR_STRING       DC.B    ' OR',0
PAREN_L_STRING  DC.B    '(',0
PAREN_R_STRING  DC.B    ')',0
POUND_STRING    DC.B    ' #',0
PLUS_STRING     DC.B    '+',0
RIGHT           DC.B    'R',0
ROD_STRING             DC.B    'RO',0
ROL_STRING      DC.B    ' ROL',0
ROR_STRING      DC.B    ' ROR',0
RTS_STRING      DC.B    ' RTS',CR,LF,0
SUB_STRING      DC.B    ' SUB',0
SUBI_STRING     DC.B    ' SUBI',0
WORD_MODE_STR   DC.B    '.W ',0

ERROR_STRING    DC.B    ' DATA $WXYZ',CR,LF,0
NEW_LINE        DC.B    CR,LF,0



    END START ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
