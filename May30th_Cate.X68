*-----------------------------------------------------------
* Title      :  Dissassembler Project
* Written by :  Cate Yochum & Travis Henderson
* Date       : 17/05/30
* Description:
*
* Result from HEXGET is stored in D6.
* Starting address is stored in A7.
* Ending address is stored in A6.
* Working register for comparisons is D7.
* Register that contains address for printing is D6.
*
* THINGS THE PROGRAM DOES SO FAR:
* - Takes a starting address, and ending address, and stores
* them into Address Registers.
* - Can iterate the starting address A7 to be equal to the
* ending address A6.
*-----------------------------------------------------------
TESTCODE

    *ADD.L   D1, -(A4)
    *ADD.W   D5, (A1)+
    *ADD.B   D7, (A6)
    *NOP
    BRA     TEST
    ROR.W   $12
    ROL.W   $12345678
    LSL.W   $1234
    LSR.W   $1234
    BRA     TESTCODE
    BCC     TEST
    BLT     TEST
    BGE     TEST
    LEA     MESSAGE1, A0

    
    JSR TEST
    SIMHALT
    
TEST

    NOP
    RTS
    SIMHALT
  ORG    $1000
START:                  ; first instruction of program

* -------- Begin Program --------
MAIN    
        *LEA     MESSAGE1,A1 *Prompts user for beginning address.
        *MOVE.B  #14,D0      *Displays what's in A1, without CR, and LF.
        *TRAP    #15
        *MOVEA   #0,A1          *May not be necessary, but seems like good housekeeping.      
        *MOVE.W  #2,D0       *Trap task 2 reads a string from input, stores in A1, it's NUL terminated.
        *TRAP    #15
        
        *JSR     HEXGET
        *MOVE.L  D6,A7       *Move starting address to A7.
        
        *Quick Testing---------------------------------------*
        LEA $00, A7

        LEA $40, A6
        JSR PRINTCOUNT
        
ENDA    
        *LEA     MESSAGE2,A1 *Prompts user for ending address.
        *MOVE.B  #14,D0      *Displays what's in A1, without CR, and LF.
        *TRAP    #15
        *MOVEA   #0,A1          *May not be necessary, but seems like good housekeeping      
        *MOVE.W  #2,D0       *Trap task 2 reads a string from input, stores in A1, it's NUL terminated.
        *TRAP    #15
        
        *JSR     HEXGET
        *MOVE.L  D6,A6       *Move ending address into A6.
        
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
        
        
        
        BRA     COMPARE
        
PRINTMORE
        LEA     MESSAGE3,A1 *Ask user if more memory should be printed.
        MOVE.B  #14,D0
        TRAP    #15
        LEA     MESSAGE4,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        CLR     D1
        MOVE.B  #4,D0   *Read user input to see if to continue or end.
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

        CMP.B   SUBI_OP, D5
        BEQ     SUBI_OUT

        CMP.B   LEA_OP, D5
        BEQ     LEA_OUT       
        
        ROR.W   #4, D7      *Restore to orginal order     
        

        
        MOVE.W  ADDA_OP,D5 *See if current output looks like ADDA by using bit mask.
        AND.W   D7,D5
        CMP.W   ADDA_OP,D5
        BEQ     NOP_OUT     *Place holder
        
        MOVE.W  ADD_OP,D5   *mask contents to see if it's ADD.
        AND.W   D7,D5
        CMP.W   ADD_OP,D5
        BEQ     ADDEA       *If so, print accordingly.
        
        BNE     ERROR_OUT        
        BRA     SEARCH
        
CHECKNB
        ROL.W   #8,D7       *Put the data back the way it was, so the LSByte can be compared now.
        LSL.B   #1,D7       *Shift the next two bits to know what exact instruction we're dealing with.
        BCC     ERROR_OUT
        LSL.B   #1,D7
        BCS     ERROR_OUT
        BRA     JSR_OUT     *If it passed all these compares then it is JSR.

* -------- BEGIN OF ADD ---------------------------------------- BEGIN OF ADD ------------------------------ BEGIN OF ADD --------------------------------        
ADDEA
        MOVEA.L #$2,A1  *Begin buffer.
        MOVE.B  #' ',(A1)+
        MOVE.B  #'A',(A1)+
        MOVE.B  #'D',(A1)+
        MOVE.B  #'D',(A1)+
        MOVE.B  #'.',(A1)+

        ROR.W   #6,D7   *Now get the size b/w/l
        CLR     D5      *I'm just always going to clear it before I use it.
        MOVE.B  #$3,D5   *This will be the bitmask to determine the size.
        AND.B   D7,D5
        CMP.B   BYTE,D5 *Is it size byte?
        BEQ     INB
        CMP.B   WORD,D5 *Is it size word?
        BEQ     INW
        CMP.B   LONG,D5
        BNE     ERROR_OUT *If it's not long, it's an error.
        
        MOVE.B  #'L',(A1)+  *If it fails the above comparisons, then it is of size LONG.
        MOVE.B  #' ',(A1)+
        BRA     CONTADD *Branch to continue add.
