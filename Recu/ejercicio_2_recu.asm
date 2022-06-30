;
; Recuperatorio.asm
;
; Created: 23/6/2022 19:09:47
; Author : Violeta
;


; Replace with your application code
.include "m328pdef.inc"

.def counter = r17
.def pd4_status = r18
.def pd5_status = r19
.def current_pd4 = r20
.def current_pd5 = r21

.org 0x0000
    rjmp start
.org INT0Addr
	rjmp isr_int
.org INT1Addr
	rjmp isr_int
.org PCI2addr
    rjmp pc_int

.org INT_VECTORS_SIZE
start:
    ; ------ Configurar stack pointer ------
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16
    ; --------------------------------------

main:
    clr r17
    in pd4_status, PIND
    andi pd4_status, 0b00010000
    in pd5_status, PIND
    andi pd5_status, 0b00100000
    rcall	configure_ports
	rcall	configurar_interrupciones
	sei
here:	jmp here

isr_int:
	in r24, SREG  ; Guardar registro de estado
	push	r24
    ;si el contador ya llego a 9, no se puede
    ;incrementar mas entonces salgo
    cpi r17, 9
    breq fin_isr_int
    ;caso contrario, incremento
    ;el valor del contador y lo muestro
    ;en el display
    inc r17
    rcall display_number
fin_isr_int:
    pop r24
    reti
    
pc_int:
	in r24, SREG  ; Guardar registro de estado
	push	r24
    ;si el contador esta en 0, no se puede
    ;decremntar mas entonces salgo
    cpi r17, 0
    breq fin_pc_int
    ;cargo los valores actuales de pd4 y pd5
    in current_pd4, PIND
    andi current_pd4, 0b00010000
    in current_pd5, PIND
    andi current_pd5, 0b00100000
    ;si el estado de pd4 y lo leido del pin
    ;son iguales, hubo un cambio en pd5
    ;sino, chequeo pd4
    cpse current_pd4, pd4_status
    rjmp change_pd4
    rjmp change_pd5
change_pd4:
    mov pd4_status, current_pd4
    ;si el valor del pin no es cero
    ;estoy en un alto y no quiero hacer nada
    cpi pd4_status, 0
    brne fin_pc_int
    ;caso contrario, decremento el contador
    ;(que para esta altura ya se que es != 0)
    ;y muestro el numero correspondiente
    dec r17
    rcall display_number
    rjmp fin_pc_int
change_pd5:
    mov pd5_status, current_pd5
    ;si el valor del pin no es cero
    ;estoy en un alto y no quiero hacer nada
    cpi pd5_status, 0
    brne fin_pc_int
    ;caso contrario, decremento el contador
    ;(que para esta altura ya se que es != 0)
    ;y muestro el numero correspondiente
    dec r17
    rcall display_number
    rjmp fin_pc_int
fin_pc_int:    
    pop r24
    reti

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
    ; Activar interrupciones para PCINT20 y PCINT21
    clr r16
    ldi r16, 0b00000100
    sts PCICR, r16
    clr r16
    ldi r16, 0b00110000
    sts PCMSK2, r16
	ret

display_number:
	push r4
	push r18
	push r17
	push zl
	push zh
	ldi	zl,LOW(TABLA<<1)
	ldi	zh,HIGH(TABLA<<1)
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

TABLA:	.DB	243, \
			96, \
			181, \
			244, \
			102, \
			214, \
			215, \
			112, \
			247, \
			246
