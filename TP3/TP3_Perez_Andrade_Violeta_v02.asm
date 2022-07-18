;
; TP3.asm
;
; Author : Violeta Perez Andrade 101456
;

.equ    LED_PORT_DIR =  DDRB
.equ    LED_PORT     =  PORTB
.equ    LED_PIN_NUM =  1
.equ    LED_PIN =  PINB
.equ    PUL1_PORT_DIR =  DDRD
.equ    PUL1_PIN  =  PIND
.equ    PUL1_PIN_NUM      =  2
.equ    PUL2_PORT_DIR =  DDRD
.equ    PUL2_PIN  =  PIND
.equ    PUL2_PIN_NUM      =  3
.def	pul1_status = r16
.def	pul1_counter = r18
.def	pul1_actual = r20
.def	pul2_status = r17
.def	pul2_counter = r19
.def	pul2_actual = r21


; Replace with your application code
.include "m328Pdef.inc"
;Inicio del codigo
.org	0x0000
	rjmp inicio
.org INT0Addr
	rjmp isr_int0
.org INT1Addr
	rjmp isr_int1
.org OVF0addr
	rjmp OVF0
.org OVF1addr
	rjmp OVF1
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


	rcall configure_ports

	//el registro pul1_status lo voy a usar para salvar
	//los estados del pulsador uno
	in pul1_status, PUL1_PIN
	//este and es para dejar en uno el bit 2 que es el que me importa
	andi pul1_status, 0b00000100
	//shifteo para que el valor me quede al final y sean mas facil las comparaciones
	lsr pul1_status
	lsr pul1_status

	//lo mismo para el pulsador dos que ahora es el bit3
	in pul2_status, PUL2_PIN
	lsr pul2_status
	lsr pul2_status
	lsr pul2_status

	//configuro timers e interrupciones
	//rcall configure_timer0
	rcall configure_timer1
	//rcall configure_timer2
	rcall configurar_interrupciones
	rcall handle_led
	sei

main_loop:
	jmp main_loop

isr_int0:
	in r24, SREG  ; Guardar registro de estado
	push	r24
	push r16

	;desactivo la interupcion externa para que no suceda
	;la interrupcion mientras estoy contando el debounce
	cbi EIMSK, INT0

	;activo el timer 0 que lo voy a estar usando para contar
	;el debounce del pulsador uno
	ldi r16, (1 << CS02) | (0 << CS01) | (1 << CS00) ;setea el prescaler en 1024
	out TCCR0B, r16

	;activo la interrupcion del timer 0
	ldi r16, 1<<TOIE0
	sts TIMSK0, r16

	pop r16
	pop r24
	reti

isr_int1:
	in r24, SREG  ; Guardar registro de estado
	push	r24
	push r16

	;desactivo la interupcion externa para que no suceda
	;la interrupcion mientras estoy contando el debounce
	cbi EIMSK, INT1

	;activo el timer2 que lo voy a estar usando para contar
	;el debounce del pulsador uno
	ldi r16, (1 << CS22) | (1 << CS21) | (1 << CS20)
	sts TCCR2B, r16

	;activo la interrupcion del timer 2
	ldi r16, 1<<TOIE2
	sts TIMSK2, r16

	pop r16
	pop r24
	reti

OVF0:
	in r24, SREG  ; Guardar registro de estado
	push	r24

	;chequeo si el counter llego a lo necesario
	cpi pul1_counter, 3
	breq OVF0_limit_reached

	;si no llego, simplemente lo incremento y salgo
	inc pul1_counter
	rjmp reti_OVF0

OVF0_limit_reached:
	;en caso que ya haya pasado el tiempo de debounce
	;limpio el contador
	clr pul1_counter
	
	;paro el timer porque ya no quiero seguir contando
	clr r0
	sts TCCR0B, r0
	
	;reactivar interrupcion externa
	sbi EIMSK, INT0

	;chequear si efectivamente cambio el bit
	;comparo el valor leido con el que tenia guardado en pul1_status
	;si los valores son iguales, solamente fue un falso positivo
	;si no, manejo el cambio y actualizo el estado del pulsador

	in pul1_actual, PUL1_PIN
	lsr pul1_actual
	lsr pul1_actual
	andi pul1_actual, 0b00000001
	cp pul1_actual, pul1_status
	breq reti_OVF0
	mov pul1_status, pul1_actual
	rcall handle_led

reti_OVF0:
	out SREG, r24  ; Restaurar registro de estado
	pop r24
	reti

