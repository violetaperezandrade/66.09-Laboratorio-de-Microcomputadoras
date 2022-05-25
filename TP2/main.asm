;
; TP2b.asm
; Author : Violeta
;


; Replace with your application code
.include "m328Pdef.inc"
;Inicio del codigo
.org	0x0000
	rjmp inicio;

inicio:

; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global
; RAMEND
	ldi		r16,HIGH(RAMEND)
	out		sph,r16
	ldi		r16,LOW(RAMEND)
	out		spl,r16.

	rcall	configure_ports


	
main_loop:
	ldi r18, 0x3
	mov r4, r18
	ldi r18, 0x5
	ldi	r17, 0x9
	rcall display_number
here:	jmp here

main_loop
	

display_number:
;main_loop:
	push r4
	push r18
	push r17

	;ldi	r17, 0x1
	ldi	zl,LOW(TABLA<<1)	;ZL = 0x00 (low byte of address)
	ldi	zh,HIGH(TABLA<<1)	;ZH = 0x05 (high byte of address)
	;ldi	zl,LOW(DISPLAY_0)	;ZL = 0x00 (low byte of address)
	;ldi	zh,HIGH(DISPLAY_0)	;ZH = 0x05 (high byte of address)
	
	l1:
		inc zl
		dec r17
		brne l1
		

	lpm	r17,z
	mov r4, r17
	mov r18, r17
	andi r18, 0b00001111

	/*
	ldi r18, 0b11110000
	mov r4, r18
	ldi r18, 0b00000000
	*/

	lsr	r4
	lsr	r4
	lsr	r4
	lsr	r4
	out	PORTB, r4
	out PORTC, r18

	pop r17
	pop r18
	pop r4
	ret

configure_ports:

	ldi	r20, 0xFF
	out	DDRC, r20
	out	DDRB, r20
	ret

	.ORG $500
;TABLA:	.DB	243, 96, 177, 244, 102, 214, 215, 116, 247, 246, 119, 247, 147, 243, 151, 23 

TABLA:	.DB	243, \
			96, \
			177, \
			244, \
			102, \
			214, \
			215, \
			116, \
			247, \
			246, \
			119, \
			247, \
			147, \
			243, \
			151, \
			23 

/*
DISPLAY_0:	.DB	243
DISPLAY_1:	.DB	96
DISPLAY_2:	.DB	177
DISPLAY_3:	.DB	244
DISPLAY_4:	.DB	102
DISPLAY_5:	.DB	214
DISPLAY_6:	.DB	215
DISPLAY_7:	.DB	116
DISPLAY_8:	.DB	247
DISPLAY_9:	.DB	246
;DISPLAY_A:	.DB	119
DISPLAY_A:	.DB	10
;DISPLAY_B:	.DB	247
DISPLAY_B:	.DB	11
DISPLAY_C:	.DB	147
DISPLAY_D:	.DB	243
DISPLAY_E:	.DB	151
DISPLAY_F:	.DB	23
*/

;DATA_0:	.DB 0b11110011
;DATA_1:	.DB 0b01100000
;DATA_2:	.DB 0b10110001
;DATA_3:	.DB 0b11110100
;DATA_4:	.DB	0b01100110
;DATA_5:	.DB	0b11010110
;DATA_6:	.DB	0b11010111
;DATA_7:	.DB	0b01110100
;DATA_8:	.DB	0b11110111
;DATA_9:	.DB	0b11110110
;DATA_A:	.DB	0b01110111
;DATA_B:	.DB	0b11110111
;DATA_C:	.DB	0b10010011
;DATA_D:	.DB	0b11110011
;DATA_E:	.DB	0b10010111
;DATA_F:	.DB	0b00010111

