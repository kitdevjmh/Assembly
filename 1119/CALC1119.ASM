;==============================================================
; CALC_REG.ASM
; 두 개의 숫자를 입력받아 사칙연산(+, -, *, /)을 수행하고,
; 연산이 모두 끝난 직후의 AX, BX, CX, DX 레지스터 내용을 출력
;
; 어셈블 (MASM) : MASM CALC_REG.ASM;  ->  LINK CALC_REG.OBJ;
; 어셈블 (TASM) : TASM CALC_REG.ASM   ->  TLINK CALC_REG.OBJ
; 실행           : CALC_REG  (DOS / DOSBox / EMU8086)
;
; 입력 범위 : 0 ~ 65535 (부호 없는 16비트 10진수)
;==============================================================

.MODEL SMALL
.STACK 100h

;--------------------------------------------------------------
; 문자열 출력 매크로 ($로 끝나는 문자열)
;--------------------------------------------------------------
PRINT MACRO MSG
        PUSH AX
        PUSH DX
        LEA  DX, MSG
        MOV  AH, 09h
        INT  21h
        POP  DX
        POP  AX
ENDM

.DATA
MSG_IN1   DB 'Input first number  (0~65535) : $'
MSG_IN2   DB 13,10,'Input second number (0~65535) : $'

MSG_ADD   DB 13,10,13,10,'A + B = $'
MSG_SUB   DB 13,10,'A - B = $'
MSG_MUL   DB 13,10,'A * B = $'
MSG_DIV   DB 13,10,'A / B = $'
MSG_REM   DB ' ... remainder $'
MSG_DIV0  DB 'Error: divide by zero$'

MSG_REG   DB 13,10,13,10,'[Registers after arithmetic]$'
MSG_AX    DB 13,10,'AX = $'
MSG_BX    DB 13,10,'BX = $'
MSG_CX    DB 13,10,'CX = $'
MSG_DX    DB 13,10,'DX = $'
MSG_H     DB 'h  ($'
MSG_RP    DB ')$'
MSG_MINUS DB '-$'
MSG_CRLF  DB 13,10,'$'

NUM1      DW ?            ; 첫 번째 수 (A)
NUM2      DW ?            ; 두 번째 수 (B)

SUM_L     DW ?            ; 덧셈 결과 (32비트: SUM_H:SUM_L)
SUM_H     DW ?
DIFF      DW ?            ; 뺄셈 결과의 절댓값
DIFF_NEG  DB 0            ; 1이면 음수
PROD_L    DW ?            ; 곱셈 결과 (32비트: PROD_H:PROD_L)
PROD_H    DW ?
QUOT      DW ?            ; 몫
REMD      DW ?            ; 나머지
DIV_ERR   DB 0            ; 1이면 0으로 나누기

R_AX      DW ?            ; 연산 직후 레지스터 저장 공간
R_BX      DW ?
R_CX      DW ?
R_DX      DW ?

.CODE
MAIN PROC
        MOV  AX, @DATA
        MOV  DS, AX

        ;----------------- 숫자 입력 -----------------
        PRINT MSG_IN1
        CALL READ_NUM           ; AX <- 입력값
        MOV  NUM1, AX

        PRINT MSG_IN2
        CALL READ_NUM
        MOV  NUM2, AX

        ;----------------- 사칙연산 ------------------
        MOV  CX, NUM1           ; CX = A
        MOV  BX, NUM2           ; BX = B

        ; 덧셈 : DX:AX = A + B (자리올림 포함)
        MOV  AX, CX
        XOR  DX, DX
        ADD  AX, BX
        ADC  DX, 0
        MOV  SUM_L, AX
        MOV  SUM_H, DX

        ; 뺄셈 : A - B (음수면 절댓값 + 부호 표시)
        MOV  AX, CX
        SUB  AX, BX
        JNC  SUB_OK
        NEG  AX
        MOV  DIFF_NEG, 1
SUB_OK:
        MOV  DIFF, AX

        ; 곱셈 : DX:AX = A * B
        MOV  AX, CX
        MUL  BX
        MOV  PROD_L, AX
        MOV  PROD_H, DX

        ; 나눗셈 : AX = 몫, DX = 나머지
        CMP  BX, 0
        JNE  DO_DIV
        MOV  DIV_ERR, 1
        JMP  SAVE_REGS
DO_DIV:
        MOV  AX, CX
        XOR  DX, DX
        DIV  BX
        MOV  QUOT, AX
        MOV  REMD, DX

        ;---- 연산이 끝난 직후의 레지스터 값 저장 ----
        ; (이후 출력 루틴이 레지스터를 바꾸므로 먼저 보관)
SAVE_REGS:
        MOV  R_AX, AX
        MOV  R_BX, BX
        MOV  R_CX, CX
        MOV  R_DX, DX

        ;----------------- 결과 출력 -----------------
        PRINT MSG_ADD
        MOV  AX, SUM_L
        MOV  DX, SUM_H
        CALL PRINT_U32

        PRINT MSG_SUB
        CMP  DIFF_NEG, 0
        JE   SUB_PRINT
        PRINT MSG_MINUS
