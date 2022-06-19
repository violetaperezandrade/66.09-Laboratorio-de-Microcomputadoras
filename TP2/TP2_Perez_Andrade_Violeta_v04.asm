;
; TP2b.asm
; Author : Violeta Perez Andrade 101456
;


; Replace with your application code
.include "m328Pdef.inc"
.equ FIRMA_1 = 0x20
.equ FIRMA_2 = 0x21
.equ POS_LP = 0x17
.equ INICIO_TABLA = 0x3
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
	rcall	check_signature
	brtc	table_ok
	rcall	load_table_in_eeprom
table_ok:
	rcall	configure_ports
	rcall   display_a_to_f
	rcall   display_last
	rcall	configurar_interrupciones
	sei
here:	jmp here

;*************************************************************************************
; Subrutina que chequea la firma
; para saber si la tabla esta cargada en la EEPROM
; Registros utilizados: r17, r18, r19, r20
;**************************************************************************************

check_signature:
	push	r17
	push	r18
	push	r19
	ldi		r17, FIRMA_1
	ldi		r18, FIRMA_2
	ldi		xl, 0x0
	ldi		xh, 0x0
	rcall	read_eeprom ;X y r20
	cpse	r20, r17
	rjmp	fallo_signature
	ld  r0, x+
	rcall	read_eeprom
	cpse	r20, r18
	rjmp	fallo_signature
	rjmp	signature_ok
	fallo_signature:
	set
	rjmp	fin_ckeck_signature
signature_ok:
	lt
fin_ckeck_signature:
	pop	r19	
pop	r19	
	pop	r19	
	pop	r18
	pop	r17
	ret

;*************************************************************************************
; Subrutina para cargar la tabla de datos en
; la memoria EEPROM
; registros utilizados: r19, r20, r21
;**************************************************************************************

load_table_in_eeprom:
	push r21
	push r20
	push r19
	ldi	xl, 0x2
	ldi	xh, 0x0
	ldi	zl,LOW(TABLA_EEPROM<<1)
	ldi	zh,HIGH(TABLA_EEPROM<<1)
	ldi	r21, 22
loop_load_table:
	lpm	r20,z+
	rcall	write_eeprom
	ld    r0, x+
	dec r21
	brne loop_load_table
	ldi	xl, 0x0
	ldi	xh, 0x0
	ldi	r20, 0x20
	rcall write_eeprom ;r20
	clr	r0
	ldi	r19, 1
	add	xl, r19
	adc xh, r0
	ldi	r20, 0x21
	rcall write_eeprom
	clr	r0
	ldi	r19, 1
	add	xl, r19
	adc xh, r0
	pop r19
	pop r20
	pop r21
	ret

;*************************************************************************************
; Subrutina para configurar los puertos de los pulsadores
; y del display
; registros utilizados: r20, r21
;**************************************************************************************

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

;*************************************************************************************
; Subrutina para mostras, al comienzo del programa
; la secuencia de la A a la F
; registros utilizados: r17, r18, r19
;**************************************************************************************

display_a_to_f:
	push r17
	push r18
	push r19
	ldi	zl,LOW(DIC<<1)
	ldi	zh,HIGH(DIC<<1)
	ldi	r18, 6

loop_display_af:
	lpm	r17,z
	rcall display_number
	rcall delay_1s
	ld  r0, z+
	dec r18
	brne loop_display_af

pop r19
pop r18
pop r17
ret

;*************************************************************************************
; Subrutina para mostrar en el display el ultimo numero
; que fue mostrado antes de que se apague el micro
; registros utilizados: r17, r20
;**************************************************************************************

display_last:
	ldi		xl, POS_LP ;pos de LP
	ldi		xh, 0x0
	rcall	read_eeprom
	mov	xl, r20 ;cargo en xl el indice del dato que quiero dibujar
	rcall	read_eeprom
	mov	r17, r20
	rcall display_number
	ret

;*************************************************************************************
; Subrutina para configurar las interrupciones
; registros utilizados: r16
;**************************************************************************************

configurar_interrupciones:
	; INT0 e INT1 responden al flanco ascendente
	ldi r16, (1 << ISC11) | (1 << ISC10) | (1 << ISC01) | (1 << ISC00)
	sts EICRA, r16
	; Activar interrupciones para INT0 e INT1
	ldi r16, (1 << INT1) | (1 << INT0)
	out EIMSK, r16
	ret

