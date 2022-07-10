;
; TP3p2.asm
;
; Author : Violeta Perez Andrade 101456
;


; Replace with your application code
.include "m328Pdef.inc"
.equ TOP_20ms = 40000
.equ UPPER_LIMIT = 4000
.equ LOWER_LIMIT = 2000
.def pul1_counter = r17
.def pul2_counter = r18
.def flag_pulsadores = r19
.def pul1_flag = r20
.def pul2_flag = r21
.def contador_timer = r22
.def contador_servo = r23
;Inicio del codigo
.org	0x0000
	rjmp inicio
.org INT0Addr
	rjmp isr_int0
.org INT1Addr
	rjmp isr_int1
.org OVF0addr
	rjmp OVF0
.org OVF2addr
	rjmp OVF2

.org INT_VECTORS_SIZE

inicio:
; Se inicializa el Stack Pointer al final de la RAM utilizando la definicion global
; RAMEND
	ldi		r16,HIGH(RAMEND)
	out		sph,r16
	ldi		r16,LOW(RAMEND)
	out		spl,r16

main:
	clr contador_timer
	clr contador_servo
	rcall configure_ports
	rcall configure_timer0
	rcall configure_timer1
	rcall configure_timer2
	rcall configurar_interrupciones
	sei
here: 
	rjmp here
;*************************************************************************************
; Se configuran los puertos del microcontrolador como entrada/salida/otra funcion
;
; En este caso, los puertos de los pulsadores se configuran como input
; y el puerto donde esta e servo como output
;
;Entrada: 					
;Salida: 					
;Registros utilizados: R20	
;**************************************************************************************

configure_ports:
	push r20
	push r21
	ldi r21, 0x0
	ldi	r20, 0xFF
	;el servo esta en el puerto B entonces es output
	out	DDRB, r20
	;como en los pulsadores estan en el puerto D
	;es de input
	out	DDRD, r21
	;pongo en 1 la resistencia de pullup
	sbi PORTD, 2
	sbi PORTD, 3
	pop r21
	pop r20
	ret

configure_timer1:
	push r16
	push r17
	//TCCR1A
	//dejo el a en modo inversor
	//y el b en modo no inversor
	clr r16
	ori r16, (0 << WGM10) | (1 << WGM11) | (1 << COM1A1) | (0 << COM1A0) | (0 << COM1B1) | (0 << COM1B0)
	sts	TCCR1A, r16
	//TCCRB
	clr r16
	ori r16, (0 << ICNC1) | (0 << ICES1) | (0 << CS12) | (1 << CS11) | (0 << CS10) | (1 << WGM12) | (1 << WGM13)
	sts TCCR1B, r16
	ldi r16, LOW(2000)
	ldi r17, HIGH(2000)
	sts OCR1AH, r17
	sts OCR1AL, r16
	ldi contador_servo, 0
	//ICR1
	//necesito que el top sea 40000=0x9C40
	//para un pulso de 20 ms
	ldi r16, HIGH(TOP_20ms)
	sts ICR1H, r16
	ldi r16, LOW(TOP_20ms)
	sts ICR1L, r16
	pop r17
	pop r16
	ret

configure_timer0:
	push r16
	ldi r16, (1 << CS02) | (0 << CS01) | (1 << CS00) ;setea el prescaler en 1024
	out TCCR0B, r16
	;activar la interrupcion del timer
	ldi r16, 1<<TOIE0
	sts TIMSK0, r16
	pop r16
	ret

configure_timer2:
	push r16
	ldi r16, (1 << CS22) | (1 << CS21) | (1 << CS20)
	sts TCCR2B, r16
	ldi r16, 1<<TOIE2
	sts TIMSK2, r16
	pop r16
	ret

OVF0:
	in r24, SREG  ; Guardar registro de estado
	push	r24
	;chequeo si el counter llego a lo necesario
	cpi contador_timer, 13
	breq OVF0_limit_reached
	inc contador_timer
	rjmp reti_OVF0
OVF0_limit_reached:
	cpi flag_pulsadores, (1 << 0)
	breq mover_izquierda
	cpi flag_pulsadores, (1 << 1)
	breq mover_derecha
	rjmp reti_OVF0
mover_derecha:
	cpi contador_servo, 16
	breq fin_OVF0
	//quiero sumar 125 que es el paso
	//125=63+62
	lds r24, OCR1AL
	lds r25, OCR1AH
	adiw r24, 63
	adiw r24, 62
	sts OCR1AH, r25
	sts OCR1AL, r24
	inc contador_servo
	rjmp fin_OVF0
mover_izquierda:
	cpi contador_servo, 0
	breq fin_OVF0
	//quiero sumar 125 que es el paso
	//125=63+62
	lds r24, OCR1AL
	lds r25, OCR1AH
	sbiw r24, 63
	sbiw r24, 62
	sts OCR1AH, r25
	sts OCR1AL, r24
	dec contador_servo
fin_OVF0:
	;limpio el contador
	clr contador_timer
reti_OVF0:
	pop r24
	reti

isr_int0:
	push r24
	in r24, SREG  ; Guardar registro de estado
	ldi pul1_flag, 1
	clr pul1_counter
	out SREG, r24  ; Restaurar registro de estado
	pop r24
	reti

isr_int1:
	push r24
	in r24, SREG  ; Guardar registro de estado
	ldi pul2_flag, 1
	clr pul2_counter
	out SREG, r24  ; Restaurar registro de estado
	pop r24
	reti

OVF2:
	push r24
	in r24, SREG  ; Guardar registro de estado
	;chequeo si el counter1 llego a lo necesario
	cpi pul1_flag, 1
	breq handle_pul1
	cpi pul2_flag, 1
	breq handle_pul2
	rjmp reti_ovf2
handle_pul1:
	cpi pul1_counter, 4
	breq pul1_debounce
	inc pul1_counter
	rjmp reti_OVF2
pul1_debounce:
	sbic PIND, 2
	breq pul1_falso_positivo
	ldi flag_pulsadores, (1 << 1)
	clr pul1_counter
	rjmp reti_OVF2
pul1_falso_positivo:
	ldi pul1_flag, 0
	ldi flag_pulsadores, 0
	rjmp reti_OVF2

handle_pul2:
	cpi pul2_counter, 4
	breq pul2_debounce
	inc pul2_counter
	rjmp reti_OVF2
pul2_debounce:
	sbic PIND, 3
	breq pul2_falso_positivo
	ldi flag_pulsadores, (1 << 0)
	clr pul2_counter
	rjmp reti_OVF2
pul2_falso_positivo:
	ldi pul2_flag, 0
	ldi flag_pulsadores, 0
	rjmp reti_OVF2
reti_OVF2:
	out SREG, r24
	pop r24
	reti

;*************************************************************************************
; Subrutina para configurar las interrupciones
; registros utilizados: r16
;**************************************************************************************
configurar_interrupciones:
	push r16
	; INT0 e INT1 responden al flanco descendente
	ldi r16, (1 << ISC11) | (0 << ISC10) | (1 << ISC01) | (0 << ISC00)
	sts EICRA, r16
	; Activar interrupciones para INT0 e INT1
	ldi r16, (1 << INT1) | (1 << INT0)
	out EIMSK, r16
	pop r16
	ret