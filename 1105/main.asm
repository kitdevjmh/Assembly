; =============================================
; 학번 + 이름 출력 프로그램 (MASM, x86 32bit)
; 출력: 2023964059조민혁
; =============================================
.386
.model flat, stdcall
.stack 4096
option casemap:none

includelib kernel32.lib

; ---- Windows API 선언 ----
GetStdHandle  PROTO, nStdHandle:DWORD
WriteConsoleW PROTO, hConsoleOutput:DWORD, lpBuffer:PTR WORD, \
                     nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:PTR DWORD, \
                     lpReserved:DWORD
ExitProcess   PROTO, dwExitCode:DWORD

STD_OUTPUT_HANDLE EQU -11

.data
; 한글이 깨지지 않도록 UTF-16(유니코드) 문자열로 저장
;   조 = C870h, 민 = BBFCh, 혁 = D601h
msg     dw '2','0','2','3','9','6','4','0','5','9'   ; 학번
        dw 0C870h, 0BBFCh, 0D601h                    ; 조민혁
        dw 13, 10                                    ; 줄바꿈 (CR LF)
msgLen  = ($ - msg) / 2                              ; 글자 수
written dd ?

.code
main PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE           ; 콘솔 출력 핸들 얻기
    INVOKE WriteConsoleW, eax, ADDR msg, msgLen, ADDR written, 0
    INVOKE ExitProcess, 0
main ENDP

END main
