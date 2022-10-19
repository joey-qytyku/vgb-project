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

%define M_TYPE(op,reg)

%define I_TYPE(op,imm,rd)       DW (op<<11)| (rd<<8) | imm
%define R_TYPE(op,rs1,rs2,rd)   DW (op<<11)| (rs1<<8)| (rs2<<3) | (rd)

%macro halt 0
        DW   0
%endmacro

%assign OP OP+1
%macro ldi 2
        I_TYPE(OP,%1,%2)
%endmacro

%assign OP OP+1
%macro ldm 1
        M_TYPE(OP,%1)
%endmacro

%assign OP OP+1
%macro stm 1
        M_TYPE(OP,%1)
%endmacro

%assign OP OP+1
%macro ad 3
        R_TYPE(OP,%1,%2,%3)
%endmacro

%assign OP OP+1
%macro sb 3
        R_TYPE(OP,%1,%2,%3)
%endmacro

%assign OP OP+1
%macro shf 3
        R_TYPE(OP,%1,%2,%3)
%endmacro

%assign OP OP+1
%macro bitor 3
        R_TYPE(OP,%1,%2,%3)
%endmacro

%assign OP OP+1
%macro bitxor 3
        R_TYPE(OP,%1,%2,%3)
%endmacro

%assign OP OP+1
%macro bitand 3
        R_TYPE(OP,%1,%2,%3)
%endmacro

%assign OP OP+1
%macro ldf 0
        I_TYPE(OP,0)
%endmacro

;
;Branch instructions
;

%assign OP OP+1
%macro b 1
%endmacro


%assign OP OP+1
%macro bz 1
%endmacro

;System call, translates to INT 80h
%assign OP OP+1
%macro swi 0

%endmacro

ad 0,1,2
