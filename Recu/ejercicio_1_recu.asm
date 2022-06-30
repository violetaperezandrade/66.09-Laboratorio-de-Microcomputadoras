;
; Recuperatorio.asm
;
; Created: 23/6/2022 19:09:47
; Author : Violeta
;


; Replace with your application code
.include "m328pdef.inc"

.def counter_va = r17
.def counter_vb = r18

.def size_va = r19
.def size_vb = r20
.def size_vr = r21

.dseg
arrayA: .byte 40
arrayB: .byte 40
arrayR: .byte 80
KA: .byte 1
KB: .byte 1
KR: .byte 1
.cseg

.org 0x0000
    rjmp start

.org INT_VECTORS_SIZE
start:
    ; ------ Configurar stack pointer ------
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16
    ; --------------------------------------

main:
    rcall merge_vectores
here:    
    rjmp here

merge_vectores:
    push counter_va
    push counter_vb
    push size_va
    push size_vb
    rcall load_tables_pointer
    ldi r25, 80
    ld r23, x+
    ld r24, y+
loop_merge:
    ;si ya termine de recorrer el vector a
    ;entonces solo resta escribir
    ;en el nuevo vector lo que quede en
    ;el vector b
    cp counter_va, size_va 
    breq va_empty
    ;idem con el vector 2
    cp counter_vb, size_vb
    breq vb_empty
    ;comparo los dos valores leidos de 
    ;los vectores
    cp r23, r24
    ;si el dato del vector a es menor
    ;entonces escribo en el vector r ese valor
    brlt write_from_array_a
    ;si en cambio el dato del vector b es menor
    ;entonces escribo en el vector ese valor
    rjmp write_from_array_b

write_from_array_a:
    st z+, r23
    ld r23, x+
    inc counter_va
    rjmp end_loop

write_from_array_b:
    st z+, r22
    ld r22, x+
    inc counter_vb
    rjmp end_loop

end_loop:
    dec r25
    brne loop_merge


va_empty:
    ;si el vector b tambien sucede
    ;haber sido recorrido completo
    ;entonces, ya termine 
    cp counter_vb, size_vb
    breq fin_merge_vectores
loop_va_empty:
    st z+, r22
    ld r22, x+
    inc counter_vb
    cp counter_vb, size_vb
    brne loop_va_empty
    rjmp fin_merge_vectores

vb_empty:
    st z+, r23
    ld r23, x+
    inc counter_va
    cp counter_va, size_va
    brne vb_empty

fin_merge_vectores:
    pop size_vb
    pop size_va
    pop counter_vb
    pop counter_va
    ret

load_tables_pointer:
    ldi xh, HIGH(arrayA)
    ldi xl, LOW(arrayA)
    ldi yh, HIGH(arrayB)
    ldi yl, LOW(arrayB)
	ldi	zl,LOW(arrayR)
	ldi	zh,HIGH(arrayR)	
    ldi size_va,LOW(KA)
    ldi size_vb,LOW(KB)
    ldi size_vr,LOW(KR)
    ret
