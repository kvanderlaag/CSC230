; ***
; HD44780 LCD Driver for ATmega2560.
; (DFRobot LCD Keypad Shield v1.1, Arduino Mega2560)
;
; Author: Keegan van der Laag (jkvander@uvic.ca)
; Updated 8 February 2015
;
; ---
;
; Some code shamelessly adapted from the C implementation of this driver
; provided by Jason Corless (jcorless@uvic.ca).
; Delay loops hackishly paraphrased from Atmel's AVR C libraries.
;
; End Notes
; ***

.include "m2560def.inc"


; Define the LCD size in rows x columns. Constants are conditionally
; determined based on this, and should be compatible with any HD44780
; controlled display.
#define LCD_2X16






; ***
; LCD Pin Definitions.
; Changing these should affect lcd_init, lcd_nbl, lcd_byte, and lcd_putchar

; Data Pins B4-B7

.equ	LCD_PORT_D4  =  PORTG
.equ	LCD_PORT_D5  =	PORTE
.equ	LCD_PORT_D6  =	PORTH
.equ	LCD_PORT_D7  =	PORTH
	
.equ	PIN_D4	  =		5
.equ	PIN_D5	  =		3
.equ	PIN_D6	  =		3
.equ	PIN_D7	  =		4

.equ	LCD_PORT_ENA =	PORTH
.equ 	LCD_PORT_RS  =	PORTH

.equ	PIN_ENA	  =		6
.equ	PIN_RS	  =		5

; Include LCD Driver Constants and Conditionals
.include "LCDdefs.inc"

; ***
; End of LCD Pin Definitions



; End of LCD Constant Definitions
; ***

;Inline

; End Inline


; End of Pin Definitions
; ***


; ***
; Code Segment
.cseg


; **
; Program Initialization/Setup

	call lcd_init		; call lcd_init to Initialize the LCD

	ldi TEMP, high(str)	; Push the data memory address 
	push TEMP		; of str to the stack
	ldi TEMP, low(str)
	push TEMP
	ldi TEMP, high(init<<1)	; Push the address of init, shifted for
	push TEMP		; program memory access, to the stack
	ldi TEMP, low(init<<1)
	push TEMP
	call str_init		; Call str_init to initialize data memory address
				; str with the contents of program memory segment
				; init


	call lcd_puts		; Call lcd_puts to output the initialized string
				; to the LCD. For demonstration purposes only.
				; May be commented without impacting LCD functionality.

; **
; Main Program Loop
mainloop:


	jmp mainloop
; ** 
; End of Main Program Loop




subroutinedefinitions: jmp subroutinedefinitions 	; Just in case.

; *** ***
; LCD Controller Subroutine Definitions
;
; * LCD Subroutines *	
; lcd_nbl     - 	Take byte from stack. Send high nibble to LCD. Return byte.
; lcd_byte    - 	Take byte from stack. Push to lcd_nbl. Swap nibbles of byte, push to stack.
;			call lcd_nbl
; lcd_cmd     - 	Take byte from stack. Set RS pin to 0 (command). Push byte to LCD
;			through lcd_byte.
; lcd_putchar - 	Take byte from stack. Set RS to 1 (write). Push byte to lcd_byte.
;			Increment cursor_xy.
; lcd_puts    - 	Take two-byte address of string from stack. Set X pointer to address.
;			Push (X) to stack. Call lcd_putchar.
; lcd_gotoxy  -		Take byte from stack. Byte takes form YYYYXXXX. Update cursor_xy to byte.
;			High nibble is row value, low nibble is column. Use LCD definitions to calculate 
;			memory address for location on display. Push address to stack. Call lcd_cmd. 
;			Update cursor_xy to byte.
; lcd_clr     -		Push 
;
;
; * Delay Subroutines *
; dly_us      -		Busy-wait delay loop for ~(DREG) microseconds. (0 <= (DREG) <= 255)
; dly_ms      -		Busy-wait delay loop for ~(DREG) milliseconds (0 <= (DREG) <= 15)
; *            *