handle_led:
	;en r25 cargo los estados de los pulsadores
	;y en base al caso que este steo el prescaler en lo necesario o enciendo el led
	mov r25, pul2_status
	lsl r25
	or r25, pul1_status
	cpi r25, 0b00000001
	breq handle_led_01
	cpi r25, 0b00000010
	breq handle_led_10
	cpi r25, 0b00000011
	breq handle_led_11
handle_led_00:
	;paro el timer uno
	clr r0
	sts TCCR1B, r0
	;prendo el led
	sbi LED_PORT, LED_PIN_NUM
	rjmp hanlde_led_fin
handle_led_01:
	;acitvo el timer 1 con prescaler 64 (011)
	ldi r22, (0 << CS12) | (1 << CS11) | (1 << CS10) ;setea el prescaler en 64
	sts TCCR1B, r22
	rjmp hanlde_led_fin
handle_led_10:
	;acitvo el timer 1 con prescaler 256 (100)
	ldi r22, (1 << CS12) | (0 << CS11) | (0 << CS10) ;setea el prescaler en 256
	sts TCCR1B, r22
	rjmp hanlde_led_fin
handle_led_11:
	;acitvo el timer 1 con prescaler 1024 (101)
	ldi r22, (1 << CS12) | (0 << CS11) | (1 << CS10) ;setea el prescaler en 1024
	sts TCCR1B, r22
	rjmp hanlde_led_fin
hanlde_led_fin:
	ret

OVF1:
	;esta interrupcion prende el led cuando llegue a overflow el timer 1
	;y el tiempo hasta el overflow va a depender de en cuanto este seteado
	;el prescaler, que depende de como esten apretados los pulsadores
	in r24, SREG  ; Guardar registro de estado
	push	r24
	sbic LED_PORT, LED_PIN_NUM ;skip if bit is cleared
	rjmp OVF1_turn_off_led
	sbi LED_PORT, LED_PIN_NUM
	rjmp OVF1_fin
OVF1_turn_off_led:
	cbi LED_PORT, LED_PIN_NUM
OVF1_fin:
	pop r24
	reti

OVF2:
	;la misma logica que OVF0 pero para el pulsador 2
	in r24, SREG  ; Guardar registro de estado
	push	r24
	;chequeo si el counter llego a lo necesario
	cpi pul2_counter, 3
	breq OVF2_limit_reached
	inc pul2_counter
	rjmp reti_OVF2

OVF2_limit_reached:
	;limpio el contador
	clr pul2_counter
	;desactivar la interrupcion del timer
	clr r0
	sts TIMSK2, r0
	;reactivar interrupcion externa
	sbi EIMSK, INT1
	;chequear si efectivamente cambio el bit
	in pul2_actual, PUL2_PIN
	lsr pul2_actual
	lsr pul2_actual
	lsr pul2_actual
	andi pul2_actual, 0b00000001
	cp pul2_actual, pul2_status
	breq reti_OVF2
	mov pul2_status, pul2_actual
	rcall handle_led
	
reti_OVF2:
	out SREG, r24  ; Restaurar registro de estado
	pop r24
	reti

configure_timer1:
	push r16
	ldi r16, (0 << CS12) | (0 << CS11) | (0 << CS10)
	sts TCCR1B, r16
	ldi r16, 1<<TOIE1
	sts TIMSK1, r16
	ldi r16, 1<<TOV1
	sts TIFR1, r16
	pop r16
	ret



;*************************************************************************************
; Subrutina para configurar las interrupciones
; registros utilizados: r16
;**************************************************************************************
configurar_interrupciones:
	push r16
	; INT0 e INT1 responden al cambio de flanco
	ldi r16, (0 << ISC11) | (1 << ISC10) | (0 << ISC01) | (1 << ISC00)
	sts EICRA, r16
	; Activar interrupciones para INT0 e INT1
	ldi r16, (1 << INT1) | (1 << INT0)
	out EIMSK, r16
	pop r16
	ret

;*************************************************************************************
; Se configuran los puertos del microcontrolador como entrada/salida/otra funcion
;
; En este caso, los puertos de los pulsadores se configuran como input
; y el led como output
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
	;el led esta en el puerto B entonces es output
	out	DDRB, r20
	;como en los pulsadores estan en el puerto D
	;es de input
	out	DDRD, r21
	;pongo en 1 la resistencia de pulldown
	sbi PORTD, 2
	sbi PORTD, 3
	pop r21
	pop r20
	ret