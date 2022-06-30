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
    ldi zh, HIGH(TABLA_1<<1)
    ldi zl, LOW(TABLA_1<<1)
	ldi xh, HIGH(arrayA)
    ldi xl, LOW(arrayA)
	ldi r17, TABLA_1_LENGTH
	rcall load_from_flash_to_ram

	ldi zh, HIGH(TABLA_2<<1)
    ldi zl, LOW(TABLA_2<<1)
	ldi xh, HIGH(arrayB)
    ldi xl, LOW(arrayB)
	ldi r17, TABLA_2_LENGTH
	rcall load_from_flash_to_ram
    rcall merge_vectores
here:    
    rjmp here

merge_vectores:
    push counter_va
    push counter_vb
    push size_va
    push size_vb
    rcall load_tables_pointer
	rcall load_variables
    mov r25, size_vr //kr
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
    brlo write_from_array_a
    ;si en cambio el dato del vector b es menor
    ;entonces escribo en el vector ese valor
    rjmp write_from_array_b

write_from_array_a:
    st z+, r23
    ld r23, x+
    inc counter_va
    rjmp end_loop

write_from_array_b:
    st z+, r24
    ld r24, y+
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
    st z+, r24
    ld r24, y+
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
    ret

load_variables:
	push xh
	push xl
    ldi xh, HIGH(KA)
    ldi xl, LOW(KA)
	ldi size_va, TABLA_1_LENGTH
	st x, size_va

	ldi xh, HIGH(KB)
    ldi xl, LOW(KB)
	ldi size_vb, TABLA_2_LENGTH
	st x, size_vb

	ldi xh, HIGH(KR)
    ldi xl, LOW(KR)
	clr size_vr
	add size_vr, size_va
	add size_vr, size_vb
	st x, size_vr


	pop xl
	pop xh
	ret

load_from_flash_to_ram:
	push r16
loop_load_etc:
	lpm	r16,z+
	st x+, r16
	dec r17
	brne loop_load_etc
	pop r16
	ret

TABLA_1:	.DB	1,3,18,22,24,33
.equ TABLA_1_LENGTH=6

TABLA_2:	.DB	2,5,21,30
.equ TABLA_2_LENGTH=4
