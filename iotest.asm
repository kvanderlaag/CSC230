.equ MAX=0x3F
.def VALUE=R22
.include "m2560def.inc"

.def TEMP=R17


#define CLOCK 16.0e6 	; Clock @ 16 MHz
.equ 	PRESCALE=0b100 ; timer prescale 1/256
.equ	PRECALE_DIV=256	; (As such.)
.equ 	TOP=46875		; top is 31250, or 0.75s delay
.equ	WGM=0b0100		; Waveform generation mode CTC

.cseg

;	Initialize the timer
	ldi TEMP, high(TOP)
	sts OCR1AH, temp
	ldi TEMP, LOW(top)
	sts OCR1AL, TEMP
	ldi TEMP, ((WGM&0b11) << WGM10) ; get the lower two bits of Waveform Generation
									; mode
	sts TCCR1A, temp
	; upper 2 bits of WGM and clock select
	ldi TEMP, ((WGM>>2) << WGM12) | (PRESCALE)
	sts TCCR1B, TEMP	; start counter

 	ldi VALUE, 0x00
;	Initialize PORTB and PORTL as outputs on 1/3 and 1/3/5/7 respectively
	lds R16, DDRB+0x20
	sbr R16, (1<<PB1)+(1<<PB3)
	sts DDRB+0x20, R16
	lds R16, DDRL
	sbr R16, (1<<PL1)+(1<<PL3)+(1<<PL5)+(1<<PL7)
	sts DDRL, R16
;	Initialize PORTB and PORTL to have pins 1/3 and 1/3/5/7 set off
	lds R16, PINB+0x20
	cbr R16, (1<<PB1)+(1<<PB3) 
	sts PORTB+0x20, R16
	lds R16, PINL
	cbr R16, (1<<PL1)+(1<<PL3)+(1<<PL5)+(1<<PL7)	
	sts PORTL, R16

loop:
	lds TEMP, TIFR1+0x20 ; get timer interrupt flags
	andi TEMP, 1<<OCF1A
	breq skip	;	main program flow when timer not matched

;match:
	CALL ledOut
	cpi VALUE, MAX
	breq done
	inc VALUE
	lds TEMP, TIFR1+0x20
	sbr TEMP, (1<<OCF1A)
	sts TIFR1+0x20, TEMP
skip:

	; as it turns out, there's nothing else to do, but if there was, you'd
	; put it here.
	jmp loop

ledOut:
	lds R16, PINB+0x20
	cbr R16, 0b00001010
	sbrc VALUE, 0
	sbr R16, (1<<PB1)
	sbrc VALUE, 1
	sbr R16, (1<<PB3)
	sts PORTB+0x20, R16
	nop
	lds R16, PINL
	cbr R16, 0b10101010
	sbrc VALUE, 2
	sbr R16, (1<<PL1)
	sbrc VALUE, 3
	sbr R16, (1<<PL3)
	sbrc VALUE, 4
	sbr R16, (1<<PL5)
	sbrc VALUE, 5
	sbr R16, (1<<PL7)
	sts PORTL, R16
	ret

done: jmp done
