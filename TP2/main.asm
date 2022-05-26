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
	
main_loop:
	rcall	check_signature
	brtc	table_ok
	rcall	load_table_in_eeprom
table_ok:
	ldi		r18, 0x3
	mov		r4, r18
	ldi		r18, 0x5
	ldi		r17, 0xF
	rcall	configure_ports
	rcall display_number
	here:	jmp here

check_signature:
	push	r17
	push	r18
	push	r19
	push	r24
	ldi		r19, 3
	bst		r19, 5
	ldi		r24, 3
	ldi		r17, 0x20
	ldi		r18, 0x21
	ldi		xl, 0x0
	ldi		xh, 0x0
	rcall	read_eeprom ;X y r20
	;cpi		r20, 0x20
	cpse	r20, r17
	dec		r19
	inc		xl
	rcall	read_eeprom
	cpse	r20, r18
	dec		r19
	cpse	r19, r24
	bst		r24, 1
	pop	r24
	pop	r19	
	pop	r18
	pop	r17
	ret


display_number:
	push r4
	push r18
	push r17

	ldi	zl,LOW(TABLA<<1)	;ZL = 0x00 (low byte of address)
	ldi	zh,HIGH(TABLA<<1)	;ZH = 0x05 (high byte of address)
	
	l1:
		inc zl
		dec r17
		brne l1

	lpm	r17,z
	mov r4, r17
	mov r18, r17
	andi r18, 0b00001111

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
	push r20
	ldi	r20, 0xFF
	out	DDRC, r20
	out	DDRB, r20
	pop r20
	ret

load_table_in_eeprom:
	ret

read_eeprom:
	; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp read_eeprom
	; Set up address X in address register
	out EEARH, XH
	out EEARL, XL
	; Start eeprom read by writing EERE
	sbi EECR,EERE
	; Read data from Data Register
	in r20,EEDR
	ret

write_eeprom:
	; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp write_eeprom
	; Set up address X in address register
	out EEARH, XH
	out EEARL, XL
	; Write data (r16) to Data Register
	out EEDR,r20
	; Write logical one to EEMPE
	sbi EECR,EEMPE
	; Start eeprom write by setting EEPE
	sbi EECR,EEPE
	ret

	.ORG $500
TABLA:	.DB	243, \
			96, \
			181, \
			244, \
			102, \
			214, \
			215, \
			112, \
			247, \
			246, \
			119, \
			247, \
			147, \
			243, \
			151, \
			23 

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