;*************************************************************************************
; Subrutina para, dado un numero, mostrar
; este en el display de 7 segmentos
; registros utilizados: r17, r18, r4
;**************************************************************************************

display_number:
	push r4
	push r18
	push r17
	push zl
	push zh

	ldi	zl,LOW(TABLA<<1)	;ZL = 0x00 (low byte of address)
	ldi	zh,HIGH(TABLA<<1)	;ZH = 0x05 (high byte of address)

	clr r0
	add zl, r17
	adc zh, r0

	lpm	r17,z
	mov r4, r17
	mov r18, r17
	andi r18, 0b00001111

	swap r4

	out	PORTB, r4
	out PORTC, r18

	pop zh
	pop zl
	pop r17
	pop r18
	pop r4
	ret

;*************************************************************************************
; Subrutina para poder leer un dato de una posicion
; dada de la memoria EEPROM
; registros utilizados: r20
;**************************************************************************************

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

;*************************************************************************************
; Subrutina para poder escribir un dato de una posicion
; dada en la memoria EEPROM
; registros utilizados: r20
;**************************************************************************************

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

;*************************************************************************************
; Subrutina para que al presionar el pulsador
; se avance en la tabla
; registros utilizados: r17, r21, r22, r24,
;**************************************************************************************

isr_int0: ; Pulsador 1
	in r24, SREG  ; Guardar registro de estado
	push	r24
	push	r22
	push	r21
	push	r17
	call delay50ms
	sbis PIND, 2  ; antirebote
	rjmp isr_int0_fin
	ldi		xl, POS_LP
	ldi		xh, 0x0
	rcall	read_eeprom
	cpi	r20, 0x16 ;si ya llegue al fin de la tabla salgo
	brge isr_int0_fin
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
	pop r17
	pop	r21
	pop	r22
	pop r24
	out SREG, r24  ; Restaurar registro de estado
	reti

;*************************************************************************************
; Subrutina para que al presionar el pulsador
; se retroceda en la tabla
; registros utilizados: r17, r21, r22, r24,
;**************************************************************************************

isr_int1: ; Pulsador 2
	in r24, SREG  ; Guardar registro de estado
	push	r24
	push	r22
	push	r21
	push	r17
	call delay50ms
	sbis PIND, 3  ; antirebote
	rjmp isr_int1_fin
	ldi		xl, POS_LP ;pos de LP
	ldi		xh, 0x0
	rcall	read_eeprom
	cpi	r20, INICIO_TABLA ;si estoy al comienzo de la tabla salgo
	brlt isr_int1_fin
	dec	r20

draw_isr_int1:
	mov	r21, r20 ; me guardo lo que voy a dejar en lp
	mov	xl, r20 ;cargo en xl el indice del prox dato(que quiero dibujar)
	rcall	read_eeprom
	mov	r17, r20 ;dejo en r17 lo que quiero dibujar para llamar a display number
	rcall display_number
	;ahora quiero dejar en lp el indice del dato dibujado (r21)
	ldi	xl, POS_LP
	mov	r20, r21
	rcall write_eeprom

isr_int1_fin:
	pop r17
	pop	r21
	pop	r22
	pop r24
	out SREG, r24  ; Restaurar registro de estado
	reti

delay50ms:
	push r19
	push r18
	push r17
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
	pop r17
	pop r18
	pop r19
	ret

delay_1s: 										
	ldi 	r20, 50
outer_loop:
	ldi 	r21, 255
middle_loop:
	ldi 	r22, 255
inner_loop:
	dec 	r22 
dec 	r22 
	dec 	r22 
	brne	inner_loop 
brne	inner_loop 
	brne	inner_loop 
	dec 	r21		
dec 	r21		
	dec 	r21		
	brne 	middle_loop		
brne 	middle_loop		
	brne 	middle_loop		
	dec 	r20					
dec 	r20					
	dec 	r20					
	brne 	outer_loop
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

TABLA_EEPROM: .DB 0,2,4,6,8,0xA,0xC,0xE,0xF,0xD,0xB,9,7,5,3,1,0,0xF,0,0xA,8,2,20,21
DIC: .DB 0xA,0xB,0xC,0xD,0xE,0xF
