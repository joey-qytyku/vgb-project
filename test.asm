bits 32

; ModRM and SIB example:
; When using ESP or EBP, an offset is required (but can be zero)
;


test:
        mov     [eax],dword 1
        mov     [ebx],dword 1
        mov     [ecx],dword 1
        mov     [edx],dword 1
        mov     [esi],dword 1
        mov     [edi],dword 1
        mov     [ebp],dword 1
        mov     [esp],dword 1
        mov     [eax+ebx],dword 1
