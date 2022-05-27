;
; TP2b.asm
; Author : Violeta
;


; Replace with your application code
.include "m328Pdef.inc"
;Inicio del codigo
.org	0x0000
	rjmp inicio
.org INT0Addr
	rjmp isr_int0
.org INT1Addr
	rjmp isr_int1

.org INT_VECTORS_SIZE

inicio:

; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global
; RAMEND
	ldi		r16,HIGH(RAMEND)
	out		sph,r16
	ldi		r16,LOW(RAMEND)
	out		spl,r16.
	
main_loop:
	;rcall	load_table_in_eeprom
	rcall	check_signature
	brtc	table_ok
	rcall	load_table_in_eeprom
table_ok:
	rcall	configure_ports
	rcall	configurar_interrupciones
	sei
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

load_table_in_eeprom:
;tabla “0,2,4,6,8,A,C,E,F,D,B,9,7,5,3,1,0,F,0,A,8"
	ldi		xl, 0x0
	ldi		xh, 0x0
	ldi		r20, 0x20
	rcall	write_eeprom ;r20
	inc		xl
	ldi		r20, 0x21
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x0
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x2
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x4
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x6
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x8
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xA
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xC
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xE
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xF
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xD
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xB
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x9
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x7
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x5
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x3
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x1
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x0
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xF
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x0
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0xA
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x8
	rcall	write_eeprom
	inc		xl
	ldi		r20, 0x2
	rcall	write_eeprom
	ret

configure_ports:
	push r20
	push r21
	ldi r21, 0x0
	ldi	r20, 0xFF
	out	DDRC, r20
	out	DDRB, r20
	out	DDRD, r21
	pop r21
	pop r20
	ret

configurar_interrupciones:
	; INT0 e INT1 responden al flanco ascendente
	ldi r16, (1 << ISC11) | (1 << ISC10) | (1 << ISC01) | (1 << ISC00)
	sts EICRA, r16
	; Activar interrupciones para INT0 e INT1
	ldi r16, (1 << INT1) | (1 << INT0)
	out EIMSK, r16
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

isr_int0: ; Pulsador 1
	push	r24
	push	r22
	push	r21
	push	r17
	in r24, SREG  ; Guardar registro de estado
	call delay50ms
	sbis PIND, 2  ; antirebote
	rjmp isr_int0_fin
	ldi		xl, 0x17 ;pos de LP
	ldi		xh, 0x0
	rcall	read_eeprom
	cpi	r20, 0x16 ;si ya llegue al fin de la tabla salgo
	brge	draw_isr_int0
	inc	r20
draw_isr_int0:
	mov	r21, r20 ; me guardo lo que voy a dejar en lp
	mov	xl, r20 ;cargo en xl el indice del prox dato(que quiero dibujar)
	rcall	read_eeprom
	mov	r17, r20 ;dejo en r17 lo que quiero dibujar para llamar a display number
	rcall display_number
	;ahora quiero dejar en lp el indice del dato dibujado (r21)
	ldi	xl, 0x17
	mov	r20, r21
	rcall write_eeprom

isr_int0_fin:
	out SREG, r24  ; Restaurar registro de estado
	pop r17
	pop	r21
	pop	r22
	pop r24

	reti

isr_int1: ; Pulsador 2
	push	r24
	push	r22
	push	r21
	push	r17
	in r24, SREG  ; Guardar registro de estado
	call delay50ms
	sbis PIND, 3  ; antirebote
	rjmp isr_int1_fin
	ldi		xl, 0x17 ;pos de LP
	ldi		xh, 0x0
	rcall	read_eeprom
	cpi	r20, 0x3 ;si estoy al comienzo de la tabla salgo
	brlt	draw_isr_int1
	dec	r20
draw_isr_int1:
	mov	r21, r20 ; me guardo lo que voy a dejar en lp
	mov	xl, r20 ;cargo en xl el indice del prox dato(que quiero dibujar)
	rcall	read_eeprom
	mov	r17, r20 ;dejo en r17 lo que quiero dibujar para llamar a display number
	rcall display_number
	;ahora quiero dejar en lp el indice del dato dibujado (r21)
	ldi	xl, 0x17
	mov	r20, r21
	rcall write_eeprom

isr_int1_fin:
	out SREG, r24  ; Restaurar registro de estado
	pop r17
	pop	r21
	pop	r22
	pop r24

	reti

delay50ms:
  ldi r19, 4
  loop0:
    ldi r18, 201
    loop1:
	  ldi r17, 248
	  loop2:
	      nop
		  dec r17
		  brne loop2
	  dec r18
	  brne loop1
	dec r19
	brne loop0
  ret

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
			199, \
			147, \
			229, \
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

