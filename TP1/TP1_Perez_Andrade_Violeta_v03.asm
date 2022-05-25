;
; TP1v2.asm
;
; Rutina que hace titilar un led al apretar el pulsador uno
; y apagarlo al presionar el pulsador 2
; Author : Violeta Perez Andrade 101456
;


; Replace with your application code
.include "m328Pdef.inc"

.equ    LED_PORT_DIR =  DDRD
.equ    LED_PORT     =  PORTD
.equ    LED_PIN      =  2
.equ    PUL1_PORT_DIR =  DDRB
.equ    PUL1_PORT_IN  =  PINB
.equ    PUL1_PIN      =  0
.equ    PUL2_PORT_DIR =  DDRD
.equ    PUL2_PORT_IN  =  PIND
.equ    PUL2_PIN      =  7
.equ	PUL2_PIN_PULL_DOWN = PORTD
.def	LED_STATUS	=	r17

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

wait_asc_flank:
	; sbic	LED_PORT, LED_PIN
	; rjmp	wait_desc_flank

	cpi 	LED_STATUS, 0x01
	breq 	wait_desc_flank ; si el led esta prendido salto a wit_desc_flank
	sbis 	PUL1_PORT_IN, PUL1_PIN
	rjmp	wait_asc_flank
	rcall	debounce_time ; Se detecto el flanco, espera el tiempo de debounce
	sbis	PUL1_PORT_IN, PUL1_PIN ;Rechequear el valor para evitar falsos positivos
	rjmp	wait_asc_flank
	rcall 	turn_led_on ; prendo el led
 
wait_desc_flank:
	; sbis 	LED_PORT, LED_PIN
	; rjmp 	wait_asc_flank

	cpi 	LED_STATUS, 0x00
	breq 	wait_asc_flank ; si el led esta apagado salto a wait_asc_flank
	rjmp 	blink_led

check_desc_flank:
	sbic	PUL2_PORT_IN, PUL2_PIN
	rjmp	wait_desc_flank
	rcall	debounce_time ; Se detecto el flanco, espera el tiempo de debounce
	sbic	PUL2_PORT_IN, PUL2_PIN ;Rechequear el valor para evitar falsos positivos
	rjmp	wait_desc_flank
	rcall 	turn_led_off 
	rjmp 	main_loop

blink_led:
	sbis 	LED_PORT, LED_PIN
	rjmp 	wait_asc_flank
	rcall 	delay_1s
		
	rcall 	turn_led_off
	rcall	delay_1s

	rcall	turn_led_on
	rjmp 	check_desc_flank

; sbic	PUL1_PORT_IN, PUL1_PIN
; sbi     LED_PORT,LED_PIN //si el pulsador uno esta en 1, quiero encender el led
; sbic	PUL2_PORT_IN, PUL2_PIN //si el pulsador uno esta en 0, 
; salteo la instruccion y chequeo el 2
; cbi     LED_PORT,LED_PIN //si esta en uno, no skipeo y apago el led
; rjmp	main_loop


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
	ldi 	r20, 0x00 						; Cargo el registro R20 con 0x00
	ldi 	LED_STATUS, 0x00 				; Cargo en el registro LED_STATE (r17) con 0x00
	out 	DDRD, r20 						; Cargo un cero en todos los bits del DDRD
	out 	DDRB, r20 						; Cargo un cero en todos los bits del DDRB
	sbi 	DDRD, LED_PIN 					; Configuro al puerto del led como output
	out 	LED_PORT, r20 					; Cargo un cero en todos los bits del PORTD
	out 	PORTB, r20						; Cargo un cero en todos los bits del PORTB
	sbi 	PORTD, PUL2_PIN 				; Enciendo la resistencia de Pull-up, PORTD7 = 1
	ret

;*************************************************************************************
; Subrutina para prender el led
;**************************************************************************************

turn_led_on:
	sbi 	LED_PORT, LED_PIN
	ldi 	LED_STATUS, 0x01
	ret

;*************************************************************************************
; Subrutina para apagar el led
;**************************************************************************************

turn_led_off:
	cbi 	LED_PORT, LED_PIN
	ldi 	LED_STATUS, 0x00
	ret

;*************************************************************************************
; Retardo de 5ms (Calculado con un cristal de 16MHz)
; Si ocurren x ciclos de clock, el tiempo que transcurre es:
; t = x/F siendo F la frecuencia
; del clock, en este caso 16MHz. Entonces x = t*F
; y, particularmente con t=5ms, entonces x = 5e-3*16e6 = 80000
; Entonces, necesito 80k clocks
; Para eso, planteo dos ciclos.
; En el loop_2(interno) realizo un dec de un clock y un brne de 2
; En el loop_1 realizo: ldi de un clock, dec de un clok y brne de dos clocks
; (con la salvedad de que el ultimo es de uno)
; Entonces, siendo m la cantidad de veces que se realiza el loop 2
; y n la cantidad de veces que se realiza el loop 1, queda:
; 80000 = 3*m*n + 4*m
; Entonces, eligiendo algun valor para m, por ejemplo, 256
; el valor de n sera 80000 = 3*256m*n + 4*256 <=> n = 104 					
;Registros utilizados: r20, r21
;*************************************************************************************

; debounce_time: 	
; 	ldi 	r20, 103
; loop_1:
; 	ldi 	r21, 255 
; loop_2:
; 	dec 	r21 	
; 	brne 	loop_2
; 	dec 	r20
; 	brne 	loop_1
; 	ret

debounce_time: 										
	ldi 	r20, 4
outer_loop_debounce:
	ldi 	r21, 255
middle_loop_debounce:
	ldi 	r22, 255
inner_loop_debounce:
	dec 	r22 
	brne	inner_loop_debounce 

	dec 	r21		
	brne 	middle_loop_debounce		

	dec 	r20					
	brne 	outer_loop_debounce
	ret			

;*************************************************************************************
; Retardo de 1s (Calculado con un cristal de 16MHz)
; 
; Como se explico en el caso anterior para dos ciclos, el tiempo es:
; t = (3m+4)*n/16MHz con m y n la cantidad de loops, 
; el maximo tiempo que se puede conseguir es:
; t =  (3*256+4)*256/16MHz = 12,3 ms, como se necesita mas tiempo(1s)
; se agrega un tercer ciclo, y siguiendo la misma logica:
; t*f = [(3*m + 4)*n +1+2+1]*p, 
; siendo m la cantidad de veces que se ejecuta el ciclo mas interno, n el intermedio,
; y p el mas externo,
;asi: p = t*f/[5*m*n + 4*n + 4]
; y dandole a m y n los valores 256, p debe valer 49					
;Registros utilizados: r20, r21, r22
;*************************************************************************************

delay_1s: 										
	ldi 	r20, 50
outer_loop:
	ldi 	r21, 255
middle_loop:
	ldi 	r22, 255
inner_loop:
	sbis	PUL2_PORT_IN, PUL2_PIN 	; Si a la mitad se aprieta el boton salgo del ciclo
	ret 
	dec 	r22 
	brne	inner_loop 

	dec 	r21		
	brne 	middle_loop		

	dec 	r20					
	brne 	outer_loop
	ret 

 	