SUB_PRINT:
        MOV  AX, DIFF
        XOR  DX, DX
        CALL PRINT_U32

        PRINT MSG_MUL
        MOV  AX, PROD_L
        MOV  DX, PROD_H
        CALL PRINT_U32

        PRINT MSG_DIV
        CMP  DIV_ERR, 0
        JE   DIV_PRINT
        PRINT MSG_DIV0
        JMP  REG_PRINT
DIV_PRINT:
        MOV  AX, QUOT
        XOR  DX, DX
        CALL PRINT_U32
        PRINT MSG_REM
        MOV  AX, REMD
        XOR  DX, DX
        CALL PRINT_U32

        ;------------- 레지스터 내용 출력 ------------
REG_PRINT:
        PRINT MSG_REG

        PRINT MSG_AX
        MOV  AX, R_AX
        CALL PRINT_REG

        PRINT MSG_BX
        MOV  AX, R_BX
        CALL PRINT_REG

        PRINT MSG_CX
        MOV  AX, R_CX
        CALL PRINT_REG

        PRINT MSG_DX
        MOV  AX, R_DX
        CALL PRINT_REG

        PRINT MSG_CRLF

        ; 프로그램 종료
        MOV  AX, 4C00h
        INT  21h
MAIN ENDP

;--------------------------------------------------------------
; READ_NUM : 키보드로 10진수를 입력받아 AX에 반환 (Enter로 종료)
;            숫자가 아닌 문자는 무시
;--------------------------------------------------------------
READ_NUM PROC
        PUSH BX
        PUSH CX
        PUSH DX
        XOR  BX, BX             ; 누적값 = 0
RN_LOOP:
        MOV  AH, 01h            ; 한 글자 입력 (에코)
        INT  21h
        CMP  AL, 13             ; Enter?
        JE   RN_DONE
        CMP  AL, '0'
        JB   RN_LOOP
        CMP  AL, '9'
        JA   RN_LOOP
        SUB  AL, '0'
        MOV  CL, AL
        XOR  CH, CH             ; CX = 이번 자릿수
        MOV  AX, BX
        MOV  DX, 10
        MUL  DX                 ; AX = 누적값 * 10
        ADD  AX, CX
        MOV  BX, AX
        JMP  RN_LOOP
RN_DONE:
        MOV  AX, BX
        POP  DX
        POP  CX
        POP  BX
        RET
READ_NUM ENDP

;--------------------------------------------------------------
; PRINT_U32 : DX:AX 의 32비트 부호 없는 정수를 10진수로 출력
;--------------------------------------------------------------
PRINT_U32 PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH SI
        PUSH DI
        MOV  SI, 10
        XOR  CX, CX             ; 자릿수 카운터
PU_DIV:
        MOV  DI, AX             ; 하위 워드 보관
        MOV  AX, DX
        XOR  DX, DX
        DIV  SI                 ; 상위 워드 / 10
        MOV  BX, AX             ; 상위 몫
        MOV  AX, DI
        DIV  SI                 ; (나머지:하위 워드) / 10
        PUSH DX                 ; 나머지 = 한 자리 숫자
        INC  CX
        MOV  DX, BX             ; DX:AX = 새 몫
        OR   BX, AX             ; 몫이 0이면 종료
        JNZ  PU_DIV
PU_OUT:
        POP  DX
        ADD  DL, '0'
        MOV  AH, 02h
        INT  21h
        LOOP PU_OUT
        POP  DI
        POP  SI
        POP  DX
        POP  CX
        POP  BX
        POP  AX
        RET
PRINT_U32 ENDP

;--------------------------------------------------------------
; PRINT_HEX16 : AX 값을 16진수 4자리로 출력
;--------------------------------------------------------------
PRINT_HEX16 PROC
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        MOV  BX, AX
        MOV  CX, 4
PH_LOOP:
        PUSH CX
        MOV  CL, 4
        ROL  BX, CL             ; 최상위 4비트를 맨 아래로
        POP  CX
        MOV  DL, BL
        AND  DL, 0Fh
        ADD  DL, '0'
        CMP  DL, '9'
        JBE  PH_OUT
        ADD  DL, 7              ; 'A'~'F'
PH_OUT:
        MOV  AH, 02h
        INT  21h
        LOOP PH_LOOP
        POP  DX
        POP  CX
        POP  BX
        POP  AX
        RET
PRINT_HEX16 ENDP

;--------------------------------------------------------------
; PRINT_REG : AX 값을 "XXXXh  (10진수)" 형식으로 출력
;--------------------------------------------------------------
PRINT_REG PROC
        PUSH AX
        PUSH DX
        CALL PRINT_HEX16
        PRINT MSG_H
        XOR  DX, DX
        CALL PRINT_U32
        PRINT MSG_RP
        POP  DX
        POP  AX
        RET
PRINT_REG ENDP

END MAIN
