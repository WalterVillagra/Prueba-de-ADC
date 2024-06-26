;
; Prueb.Adc.asm
;
; Created: 3/5/2024 20:11:53
; Author : Walter
;


; Replace with your application code
.ORG	0X0000
JMP	INICIO
.ORG	0X0002
JMP	ISR_INT0
.ORG	0X002A
JMP	ISR_ADC

.INCLUDE "division.inc"
.DSEG
		CONTADOR: .BYTE 1
		TermoDormi:	.BYTE 2
.CSEG

INICIO:
LDI	R16,HIGH(RAMEND)
OUT	SPH,R16
LDI	R16,LOW(RAMEND)
OUT	SPL,R16


        ;CONFIGURACION INT0 POR FLANCO ASCENDENTE
        LDI     R16,(1<<ISC01)|(1<<ISC00)
		STS     EICRA,R16
		LDI     R16,(1<<INT0)
		OUT     EIMSK,R16


	;CONFIGURACION DE UART
	LDI	R16,0
	STS	UCSR0A,R16
	LDI	R16,(1<<TXEN0)
	STS	UCSR0B, R16
	LDI	R16,(1<<UCSZ01)|(1<<UCSZ00)
	STS	UCSR0C,R16
	LDI	R16,103
	STS	UBRR0L,R16
	LDI	R16,0
	STS	UBRR0H,R16
	;FIN CONFIGURACION DE UART

;CONFIGURACION ADC
LDI	R16,(1<<REFS0)
STS	ADMUX,R16
LDI  R16,(1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(1<<ADATE)|(1<<ADPS2)|(1<<ADPS1)
STS	ADCSRA,R16
LDI	R16,(1<<ADTS1)
STS	ADCSRB,R16
LDI	R16,(1<<ADC0D)
STS	DIDR0,R16
;FIN CONFIGURACION ADC
sei
 
VOLVER:
		LDS     R16,CONTADOR
		CPI     R16,50
		BREQ    VERDADERO ;Si es igual a 50 se bifurca

		RJMP	VOLVER

   

	ISR_INT0:                      
        PUSH	R16
		IN		R16,SREG
		PUSH	R16
		LDS     R16,CONTADOR
		INC     R16
		STS     CONTADOR,R16
		POP		R16
		OUT		SREG,R16
		POP		R16	

		RETI

	VERDADERO:
				CLR	R16
				STS	CONTADOR,R16	;SETEA EL CONTADOR EN 0
				CALL enviar_med
     JMP	VOLVER

ISR_ADC:
PUSH	R24
PUSH	R25
PUSH	R17
IN	R17,SREG
PUSH	R17

        LDS		R24,ADCL	
        LDS 	R25,ADCH

		sts high(TermoDormi),r25	;Guarda el valor en la variable TermoDormi
		sts low(TermoDormi),r24


		LDI R17, (1<<INTF0)
		OUT 	EIFR, R17


;FIN LECTURA ADC

POP	R17
OUT	SREG,R17
POP	R17
POP	R25
POP	R24

RETi

enviar_med:
	
		lds r24,low(TermoDormi)		;carga el valor al registro para enviar
		lds r25,high(TermoDormi)
		call DESARMAR_ENVIAR1
ret

	ENVIO_UART:
        	LDI	R16,48
        	ADD	R20,R16
ESPERAR_TX:
	LDS	R16,UCSR0A
	SBRS	R16,UDRE0
	RJMP	ESPERAR_TX
	STS	UDR0,R20
	RET

DESARMAR_ENVIAR1:
;Obtenemos unidad de mil
		LDI		R23,HIGH(1000)
		LDI		R22,LOW(1000)
		CALL	DIVISION16
		MOV		R20,R24
CALL	ENVIO_UART
MOVW	R24,R26

;Obtenemos centena
		LDI		R23,HIGH(100)
		LDI		R22,LOW(100)
		CALL	DIVISION16
		MOV		R20,R24
CALL	ENVIO_UART
MOVW	R24,R26


;Obtenemos la decena
		LDI		R23,HIGH(10)
		LDI		R22,LOW(10)
		CALL	DIVISION16
		MOV		R20,R24
		CALL	ENVIO_UART

;Obtenemos la unidad
		MOV	    R20,R26	;r26 es el resto
		CALL	ENVIO_UART
	    
		RET