INB  
        MOVE.B  #'B',(A1)+
        MOVE.B  #' ',(A1)+
        BRA     CONTADD     *Branch to continue add.
INW
        MOVE.B  #'W',(A1)+
        MOVE.B  #' ',(A1)+
        BRA     CONTADD     *Branch to continue add.
CONTADD
        ROL.W   #6,D7   *Return the data to it's original state.
        ROR.W   #8,D7   *Check bit 9 by rolling it out to set/clear the carry flag to determine if Dn + <Ea> -> <Ea> or Dn + <Ea> -> Dn.
        ROR.W   #1,D7
        BCC     DNDEST  *Destination is a Dn, therefore print the register last.
        MOVE.B  #'D',(A1)+  *Otherwise destination is a <Ea>, therefore the data register can be printed first.
        
        
        CLR     D5      *Now I'll begin finding the number of the register.
        MOVE.B  D7,D5
        AND.B   #$7,D5  *Mask D5 so it'll read 0xxx.
        JSR     FINDREGNUMBER   *Get the Register number

        MOVE.B  #',',(A1)+
        
        ROL.W   #8,D7   *Restore data to it's original bit representation.
        ROL.W   #1,D7
        
        ROR.W   #3,D7   *Check the mode of the <EA>, do this first by getting the byte into position.
        
        CLR     D5
        MOVE.B  D7,D5        
        AND.B   #$07,D5 *Check if (xxx).L/W
        CMP.B   #$07,D5
        BEQ     LITADDR
        
        MOVE.L  #$0,D5
        MOVE.B  D7,D5
        AND.B   #$04,D5 *Check if it's -(An)
        CMP.B   #$04,D5
        BEQ     ADDANMINUS
              
        MOVE.L  #$0,D5
        MOVE.B  D7,D5
        AND.B   #$03,D5 *Check if it's (An)+
        CMP.B   #$03,D5
        BEQ     ADDANPLUS
        
        CLR     D5
        MOVE.B  D7,D5
        AND.B   #$02,D5 *Check if it's (An)
        CMP.B   #$02,D5
        BEQ     ADDAN
        
        BRA     ERROR_OUT *It shouldn't make it this far, but if it does, print error.
        
ADDANMINUS
        ROL.W   #3,D7   *Restore data to it's original bit representation.
        
        MOVE.B  #'-',(A1)+
        MOVE.B  #'(',(A1)+
        MOVE.B  #'A',(A1)+
        
        CLR     D5      *Now I'll begin finding the number of the register.
        MOVE.B  D7,D5
        AND.B   #$7,D5  *Mask D5 so it'll read 0xxx.
        JSR     FINDREGNUMBER   *Get the Register number
        
        MOVE.B  #')',(A1)+
        MOVE.B  #$0,(A1)+
        
        MOVEA.L #$2,A1      *Print.
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #$0,(A1)+   *This just allows a newline to be printed.
        MOVEA.L #$2,A1
        MOVE.B  #13,D0
        TRAP    #15
        
        BRA     SEARCH 
ADDANPLUS
        ROL.W   #3,D7   *Restore data to it's original bit representation.
        
        MOVE.B  #'(',(A1)+
        MOVE.B  #'A',(A1)+
        
        CLR     D5      *Now I'll begin finding the number of the register.
        MOVE.B  D7,D5
        AND.B   #$7,D5  *Mask D5 so it'll read 0xxx.
        JSR     FINDREGNUMBER   *Get the Register number
        
        MOVE.B  #')',(A1)+
        MOVE.B  #'+',(A1)+
        MOVE.B  #$0,(A1)+
        
        MOVEA.L #$2,A1      *Print.
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #$0,(A1)+   *This just allows a newline to be printed.
        MOVEA.L #$2,A1
        MOVE.B  #13,D0
        TRAP    #15
        
        BRA     SEARCH        
ADDAN
        ROL.W   #3,D7   *Restore data to it's original bit representation.
        
        MOVE.B  #'(',(A1)+
        MOVE.B  #'A',(A1)+
        
        CLR     D5      *Now I'll begin finding the number of the register.
        MOVE.B  D7,D5
        AND.B   #$7,D5  *Mask D5 so it'll read 0xxx.
        JSR     FINDREGNUMBER   *Get the Register number
        
        MOVE.B  #')',(A1)+
        MOVE.B  #$0,(A1)+
        
        MOVEA.L #$2,A1      *Print.
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.B  #$0,(A1)+   *This just allows a newline to be printed.
        MOVEA.L #$2,A1
        MOVE.B  #13,D0
        TRAP    #15
        
        BRA     SEARCH       
        
LITADDR
        CLR     D5
        MOVE.B  D7,D5
        
        AND.B   #$1,D5  *Check if it's size W
        CMP.B   #$1,D5
        BNE     SHORTADDEA  *Get the short address, otherwise continue for long address.
        
        MOVE.B  #$0,(A1)+  *Null terminate the buffer, and print it..
        MOVEA.L #$2,A1
        MOVE.B  #14,D0 *Trap task 13 will print the NULL terminated string pointed to by (A1).
        TRAP    #15
        
        MOVE.W  (A7)+,D1    *Now print the literal address.
        LSL.L   #8,D1
        LSL.L   #8,D1
        MOVE.W  (A7)+,D1
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        
        MOVE.B  #$0,(A1)+   *This just allows a newline to be printed.
        MOVEA.L #$2,A1
        MOVE.B  #13,D0
        TRAP    #15

        MOVE.L   #0,D1  *Need to clear D1 because CLR does not work, and to rid of LONG address.
        
        BRA     SEARCH