; **
; lcd_nbl : 		Send high nibble of CREG to LCD. Pulses clock.
;
; Registers:	CREG	-	Register for grabbing from stack..
;				TEMP	-	Temporary value. MODIFIED.
;				DREG    -	Passed to dly_us. MODIFIED.
lcd_nbl:
	; CREG(7, 6) -> PORTH(4, 3)

	lds TEMP, PINS_D4
	cbr TEMP, (1<<PIN_D4)
	sbrc CREG, 4
	sbr TEMP, (1<<PIN_D4)
	sts PORT_D4, TEMP

	lds TEMP, PINS_D5
	cbr TEMP, (1<<PIN_D5)
	sbrc CREG, 5
	sbr TEMP, (1<<PIN_D5)
	sts PORT_D5, TEMP

	lds TEMP, PINS_D6
	cbr TEMP, (1<<PIN_D6)
	sbrc CREG, 6
	sbr TEMP, (1<<PIN_D6)
	sts PORT_D6, TEMP

	lds TEMP, PINS_D7
	cbr TEMP, (1<<PIN_D7)
	sbrc CREG, 7
	sbr TEMP, (1<<PIN_D7)
	sts PORT_D7, TEMP

	; Pulse clock high
	lds TEMP, PINS_ENA
	sbr TEMP, (1<<PIN_ENA)
	sts PORT_ENA, TEMP 
	
	; Wait for LCD_ENA microseconds
	ldi DREG, 0x05
	call dly_us
	
	; Pulse clock low.
	lds TEMP, PINS_ENA
	cbr TEMP,  (1<<PIN_ENA)
	sts PORT_ENA, TEMP
 
	; Return
	ret
; **


; **
; lcd_byte :   	 	Send eight bits of (dat) to LCD. Calls lcd_nbl.
;
; Registers:	CREG	-	Command Register. Loads from (dat). MODIFIED.
;				DREG	-	Passed to dly_us. MODIFIED.
;				TEMP	-	Temporary value. MODIFIED.
; Memory :		dat		-	Input. Data sent to LCD. 1 byte. Unmodified.
lcd_byte:
	; Get stack data into CREG
	pop RET1
	pop RET2
	.if SPBITS > 16
	pop RET3
	.endif
	pop CREG
	.if SPBITS > 16
	push RET3
	.endif
	push RET2
	push RET1
	; Send high nibble
	call lcd_nbl
	; Wait LCD_DAT microseconds for command to finish.
	ldi DREG, LCD_DAT
	call dly_us
	; Send low nibble of CREG
	swap CREG
	call lcd_nbl
	; Wait LCD_DAT microseconds for command to finish,
	ldi DREG, LCD_DAT
	call dly_us
	swap CREG
	.if SPBITS > 16
	pop RET3
	.endif
	pop RET2
	pop RET1
	push CREG
	push RET1
	push RET2
	.if SPBITS > 16
	push RET3
	.endif
	ret
; **


; **
; lcd_cmd :			Set RS pin on LCD to 0 (Command.) Send byte (dat).
;
; Registers:	TEMP	-	Temporary value. MODIFIED.
;				DREG	-	Passed to dly_ms. MODIFIED.
;				CREG	-	Retrieved from lcd_byte. Swapped. MODIFIED.
;				
lcd_cmd:
	pop RET1
	pop RET2
	.if SPBITS > 16
	pop RET3
	.endif
	pop CREG
	.if SPBITS > 16
	push RET3
	.endif
	push RET2
	push RET1

	; Set RS = 0
	lds TEMP, PINS_RS
	cbr TEMP, (1<<PIN_RS)
	sts PORT_RS, TEMP
	; Send commnand byte (dat)
	push CREG
	call lcd_byte
	; Swap CREG used in lcd_byte back to original state.
	; On CREG = 0x01, 0x02, or 0x03, command takes longer to execute.
	; Wait LCD_CLEAR milliseconds before continuing.
	pop CREG
	cpi CREG, 0x04
	brsh cmd_fin
	ldi DREG, LCD_CLEAR
	call dly_ms

