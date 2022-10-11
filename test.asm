
;JMP implicitly uses signed offsets instead of absolute addresses
;which is default for labels

%define J_TYPE(op, off)

%define M_TYPE(op, reg)

%define I_TYPE(op,imm)

%define R_TYPE()

%imacro halt
%end

%imacro ldi
%end

%imacro ldm
%end

%imacro stm
%end

%imacro ad
%end

%imacro sb
%end

%imacro shf
%end

%imacro shi
%end

%imacro bitor
%end

%imacro bitxor
%end

%imacro bitand
%end

%imacro ldf
%end

%imacro b
%end

%imacro bz
%end

%imacro swi
%end
