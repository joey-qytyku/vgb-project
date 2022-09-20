# JQ-RISC

## Registers

There are eight accessible registers. There is no zero register.

R0-R4 = Scratch
R5    = Multiply/Divide result
R6    = BP
R7    = SP

## Instruction Encoding

Instructions have predictable encoding and fields are in the same location. Each instruction is 16-bit. There are less than 32.

There are no advanced addressing modes.

Branch targets are always DWORD aligned. All instructions must be at least WORD aligned. Memory access is always DWORD aligned.

Operands follow the intel syntax direction. Bytes are little endian.

R-Type
CCCCCrrr --RRRrrr
I-Type
CCCCCrrr iiiiiiii
J-Type: 10-bit displacement (shifted by 2)
CCCCCxxx jjjjjjjj

LS-Type
CCCCCrrr --------

## Instruction Definitions

LDI, 0, I-Type

ADD
SUB
UML
IML
UDV
IDV

SHF, R-Type, uses 8-bit signed offset
OR,  R-Type
XOR, R-Type