cmd_fin:
	ret
; **


; **
; lcd_putchar : 	Set RS pin on LCD to 1 (write data). Send character in
;					byte (dat).
;
; Registers:	TEMP		-	Temporary value. MODIFIED.
; Memory:		cursor_xy 	-	Current cursor position. Updates after send. MODIFIED.
;				dat			-	Character data. Input. Unmodified.
lcd_putchar:
	pop RET1
	pop RET2
	.if SPBITS > 16
	pop RET3
	.endif
	pop CREG
	.if SPBITS > 16
	push RET3
	.endif
	push RET2
	push RET1
	; Set RS = 1 (Write data to current DDRAM address)
	lds TEMP, PINS_RS
	sbr TEMP, (1<<PIN_RS)
	sts PORT_RS, TEMP
	; Send character data in byte (dat) using lcd_byte
	push CREG
	call lcd_byte
	pop CREG
	; Update the current cursor position in (cursor_xy) to reflect
	; increment.
	lds TEMP, cursor_xy
	inc TEMP
	; If incrementing TEMP increases it past 0x0F, use lcd_gotoxy
	; to update DDRAM address for new line.
	cpi TEMP, 0x10
	breq newln
	; If incrementing TEMP increases it past 0x1F (off the edge of line 2)
	; then set it back to 0x00 (wrap to beginning) and update DDRAM address
	; using lcd_gotoxy
	cpi TEMP, 0x20
	breq retln
	; If not (new cursor position is just the next position on the same line,)
	; update cursor position
	sts cursor_xy, TEMP
	ret
newln:
	push TEMP
	call lcd_gotoxy
	ret
retln:
	clr TEMP
	push TEMP
	call lcd_gotoxy
	ret
; **
	

lcd_puts:		; Load two-byte address in str into X register
				
		ldi ZH, high(str)
		ldi ZL, low(str)
	parse:
		ld TEMP2, Z+
		cpi TEMP2, 0x00
		breq donestr
		push TEMP2
		call lcd_putchar
		rjmp parse
	donestr:
		ret


; **
; lcd_gotoxy :		Use yyyyxxxx stored in (cursor_xy) to determine
;					memory address in DDRAM. Send command to set address
;					to LCD.
; Register:		TEMP	-	Temporary value. MODIFIED.
;				TEMP2	-	Temporary value. MODIFIED.
;				R20		-	Temporary value. MODIFIED.
;				CREG	-	Used in call to lcd_cmd. MODIFIED.
;				DREG	-	Used in call to lcd_cmd. MODIFIED.
; Memory:		cursor_xy	-	Cursor position in Row/Column format. Input.
;								Unmodified.
;				dat			-	Command data sent to LCD to update DDRAM address.
;								MODIFIED.
lcd_gotoxy:
	pop RET1
	pop RET2
	.if SPBITS > 16
	pop RET3
	.endif
	pop TEMP
	.if SPBITS > 16
	push RET3
	.endif
	push RET2
	push RET1
	
	sts cursor_xy, TEMP
	sbrc TEMP, 4
	ldi TEMP2, LCD_LINE2
	sbrs TEMP, 4
	ldi TEMP2, LCD_LINE1
	; cursor_xy
	; High -> Row. (0= Row 1, 1= Row 2)
	; Low -> Col (0= Col 1, F= Col 16)
	; Line 1 = 0x80
	; Line 2 = 0x80 + 0x40

	; Clear row nibble of coordinates
	andi TEMP, 0x0F
	; Add column value to selected row value
	add TEMP, TEMP2
	; Memory address is command data
	push TEMP
	call lcd_cmd




	ret
