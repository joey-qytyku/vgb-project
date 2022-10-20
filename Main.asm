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

        %define SYS_EXIT        1
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

;-------------------------------------------------------------------------------
; Equates
;-------------------------------------------------------------------------------
        JQ.HALT EQU     0
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Linking information
;-------------------------------------------------------------------------------

        global  main
        extern  malloc, free, printf, puts

;-------------------------------------------------------------------------------
        section .bss

alRegBuffer     RESD    8
lProgramCounter RESD    1
pMemory         RESD    1
BytesLeftBlock  RESD    1

bFlags          RESB    1
abStatBuffer    RESB    144
ExecBuffer      RESB    4096

        section .data

strDebugMsg     DB      "Op=%x    Rd=%x    Rs1=%x    Rs2=%x    Imm=%x",10,0
strCopyrightMsg DB      "JQx86",10,"Copyright (c) 2022 Joey Qytyku",0
strStartuperror DB      "Error starting virtual machine",0

;Array of call pointers
afCallTable:
        DD      Conv.LDI

        section .text

;###############################################################################
;############################## Helper functions ###############################
;###############################################################################


Helper.MoveRegToReg:
        call    EncodeR2rModRM
Helper.CmpRegs:

;
;All arithmetic and bitwise instructions are register-to-register
;so the ModRM/Reg direction is not that important.
;
Helper.Addition:
Helper.Subtraction:
Helper.Multiplication:
Helper.Division:

;No need to decode ModRM, reg specified in opcode
;Uses EBP as the register and EDX as the immediate
;
;The MakeIMM procedure must be used to generate the immediate value
;
Helper.MoveImmToReg:
        xor     eax,eax
        mov     al,10111000b
        or      eax,ebp
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
; INPUTS:       EBP=Reg1 (source operand)   EDX=Reg2 (destination operand)
; OUTPUTS:      EAX=Reg-to-reg ModRM byte produced
; CLOBBERS:     EAX, the output code buffer
EncodeR2rModRM:
        mov     eax,edx
        shl     eax,3
        or      eax,ebp
        or      eax,11000000h
        stosb
        ret

;-------------------------------------------------------------------------------
; Procedure: MakeIMM
; In JQ-RISC, the immediate value is made of R1 and R2. The rest of the
; bits are unused for decoding simplicity. This takes the R1 and R2 fields
; and bitwise them together in EAX
;
MakeIMM:
        mov     eax,edx
        shl     eax,3
        or      eax,ebp
        ret

EncodeSIB:
        ret

;###############################################################################
;########################### End of Helper functions ###########################
;###############################################################################


;###############################################################################
;######################## Start of Conversion functions ########################
;###############################################################################
Conv.LDI:
        ;Is the source operand the zero register?
        cmp     ebp,6
        je      .ZeroDestReg

        ;Is the destination ZR? If so, this is a redundand opcode (NOP)
        cmp     edx,6
        jne     .DestNotZR      ;If not, encode the operation

        ;Otherwise encode a nop

        mov     eax,90h
        stosb
        ret
.DestNotZR:

.ZeroDestReg:
        xor     edx,edx
        call    Helper.MoveImmToReg
.RegularMove:
        call    Helper.MoveImmToReg
        ret

Conv.LDM:
        ;Memory access requires generating an MOV with the immediate value
        ;32-bit for optimizations
        ;The base register is also the register where it is written for loads

        ;Last reg operand is the index (ECX)
        mov     eax,[pMemory]
        add     eax,[alRegBuffer+ecx*4]
        mov     eax,[eax]
        ;Now the memory has been "accessed"
        ;Time to write it to the register
        call    Helper.MoveImmToReg     ; How does this work?

Conv.STM:

Conv.AD:
        mov     eax,1   ;80x86 Add reg,modrm
        stosb
        ;Generate a reg+modrm byte

Conv.SB:

Conv.SHF:
        ;but variable shifts are slow, on some processors
        ;the speed is dependent on the shift count
        ;and it requires clobbering CL
        ;This means that encoding an immediate l/r shift is
        ;the only option.


Conv.SHI:

Conv.SWI:
        mov     eax,80CDh
        stosw
        ret

Conv.B:

Conv.HALT:
        ;Encode a jump to routine Termination
        mov     esi,.code
        movsd
        movsd
        ret
.code:
        mov     eax,Termination ; B8 xx xx xx xx
        jmp     eax             ; FF E0
        nop

;###############################################################################
;######################## End of Conversion functions ##########################
;###############################################################################

;###############################################################################
;###################### Start of Main Execution Procedure ######################
;###############################################################################
        align   64
ExecuteVM:
        ;I tried to use SSE/MMX to no avail. The only way I can think of is
        ;to decode instructions one by one

        mov     dword [BytesLeftBlock],4096
