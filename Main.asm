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

%endmacro

        %define SYS_READ        3
        %define SYS_OPEN        5
        %define SYS_STAT        0x12
        %define O_CREAT         00000100
        %define O_TRUNC         00001000
        %define O_RDONLY        00000000
        %define STAT_SIZE       48
        %define MEM_SIZE        65536

        ;Single byte opcodes using ModRM/Reg to encode RegOps
        %define X86.MOV_R2R    89h
        %define X86.MOV_M2R    8Bh

        bits    32
        global  main
        extern  malloc, free, printf, puts

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
lVirtualESP:
        RESD    1
pMemory:
        RESD    1

        section .data

strCopyrightMsg:
        DB      "JQx86",10,"Copyright (c) 2022 Joey Qytyku",0

strStartuperror:
        DB      "Error starting virtual machine",0

;Array of call pointers
afCallTable:

        section .text

;No need to decode ModRM, reg specified in opcod

Helper.MoveImmToReg:
        xor     eax,eax
        mov     al,10111000b
        or      eax,ecx
        stosb
        mov     eax,edx
        shl     eax,3
        or      eax,ebp
        stosd
        ret

;-------------------------------------------------------------------------------
; Procedure EncodeR2rModRM:
;       Generate a ModRM byte to represent a register-to-register operation
;
;       A reg-to-reg ModRM byte looks like this
;       11rrrRRR, where 11 indicates register addressing
;       and rrr+RRR are the two register operands.
;
; INPUTS:
;       EBP=Reg1 (source operand)
;       EDX=Reg2 (destination operand)
; OUTPUTS:
;       EAX=Reg-to-reg ModRM byte produced
; CLOBBERS:
;       EAX, the output code buffer
EncodeR2rModRM:
        mov     eax,edx
        shl     eax,3
        or      eax,ebp
        or      eax,11000000h
        stosb
        ret

;-------------------------------------------------------------------------------
; Procedure EncodeR2mModRM
;       Generate the Mod/RM + SIB sequence for a specific memory addressing mode
;       Supports [EAX], [EBX], [ECX], [EDX], [ESI], [EDI], [EBP]
;
; INPUTS:
;       EBP=Register to use as address (RegOp 1)
; OUTPUTS:
;       EAX = -1 if using stack pointer as the address
EncodeSIB:
        cmp     ebp,6           ;Is it the stack pointer?
        je      .StackPointer

        cmp     ebp,7           ;Is it the base pointer?
        je      .BasePointer

        ;If normal register, encode the exact RegOp number
        mov     eax,ebp
        stosb
        ret
.StackPointer:
        ;Access to the stack pointer is faked. JQ-RISC does not have an
        ;architectural SP and must be able to use it as a scratch reg
        ;Using ESP as an address requires saving an x86 register that is not the
        ;target operand (increment and bit-AND always works),
        ;writing the address there and then performing the whole memory access

.BasePointer:
        ;Using [R6], or in x86, [EBP] requires an extra 8-bit signed offset
        ;In this emulator, it will always be zero because advanced addressing
        ;modes are not supported in JQ-RISC
        xor     eax,eax
        stosb
        ret


;
;Procedure to generate memory access (in case of ESP)
;and procedure for reg access?
;

Helper.MoveRegToReg:
        call    EncodeR2rModRM
Helper.CmpRegs:
Helper.Halt:

;
;All arithmetic and bitwise instructions are register-to-register
;so the ModRM/Reg direction is not that important.
;
Helper.Addition:
Helper.Subtraction:
Helper.Multiplication:
Helper.Division:

;-------------------------------------------------------------------------------
; Procedure: ExecuteVM
; Converts JQ-RISC code into native x86 binary
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

%define VREG_ANDVAL esi

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
        and     ebp,VREG_ANDVALproject

%undef VREG_ANDVAL

        mov     edi,[lProgramCounter]
        call    [ebx*4+afCallTable]
        mov     [lProgramCounter],edi
        ;Increment PC by one?
        ret

;-------------------------------------------------------------------------------
; Procedure: main
; argv[1] is the binary to execute
;-------------------------------------------------------------------------------
main:
        cld     ; Clear for entire program

        push    strCopyrightMsg
        call    puts
        add     esp,4

        mov eax,1
        mov ebx,1
        int 80h

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
        mov     [pMemory],ecx          ;Memorize buffer, PC changes

        ;Execute the VM

        ;Deallocate memory
.KillMachine:
        push    dword [pMemory]
        call    free
.StartError:
        ;There is no memory to free
        mov     eax,1
        int     80h
