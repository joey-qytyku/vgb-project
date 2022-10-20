;JMP implicitly uses signed offsets instead of absolute addresses
;which is default for labels

;Operands go in GAS order, just as they do in the encoding
;Its official now, use it
; e.g. AD R0,R1,R0 aka R0+R1->R0


;undef if assign does not work
%assign OP 0

%define R0 0
%define R1 1
%define R2 2
%define R3 3
%define R4 4
%define R5 5
%define R6 6
%define R7 7

%define J_TYPE(op,label)

;[00000|000] [xx|000|000]

%define M_TYPE(op,reg)
%define I_TYPE(op,imm,rd)       DW (op<<11)| (rd<<8) | imm
%define R_TYPE(op,rs1,rs2,rd)   DW (op<<11)| (rs1<<8)| (rs2<<3) | (rd)

%macro halt 0
        DW   0
%endmacro

%macro ldi 2
        I_TYPE(1,%1,%2)
%endmacro

%macro ldm 1
        M_TYPE(2,%1)
%endmacro

%macro stm 1
        M_TYPE(3,%1)
%endmacro

%macro ad 3
        R_TYPE(4,%1,%2,%3)
%endmacro

%macro sb 3
        R_TYPE(5,%1,%2,%3)
%endmacro

%macro shf 3
        R_TYPE(6,%1,%2,%3)
%endmacro

%macro bitor 3
        R_TYPE(7,%1,%2,%3)
%endmacro

%macro bitxor 3
        R_TYPE(8,%1,%2,%3)
%endmacro

%macro bitand 3
        R_TYPE(9,%1,%2,%3)
%endmacro

%macro ldf 0
        I_TYPE(10,0)
%endmacro

;
;Branch instructions
;

%macro b 1
%endmacro


%macro bz 1
%endmacro

;System call, translates to INT 80h
%macro swi 0
        I_TYPE(31,0)
%endmacro

ldi 4,R0
ldi 0,R1
ldm 10,R2
ldi 14,R3
swi
strPtr: DD strMessage
strMessage:
DB "Hello, world",10