.Emit:
        mov     eax,[lProgramCounter]
        movzx   ebx, word [eax]
        mov     ecx,ebx
        mov     edx,ebx
        mov     ebp,ebx

        mov     esi,7
        ;EBX=Opcode
        shr     ebx,3
        and     ebx,esi
        cmp     ebx,JQ.HALT
        jz      .End
        ;ECX=REG1
        shr     ecx,8
        and     ecx,esi
        ;EDX=REG2
        shr     edx,3
        and     edx,esi
        ;EBP=REG3
        and     ebp,esi

        pusha
        push    ebp
        push    edx
        push    ecx
        push    ebx
        push    strDebugMsg
        call    printf
        popa

        ;x86 instructions are no longer than 15 bytes
        ;There has to be space for an extra RET instruction to get back
        ;to ExecuteVM, so the interpreter must execute the block
        ;if there is no more space left for instructions and the RET

        cmp     byte [BytesLeftBlock],16
        jae     .ClearToEmit
        call    RunBlock
.ClearToEmit:
        ;Emit an instruction
        mov     edi,[lProgramCounter]
        call    [ebx*4+afCallTable]
        mov     [lProgramCounter],edi

        ;Was this a branch?
        cmp     eax,-1  ; Branch if carry
        je      .BC
        cmp     eax,-2  ; Branch if zero
        je      .BZ
        cmp     eax,-3  ; Branch unconditionally
        je      .doBranch

        jmp     .dontDoBranch   ; Do not do branch because this is not a Bx op
.BZ:
        cmp     byte [bZeroFlag],1
        je      .doBranch
        jmp     .dontDoBranch
.BC:
        cmp     byte [bCarryFlag],1
        je      .doBranch
.doBranch:
        ;Set the vPC to the branch target so that it runs there
.dontDoBranch:
        ;Its not a branch or was and not taken

        ;BytesLeftBlock = EDI - (ExecBuffer+4096)
        sub     edi,ExecBuffer+4096
                ;BytesLeftBlock = EDI 
        mov     edi,[lProgramCounter]
        sub     edi,ExecBuffer+4096 - (ExecBuffer+4096)

        ;Conversion functions append bytes to the execution buffer using STOS
        ;The program counter always points
        ;to the next byte to insert an instruction (like a normal PC)
        jmp     .Emit

RunBlock:
        ;When running generated x86 code, all registers, including flags
        ;are garaunteed to be clobbered. The only thing that matters
        ;is loading the previous state of the last block so that the
        ;next one can continue where the previous one left off.
        ;So the procedure is to get the last state, run the block
        ;and save the result for later.

        ;Code is generated as long as there are 16 or more bytes left
        ;in the block. If there is not. an instruction is not generated
        ;and .RunBlock takes control

        mov     eax,0C3h        ;Put it in
        stosb                   ;There is space

        mov     ah,[bFlags]
        lahf

        ;Fetch the x86 register state
        mov     ebx,alRegBuffer
        mov     eax,[ebx]
        mov     ecx,[ebx+8]
        mov     edx,[ebx+12]
        mov     esi,[ebx+16]
        mov     edi,[ebx+20]
        mov     ebp,[ebx+24]
        mov     ebx,[ebx+4]

        call    ExecBuffer      ;Run the generated code

        ;Save x86 register state to memory
        ;TODO: optimize this so no abs addresses
        mov     [alRegBuffer+0],eax
        mov     [alRegBuffer+4],ebx
        mov     [alRegBuffer+8],ecx
        mov     [alRegBuffer+12],edx
        mov     [alRegBuffer+16],esi
        mov     [alRegBuffer+20],edi
        mov     [alRegBuffer+24],ebp
        sahf
        mov     byte[bFlags],ah

        ret     ;Block has finished executing, run a new one


;###############################################################################
;###################### End of Main Execution Procedure ########################
;###############################################################################

;-------------------------------------------------------------------------------
; Procedure: Termination
; Exits the program
Termination:
        mov     eax,SYS_EXIT
        xor     ebx,ebx
        int     80h

;-------------------------------------------------------------------------------
; Procedure: main
; argv[1] is the binary to execute
;-------------------------------------------------------------------------------
main:
        cld     ; Clear for entire program

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

        push    eax             ;Save the FD
        push    MEM_SIZE
        call    malloc          ;Allocate the memory
        add     esp,4           ;Clean stack

        test    eax,eax         ; Is result NULL
        je      .StartError

        ;EAX contains pointer to allocated buffer
        ;On the stack is the FD

        ;Read the executable data into the buffer
        mov     ecx,eax         ;Buffer address
        pop     ebx             ;File descriptor
        mov     eax,SYS_READ    ;Syscall
        mov     edx,[abStatBuffer]
        int     80h

        ;Close the file, it is no longer needed
        mov     eax,SYS_OPEN+1
        int     80h

        ;ECX is still return of malloc()

        ;Buffer contains the code to be executed by JQx86
        ;PC initialized to the start of the buffer
        mov     [lProgramCounter],ecx
        mov     [pMemory],ecx

        ;Execute the VM
        call    ExecuteVM

        ;Deallocate memory
.KillMachine:
        push    dword [pMemory]
        call    free
.StartError:
        ;There is no memory to free
        mov     eax,SYS_EXIT
        int     80h
