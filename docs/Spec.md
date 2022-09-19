# JQEM

JQEM is a dynamic recompiler that converts JQ-RISC code into native 32-bit binary in real time. The generated code is not of optimizing C compiler quality, but runs much faster than direct interpretation for programs that do not overuse self-modifying code.

##  Concepts

JQEM fetches a "block" of instructions, which is 4096 bytes long and in JQ-RISC, contains 2048 instructions (also 64 cache lines). This is stored in a page aligned space for processing.

The recompiling code then converts the code into native code by direct translation to an exact equivalent.


## Decode Process

JQ-RISC places all fields in predictable locations. This makes decoding simpler. SSE is used to speed up instruction decoding. The SSE registers store the results of decode operations and pextrw and pextrb are used to put it inside integer registers.

This gives a minor performance increase.

A XMM register is used for the following:
* Opcode
* Reg1
* Reg2
* Reg3

Each are shifted and AND'ed so that each packed word is the necessary field.

## x86 Instruction Generation

### Registers and Operand Size

This process is simplified by the fact that JQ-RISC can only perform 32-bit memory access to aligned addresses, and all math is done on 32-bit registers. In 32-bit x86, the W-bit indicates if the access is a byte or a dword, rather than a word in 16-bit mode.

x86 orders the encoding different than the logical order. Instead it goes:

```c
enum {
EAX,
ECX,
EBX,
EDX,
EDI,
ESI,
ESP,
EBP
};
```

JQ-RISC does not have an architectural stack pointer and simulates this with an ABI defined SP. Register-related instructions can be 1:1 mapped, and the register encoding order is irrelevant.

### Memory Addresses Indirect Addressing

in IA-32, all registers can be used for memory addressing, but a different encoding is necessary.

## Source Code

The source code is written in 32-bit assembly for performance. Pipeline-concious instructions are used:

```
; To increment
add eax,1    ; Good
inc eax      ; Not that bad, but to be safe...

; Load from memory, byte x
movzx eax, byte [x]         ; Good
mov   al, [x]               ; Very bad

; To load 80000000h in EAX
mov al,1h   ; Very bad
shl eax,31  ; and even worse

; Good, easy on the pipeline
mov eax,80000000h
```

Partial register access is totally avoided as this causes the register to be renamed to something different from the expected destination, and there is a penalty.

Reducing code size does not always improve performance. While cache efficiency may be improved, the instructions will run slower if the "bad" choices are made.

## Security

JQ-RISC code is not permitted to access beyond what is allocated initially. Addresses are checked to be in this range.

The stack pointer is never directly accessed. Instructions referencing the stack are virtualized.

