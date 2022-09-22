;Copyright (c) 2022 Joey Qytyku

;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:

;The above copyright notice and this permission notice shall be included in all
;copies or substantial portions of the Software.

;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;SOFTWARE.


        %define SYS_READ        3
        %define SYS_OPEN        5
        %define SYS_STAT        0x12
        %define O_CREAT         00000100
        %define O_TRUNC         00001000
        %define O_RDONLY        00000000
        %define STAT_SIZE       48
        %define MEM_SIZE        65536

        bits    32
        global  _start
        extern  malloc

        section .bss

;When translated x86 instructions are done executing
;they must exit back to the VM procedure
;
alRegBuffer:
        RESD    8

abStatBuffer:
        RESB    144

lProgramCounter:
        RESD    1

        section .data

strCopyrightMsg:
        DB      "JQx86",10,"Copyright (c) 2022 Joey Qytyku",0

strStartuperror:
        DB      "Error starting virtual machine",0

;Array of call pointers
afCallTable:

        section .text

;-------------------------------------------------------------------------------
; Procedure: MkComponent.Reg
; The stack pointer is never accessed directly because that is dangerous.
;
MkComponent.Reg:

;-------------------------------------------------------------------------------
; Procedure: MkComponent.Addr
; Creates an address relative to the execution buffer
; If there is an overflow, execution halts with error
; Modifies:
;       The program counter
;
MkComponent.Addr:

SourceOp.LDI:


;-------------------------------------------------------------------------------
; Procedure: ExecuteVM
; Converts JQ-RISC code into native x86 binary
;
;
        align   64
ExecuteVM:
        ;I tried to use SSE/MMX to no avail. The only way I can think of is
        ;to decode instructions one by one
        mov     eax,[lProgramCounter]
        movzx   ebx, word [eax]
        mov     ecx,ebx
        mov     edx,ebx
        mov     ebp,ebx

        mov     esi,7

        ;EBX=Opcode
        shr     ebx,3
        and     ebx,esi

        ;ECX=REG3
        shr     ecx,8
        and     ecx,esi

        ;EDX=REG2
        shr     edx,3
        and     edx,VREG_ANDVAL

        ;EBP=REG1
        and     ebp,VREG_ANDVAL

        call    [ebx*4+afCallTable]
        ret

;-------------------------------------------------------------------------------
; _start
; argv[1] is the binary to execute
;-------------------------------------------------------------------------------
_start:
        push    strCopyrightMsg
        call    puts
        add     esp,4

        cmp     dword [esp+4],1
        jb      .StartError

        mov     ebx,[esp+8]
        mov     ebx,[ebx+4]     ; Get argv[1] in EBX

        ;Open the executable flat binary
        mov     eax,SYS_OPEN
        mov     ecx,O_RDONLY
        mov     edx,777q
        int     80h
        ;EAX is the file descriptor, if -1, failed
        cmp     eax,-1
        je      .StartError

        push    eax                             ;Save the FD
        push    MEM_SIZE
        call    malloc                          ;Allocate the memory
        add     esp,4                           ;Clean stack

        test    eax,eax         ; Is result NULL
        je      .StartError

        ;EAX contains pointer to allocated buffer
        ;On the stack is the FD

        mov     ecx,eax         ;Buffer address
        pop     ebx             ;File descriptor
        mov     eax,SYS_READ    ;Syscall
        mov     edx,[abStatBuffer+STAT_SIZE]
        int     80h

        ;Close the file, it is no longer needed
        mov     eax,SYS_OPEN+1
        int     80h

        ;Buffer contains the code to be executed by JQx86
        mov     [lProgramCounter],ecx
        mov     [MemoryPtr],ecx         ;Memorize buffer, PC changes

        ;Execute the VM

        ;Deallocate memory
.KillMachine:
        push    [MemoryPtr]
        call    free
.StartError:
        ;There is no memory to free
        mov     eax,1
        int     80h