SHORTADDEA
        MOVE.B  #$0,(A1)+  *Empty the buffer.
        MOVEA.L #$2,A1
        MOVE.B  #14,D0 *Trap task 13 will print the NULL terminated string pointed to by (A1).
        TRAP    #15
        
        MOVE.W  (A7)+,D1    *Now print the literal address.
        CLR     D2
        MOVE.B  #16,D2      *This allows printing in base 16.
        MOVE.B  #15,D0      *Displays what's in D1 in base whatever is in D2.
        TRAP    #15
        
        MOVE.B  #$0,(A1)+   *This just allows a newline to be printed.
        MOVEA.L #$2,A1
        MOVE.B  #13,D0
        TRAP    #15
        
        BRA     SEARCH  


DNDEST     

        SIMHALT 
*--------- END OF ADD ------------------------------ END OF ADD ----------------------------- END OF ADD --------------------------   

SUB_OUT

SUBI_OUT

LEA_OUT
        LEA     LEA_STRING, A1
        MOVE.B  #14,D0          *Displays what's in A1
        TRAP    #15
        
                    
        



        ROL.W   #3, D7          
        *RORL.W   #1, D7          *Move register bits to the far right
        CLR     D5
        MOVE.B  NIBBLEMASK, D5
        AND.B   D7, D5          *Get the register bits into D5
        
        LEA     A_STRING, A1    *Displays A for address register
        MOVE.B  #14,D0
        TRAP    #15     
        
        *BRA     FINDREGNUMBER
        

             
        
        BRA SEARCH

*Decodes BCC, BRA, BLT, BGE
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
        *MOVE.B  BYTEMASK, D5     
        
        CMP.B   #$00, D7   *See if the displacement is 00, that tells us it's a word
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
        


*END OF SHIFTING----------------------------------------------------------------------------------------------------------------------* 
   
*---------------- This subroutine puts the correct register number into the buffer ------------------------
FINDREGNUMBER
        CMP.B   #$0,D5
        BEQ     ZERO
        CMP.B   #$1,D5
        BEQ     ONE
        CMP.B   #$2,D5
        BEQ     TWO
        CMP.B   #$3,D5
        BEQ     THREE
        CMP.B   #$4,D5
        BEQ     FOUR
        CMP.B   #$5,D5
        BEQ     FIVE
        CMP.B   #$6,D5
        BEQ     SIX
        
        CMP.B   #$7,D5
        BNE     ERROR_OUT
        MOVE.B  #'7',(A1)+ *If it fails all those tests then it is reg 7.
        RTS
ZERO
        MOVE.B  #'0',(A1)+
        RTS
ONE
        MOVE.B  #'1',(A1)+
        RTS
TWO
        MOVE.B  #'2',(A1)+
        RTS
THREE
        MOVE.B  #'3',(A1)+
        RTS
FOUR
        MOVE.B  #'4',(A1)+
        RTS
FIVE
        MOVE.B  #'5',(A1)+
        RTS
SIX
        MOVE.B  #'6',(A1)+
        RTS
            
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
SBITMASK    DC.B    $003F       *Six bit mask.
        
;SIZES
BYTE    DC.B    $0
WORD    DC.B    $1
LONG    DC.B    $2

;OP CODES

ADDA_OP     DC.W     $D0C0      *Op Code for ADDA
ADD_OP      DC.W     $D000
AND_OP      DC.B     $0C        *Op Code for AND  
BXX_OP      DC.B     $6         *Op Code for branching 
JSR_OP      DC.B     $4E        *First two bytes of JSR
LEA_OP      DC.B     $4
MOVE_OP     DC.B     $0         *Op Code for Move, MoveQ
NOP_OP      DC.W     $4E71
RTS_OP      DC.W     $4E75
SHIFT_OP    DC.B     $E         *LSL, LSR, ASL, ASR, ROL, ROR
SUB_OP      DC.B     $9         *Op Code for SUB   
SUBI_OP     DC.B     $04

;ASSEMBLY OUTPUT
A_STRING        DC.B    ' A',0
ASL_STRING      DC.B    ' ASL',0
ASR_STRING      DC.B    ' ASR',0
BCC_STRING      DC.B    ' BCC',0
BGE_STRING      DC.B    ' BGE',0
BLT_STRING      DC.B    ' BLT',0
BRA_STRING      DC.B    ' BRA',0
BYTE_MODE_STR   DC.B   '.B ',0
JSR_STRING      DC.B    ' JSR',0
LEA_STRING      DC.B    ' LEA',0
LONG_MODE_STR   DC.B    '.L ',0
LSL_STRING      DC.B    ' LSL',0
LSR_STRING      DC.B    ' LSR',0 
NOP_STRING      DC.B    ' NOP',0
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
