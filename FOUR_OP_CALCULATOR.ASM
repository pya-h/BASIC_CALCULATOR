STACK_SEG SEGMENT STACK
    DW 256 DUP(?)
    STACK_TOP EQU THIS WORD
STACK_SEG ENDS

DATA_SEG SEGMENT
    MSG_TIP DB 0DH, 0AH, '1ST_NUMBER', 09H, '(+,-,/,*)',09H, '2ND_NUMBER', 0DH, 0AH, '$'
    MSG_RESULT DB 09H, '=', 09H, '$'
    MSG_ERROR DB 0DH,0AH, 'ERROR',0DH, 0AH, '$'
    MSG_WITH_REMINDER DB 09H, 'WITH', 09H, '$'
    
DATA_SEG ENDS

CODE_SEG SEGMENT
    ASSUME SS:STACK_SEG, CS:CODE_SEG, DS:DATA_SEG

    MAIN PROC FAR
        MOV SP, OFFSET STACK_TOP
        MOV AX, DATA_SEG
        MOV DS, AX
        MOV ES, AX

        ; ... = ... MESSAGE
        MOV DX, OFFSET MSG_TIP
        MOV AH, 09H
        INT 21H

        ; LOOP COUNTER IS 3 MEANING 3 INPUT 
        MOV CX, 0003H
        MOV SI, 0010D
        MOV BX, 0
        ; THIS PART GETS THE NUMBERS & OPERATOR CHAR BY CHAR AND CONVERTS TO ACTUAL NUMBER
        INPUT_OPERANDS:
            ;MOV DX, OFFSET MESS_ENTER
            ;MOV AH, 09H
            ;INT 21H

            CHECK_KB: ; CHECK IF KEY IS PRESSED
                MOV AH, 01H
                INT 16H
            JZ CHECK_KB

            ;IF PRESSED: READ
            MOV AH, 00H
            INT 16H

            MOV AH, 00H
            MOV ES, AX ;save previoue digits temperory
            
            ; TYPE PRESSED CHARACTER
            MOV AH, 00H
            MOV DX, AX
            MOV AH, 02H
            INT 21H

            ; check if its operator turn:
            CMP CX, 0002H
            JE COMMIT_OPERATOR

            ; PRESSING SPACE COMMITS THE NUMBER
            CMP DX, ' '
            JE COMMIT

            ; PRESSING ENTER ALSO COMMITS
            CMP DX, 000DH
            JE COMMIT_BY_ENTER

            ; GET CHARACTER => BX = 10BX + digit => BX = (D1D2...DNd)
            MOV DX, 0
            MOV AX, BX
            MUL SI
            MOV BX, AX

            ; NOW CONVERT DIGIT CHARACTER TO INTEGER VALUE AND THEN ADD IT TO APPEND IT TO PREVIOUS DIGITS
            MOV AX, ES
            SUB AX, '0'
            ADD BX, AX
            
            MOV DX, BX ;FINAL INPUT IS STORED IN ES

            ; AS LONG AS SPACE OR ENTER ARE NOT PRESSED, THE NUMBER CONTINUES TO BE ENTERED BY USER
            JMP CHECK_KB
            
            ; THIS HAPPENS ON SECOND INPUT AND DETERMINES THE OPERATION TYPE: PLUS/MINUS/DIVIDE/MULTIPLY
            COMMIT_OPERATOR:
                MOV BX, DX
                JMP COMMIT
            COMMIT_BY_ENTER:
                MOV DX, 000AH
                MOV AH, 02H
                INT 21H
            COMMIT: 
                PUSH BX ; PUT BX ON STACK FOR USING LATER
                MOV BX, 0 ; RESET BX FOR NEXT INPUT
                ; PRINT A TAB
                MOV DX, 0009H
                MOV AH, 02H
                INT 21H
        LOOP INPUT_OPERANDS

        ; ... = ... MESSAGE
        MOV DX, OFFSET MSG_RESULT
        MOV AH, 09H
        INT 21H

        ; RESET RESGISTERS & POP ALL DATA THAT HAS BEEN ENTERED BY USER
        MOV DX, 0
        MOV AX, 0
        MOV BX, 0
        MOV SI, 0
        MOV ES, AX

        MOV CX, 0

        POP SI 
        POP BX
        POP AX

        CMP BX, 002BH
            JE PLUS
        CMP BX, 002DH
            JE MINUS
        CMP BX, 002AH
            JE MULTIPLY
        CMP BX, 002FH
            JE DEVIDE

        ;IF OPERATOR IS NONE THEN THERE WAS A MISTAKE
        ; SHOW ERROR MSG
        MOV DX, OFFSET MSG_ERROR
        MOV AH, 09H
        INT 21H
        JMP EXIT

        PLUS: ADD AX, SI
                JMP EXTRACT_DIGITS

        MINUS: SUB AX, SI
                JMP EXTRACT_DIGITS

        MULTIPLY: MUL SI
                JMP EXTRACT_DIGITS

        DEVIDE: DIV SI
                MOV ES, DX ; SAVE REMINDER FOR TEMP
                JMP EXTRACT_DIGITS

        SHOW_REMINDER:
            MOV DX, OFFSET MSG_WITH_REMINDER ; RESET REMINDER TO ASSURE THAT NO REMINDER HAS BEEN LEFT TO PRINT AFTER THIS
            MOV AH, 09H
            INT 21H

            MOV AX, ES
            MOV DX, 0
            MOV CX, 0
            MOV ES, DX
        ; NOW WE EXTRACT THE NUMBER AND PRINT
        EXTRACT_DIGITS: 	
            MOV SI, 10D
            MOV DX, 0
            DIV SI

            ADD DX, '0'
            PUSH DX
            INC CX
            
            CMP AX, 0000H
            JNE EXTRACT_DIGITS

        PRINT_DIGITS:		
            POP DX
            MOV AH, 02H
            INT 21H
            
            LOOP PRINT_DIGITS
        

        ; NOW CHECK IF ES IS ZERO OR NOT, DX BEING NOT ZERO MEANS THAT THE OPERATION IS DIVISION
        MOV DX, ES ;EMINDER WAS SAVED TEMPERORY IN DS
        CMP DX, 0000H
        JNE SHOW_REMINDER

        EXIT: MOV AH, 4CH
        INT 21H
        
    MAIN ENDP
CODE_SEG ENDS

END MAIN