; **


; ** 
; lcd_clr : 		Clear the LCD, return cursor to (0,0)
; Registers :	TEMP	-	Temporary value. MODIFIED.
;				CREG	-	Used in lcd_cmd. MODIFIED.
;				DREG	-	Used in lcd_cmd. MODIFIED.
; Memory :		dat			-	Command Data. MODIFIED.
;				cursor_xy	-	Cursor position. Updated. MODIFIED.
lcd_clr:

	ldi TEMP, cmd_CLR
	push TEMP
	call lcd_cmd
	; Update cursor position,
	ldi TEMP, 0x00
	sts cursor_xy, TEMP

	ret
; ** End lcd_clr


; ** 
; lcd_init: Initialize our LCD
; 
; TO DO:
;	- Document this.
;	- Abstract I/O addresses to account for different pin assignment.
;	
;	For now, it works.
lcd_init:
	
	; Set Data Direction Register bits to output for LCD data 4-7,
	; E, and RS.
	; TODO: Abstract this for different pin assignments.
	lds TEMP, DDR_D4
	sbr TEMP, (1<<PIN_D4)
	sts DDR_D4, TEMP
	lds TEMP, PINS_D4
	cbr TEMP, (1<<PIN_D4)
	sts PORT_D4, TEMP

	lds TEMP, DDR_D5
	sbr TEMP, (1<<PIN_D5)
	sts DDR_D5, TEMP
	lds TEMP, PINS_D5
	cbr TEMP, (1<<PIN_D5)
	sts PORT_D5, TEMP

	lds TEMP, DDR_D6
	sbr TEMP, (1<<PIN_D6)
	sts DDR_D6, TEMP
	lds TEMP, PINS_D6
	cbr TEMP, (1<<PIN_D6)
	sts PORT_D6, TEMP

	lds TEMP, DDR_D7
	sbr TEMP, (1<<PIN_D7)
	sts DDR_D7, TEMP
	lds TEMP, PINS_D7
	cbr TEMP, (1<<PIN_D7)
	sts PORT_D7, TEMP
	
	lds TEMP, DDR_RS
	sbr TEMP, (1<<PIN_RS)
	sts DDR_RS, TEMP
	lds TEMP, PINS_RS
	cbr TEMP, (1<<PIN_RS)
	sts PORT_RS, TEMP

	lds TEMP, DDR_ENA
	sbr TEMP, (1<<PIN_ENA)
	sts DDR_ENA, TEMP
	lds TEMP, PINS_ENA
	cbr TEMP, (1<<PIN_ENA)
	sts PORT_ENA, TEMP

	; Initialize display to specs listed in HD44780 data sheet.
	; Generally very conservative with timing; speed may be improved
	; with some experimentation.

	ldi DREG, 0xF	; wait 15ms to power up
	call dly_ms
	ldi CREG, 0x30	; send the first half of 0x30 (8-bit mode) three times
	call lcd_nbl
	ldi DREG, 0x5	; wait 5ms before sending the second set command
	call dly_ms
	ldi CREG, 0x30
	call lcd_nbl
	ldi R21, 0x7	; wait 15ms (max for dly_ms) 7 times is ~100ms
dly_init:			
	ldi DREG, 0xF	; wait 100ms before sending the last one
	call dly_ms
	dec R21  		; dec temp counter (not used in dly_ms)
	brne dly_init	; if 0, send the nibble again
    ldi CREG, 0x30
	call lcd_nbl
	ldi DREG, LCD_DAT	; wait LCD_DATus before sending more commands
	call dly_us
	ldi CREG, 0x20		; load 4-bit mode command into CREG
	call lcd_nbl
	ldi DREG, LCD_DAT
	call dly_us
	ldi TEMP, 0x28		; 4-bit, 2-line, 5x8 dot
	push TEMP
	call lcd_cmd
	ldi TEMP, 0x08		; Display Off, Cursor Off, Blink Off
	push TEMP
	call lcd_cmd
	ldi TEMP, 0x01		; Display Clear
	push TEMP
	call lcd_cmd
	ldi DREG, 0x02
	call dly_ms
	ldi TEMP, 0x06		; Increment cursor, no Display Shift
	push TEMP
	call lcd_cmd
	ldi TEMP, 0x0C		; Display On, Cursor On, Blink On
	push TEMP
	call lcd_cmd
	ldi TEMP, 0x00
	sts cursor_xy, TEMP ; Update cursor position to (0,0)

	ret
