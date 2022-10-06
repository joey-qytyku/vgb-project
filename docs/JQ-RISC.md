# JQ-RISC

## Registers

There are eight accessible registers.
|Rx|Significance|
-|-
R0 | Scratch
R1 | Scratch
R2 | Scratch
R3 | Scratch
R4 | Scratch
R5 | Scratch
R6 | Zero
R7 | Scratch

The flags are internal. It has a carry and zero.

## Instruction Encoding

Instructions have predictable encoding and fields are in the same location. Each instruction is 16-bit. There are less than 32.

There are no advanced addressing modes.

Operands follow the AT&T syntax direction. Bytes are little endian.

I-Type opcodes use only 6-bit immediates. This for decoding simplicity.

Features present:
* Shift by contant using signed offset

Features not present:
* Hardware division and multiplication
* Unaligned memory access
* Access to words and bytes
* Branch to unaligned address (32-bit align)
* Reg-to-reg mov
  * Add/sub with zero register and store result
* Comparison
  * Subtract and store result in zero

Moving from R2R can be done by simply adding the register with the zero register and saving the result to the destination. Comparisons can be done by subtracting two registers and saving the result in the zero register

```
R-Type
CCCCCrrr --RRRrrr

I-Type
CCCCCrrr --iiiiii

J-Type: 8-bit displacement (shifted by 2)
CCCCCxxx --jjjjj

LS-Type (Load/Store)
CCCCCrrr --------
```
## Instruction Definitions
```
HALT
LDI, I-Type

LDM, LS
STM, LS

AD, R-Type
SB, R-Type

SHF, R-Type, uses 8-bit normalized signed offset
SHI, I-Type

BITOR,  R-Type
BITXOR, R-Type

BITAND, R-Type

LDF, Load flags to register

BGR
BLS

B, J, unconditional branch
BZ, J, just check the inverse lol

```