.equ MAX=0x3F
.def VALUE=R22
.def DLY1=R17
.def DLY2=R18
.def DLY3=R19
.include "m2560def.inc"


.cseg
	ldi VALUE, 0x00
	lds R16, DDRB+0x20
	sbr R16, (1<<PB1)+(1<<PB3)
	sts DDRB+0x20, R16
	lds R16, DDRL
	sbr R16, (1<<PL1)+(1<<PL3)+(1<<PL5)+(1<<PL7)
	sts DDRL, R16
	lds R16, PINB+0x20
	cbr R16, (1<<PB1)+(1<<PB3) 
	sts PORTB+0x20, R16
	lds R16, PINL
	cbr R16, (1<<PL1)+(1<<PL3)+(1<<PL5)+(1<<PL7)	
	sts PORTL, R16

loop:
	CALL ledOut
	CALL delay
	cpi VALUE, MAX
	breq done
	inc VALUE
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

delay:
	ldi DLY1, 0x1F
del1:
	cpi DLY1, 0x00
	breq dlyEnd
	dec DLY1
	ldi DLY2, 0xFF
del2:
	cpi DLY2, 0x00
	breq del1
	ldi DLY3, 0xFF
del3:

	dec DLY3
	cpi DLY3, 0x00
	brne del3

	dec DLY2
	jmp del2
dlyEnd:
	ret

done: jmp done