; **


; ** 
; dly_us : 			Busy-Wait loop for DREG microseconds
;
; Registers:	DREG	-	Input. Used as counter. MODIFIED.
;				TEMP	-	Counter. MODIFIED.
dly_us:		; Waits DREG microseconds in a busy-wait loop.
			; DREG can be any number of microseconds from 0 to 255.
dlyus_dreg:	ldi TEMP, 0x05
dlyus_in:	dec TEMP
			brne dlyus_in	
			dec DREG
			brne dlyus_dreg

	ret
; **


; ** 
; dly_ms:			Busy-wait loop for about DREG milliseconds.
;					Hackily adapted from the delay_ms function
;					in the AVR C libraries.
;
; Register : 	DREG	-	Input. Number of ms to wait. MODIFIED.
;				YH:YL	-	16-bit counter. MODIFIED.
;				TEMP	-	Temporary value. MODIFIED.
dly_ms:
		; TO DO: Consolidate or remove this Comment Section
		; 1ms = FCPU / 1000 instructions
		; This loop is 4 instructions per iteration.
		; DREG = number of milliseconds to wait, in the high nibble
		; 1ms = FCPU/1000/loop instructions
		; 1ms = 16000/4 = 4000 iterations
		; Y =  DREG*(4000), 4000 = 2048 + 1024 + 512 + 256 + 128 + 64 + 16
		;						4000 =		    1111 1101 0000
		;                               DREG     F    D    0
		; 0xFD * DREG * FCPU/1e6
		; DREG is 0x00 to 0xF0, low nibble is always ignored
		; This means that delays up to about 15ms can be achieved using
		; A 16-bit register pair. (Y-register)

		; YH = DREG ^ 0x0F
		; YL = 0xFD
		; call led_dly
		ldi TEMP, 0xFD
		mul DREG, TEMP
		mov TEMP, R1
		swap TEMP
		andi TEMP, 0xF0
		mov YH, TEMP
		mov TEMP, R0
		swap TEMP
		mov TEMP2, TEMP
		andi TEMP, 0xF0
		andi TEMP2, 0x0F
		mov YL, TEMP
		or YH, TEMP2


dlyms:	sbiw YH:YL, 1
		brne dlyms
	ret
; End dlyms

str_init:
	pop RET1
	pop RET2
	.if SPBITS > 16
	pop RET3
	.endif

	pop ZL
	pop ZH

	pop XL
	pop XH

	.if SPBITS > 16
	push RET3
	.endif
	push RET2
	push RET1

initloop:
	lpm TEMP, Z+
	cpi TEMP, 0x00
	breq initdone
	st X+, TEMP
	jmp initloop
initdone:
	clr TEMP
	st X+, TEMP

	ret



; *** ***
; End of Subroutine Definitions


; ***
; Initialization values ro4for String
init:	.db		"Hello, World!", '\0'



; ***
; Memory Allocation

.dseg

	str: .byte lcd_length ;

	cursor_xy:	.byte 1 ; Reserve one byte for the current cursor position.
						; cursor_xy = rrrrcccc, where R is row (0x00 or (0x01)
						; and C is column (0x00 to 0xFF, for our display)
						; lcd_gotoxy handles memory addresses for this grid.
						; (Theoretically, one could have 16 rows and 16 columns;
						; The HD44780 doesn't actually support that many, but hey.
