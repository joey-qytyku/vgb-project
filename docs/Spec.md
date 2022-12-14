# JQx86

JQx86 is a dynamic recompiler that converts JQ-RISC code into native 32-bit binary in real time. The generated code is not of optimizing C compiler quality, but runs much faster than direct interpretation for programs that do not overuse self-modifying code.

##  Concepts

JQx86 fetches a "block" of instructions, which is 4096 bytes long and in JQ-RISC, contains 2048 instructions (also 64 cache lines). This is stored in a page aligned space for processing.

The recompiling code then converts the code into native code by direct translation to an exact equivalent.

## Decode Process

Decoding is done one-by-one at the moment. I have tried to use MMX/SSE to increase throughput, but there does not seem to be a proper way to do this.

## x86 Instruction Generation

### Registers and Operand Size

This process is simplified by the fact that JQ-RISC can only perform 32-bit memory access to aligned addresses, and all math is done on 32-bit registers. In 32-bit x86, the W-bit indicates if the access is a byte or a dword, rather than a word in 16-bit mode.

x86 orders the encoding different than the logical order. Instead it goes:

```c
enum {
EAX,ECX,EBX,EDX,EDI,ESI,ESP,EBP
};
```


### Branching

Jumps are never generated by the converter, they simply change the virtual PC and force the ExecuteVM function to start executing there.

If there is a conditional jump, the branch is obviously only taken if the condition is true. If the condition is false, flow continues normally.

ExecuteVM does not keep track of condition codes while it is generating code. It is informed by the branch instruction implementor function through register parameter that a branch of the specific type is being requested (carry or zero).

ExecuteVM will execute the block and set the vPC accordingly.

The code that calls the block and handles context save/restore is a callable unit to make this possible alongside non-branching operation.

### Memory Addresses and Indirect Addressing

in IA-32, all registers can be used for memory addressing, but a different encoding is necessary. When any other register is used (or SIB features are used) the SIB byte is also encoded.  The exact complexities do not need to be known, only the following table is needed:
|Hex|Meaning|
-|-
00|[EAX]
01|[ECX]
02|[EDX]
03|[EBX]
06|[ESI]
07|[EDI]
45 00|[EBP+0]
04 24|[ESP]

Note that [EBP+0] encodes an offset while [ESP] does not need to. [ESP] encodes an additional byte because ModRM alone cannot encode ESP.

In the source code, there are functions for assembling instructions with their components: opcode, address, registers.

### Overall Explaination

Because of the entirely 32-bit design of JQ-RISC, shortcuts can be taken so that there is very little conditional branching in the conversion code, and that converter runs as fast as possible. The few instructions implemented in JQ-RISC means that only a fine-tuned subset of x86 needs to be used.

This makes JQx86 completely non-portable to other source architectures.

### Structure

The branch table called by ExecuteVM runs a function that generates the specific instruction with the specified operands.

The generation procedure then calls helper procedures to generate one of the following types of instructions:
* Move immediate to reg
* Move reg to reg
* Move reg to mem
* Move mem to reg
* Compare reg with R/M
* Add/sub/mul/div/idiv/imul reg to reg
* Halt
* INT through SWI

The helper procedure generates that specific type. Most instructions have direct equivalents and the helper function is the dispatch target. In the case of the MOV family, they must by multiplexed so that they can access memory instead of ESP.

Because JQ-RISC instructions can take three register operands, an extra reg-to-reg may need to be generated.

## Source Code

The source code is written in 32-bit assembly for performance. Pipeline-friendly instructions are used:

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
