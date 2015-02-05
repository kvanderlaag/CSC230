.include "m2560def.inc"


#define FCPU			16e6		; MCU clock speed in Hz (1e6 = 1MHz)
#define LCD_DAT			50		; Execute time in microseconds for data commands
#define LCD_ENA			1		; Execute time in microseconds for clock pulse
#define LCD_CLEAR		2		; Execute time for longer commands in ms
#define LCD_2X16				; LCD size in Rows x Columns.
#define SPBITS			22		; Stack pointer width in bits for return addresses.
						; Mega2560 = 22, some others = 16
#if SPBITS = 22
#define SPBITS_22
#endif


; Register definitions used in this module
.def CREG=R18					; Command or data register used in routines
.def DREG=R19					; Delay values passed to dly_ms and dly_us
.def TEMP=R16					; Mnemonics for temporary values
.def TEMP2=R17
.def RET1=R7 		; These three registers can be used to store
.def RET2=R8 		; return addresses for working with the stack
#ifdef SPBITS_22	; If your processor has a 22-bit stack pointer, define
.def RET3=R9		; a third register byte
#endif


; ***
; HD44780 LCD Driver for ATmega2560.
; (DFRobot LCD Keypad Shield v1.1, Arduino Mega2560)
;
; Author: Keegan van der Laag (jkvander@uvic.ca)
; Updated 4 February 2015
;
; ---
;
; Some code shamelessly adapted from the C implementation of this driver
; provided by Jason Corless (jcorless@uvic.ca).
; Delay loops hackishly paraphrased from Atmel's AVR C libraries.
;
; TODO:
; - Make gotoxy subroutine more robust. Add cases for locations not displayed
;   on the 16x2 LCD
; - Implement generics and conditional assembly for other pin assignments
;   and other LCD sizes.

; End Notes
; ***

; Definitions of constants for different LCD sizes.
; Shamelessly borrowed from the C driver mentioned above.
#ifdef LCD_1X8
#define LCD_COLUMN      8
#define LCD_LINE        1
#define LCD_LINE1       0x80
#endif

#ifdef LCD_1X16
#define LCD_COLUMN      16
#define LCD_LINE        1
#define LCD_LINE1       0x80
#endif

#ifdef LCD_1X20
#define LCD_COLUMN      20
#define LCD_LINE        1
#define LCD_LINE1       0x80
#endif

#ifdef LCD_1X40
#define LCD_COLUMN      40
#define LCD_LINE        1
#define LCD_LINE1       0x80
#endif

#ifdef LCD_2X8
#define LCD_COLUMN      8
#define LCD_LINE        2
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#endif

#ifdef LCD_2X12
#define LCD_COLUMN      12
#define LCD_LINE        2
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#endif

#ifdef LCD_2X16
#define LCD_COLUMN      16
#define LCD_LINE        2
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#endif

#ifdef LCD_2X20
#define LCD_COLUMN      20
#define LCD_LINE        2
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#endif

#ifdef LCD_2X24
#define LCD_COLUMN      24
#define LCD_LINE        2
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#endif

#ifdef LCD_2X40
#define LCD_COLUMN      40
#define LCD_LINE        2
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#endif

#ifdef LCD_4X16
#define LCD_COLUMN      16
#define LCD_LINE        4
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#define LCD_LINE3       (0x80 + 0x10)
#define LCD_LINE4       (0x80 + 0x50)
#endif

#ifdef  LCD_4X20
#define LCD_COLUMN      20
#define LCD_LINE        4
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#define LCD_LINE3       (0x80 + 0x14)
#define LCD_LINE4       (0x80 + 0x54)
#endif

; End of LCD Constant Definitions

; Some constant definitions for Hitachi HD44780 Command instructions.
; Can be used with lcd_cmd by pushing them onto the stack before calling.
#define cmd_CLR			0x01
#define cmd_HOM			0x02

; End of LCD Constant Definitions
; ***

; ***
; LCD Pin Definitions.
; Changing these should affect lcd_init, lcd_nbl, lcd_byte, and lcd_putchar

; Data Pins B4-B7
#define P_4 = G
#define DB4 = (1<<PG5)
#define P_5 = E
#define DB5 = (1<<PE3)
#define P_6 = H
#define DB6 = (1<<PH3)
#define P_7 = H
#define DB7 = (1<<PH4)

; Command Pins
; E (Clock) = D9 = H6
#define P_ENA = H
#define ENABLE = (1<<PH6)
; RS (Cmd/Data) = D8 = H5
#define P_RS = H
#define REGSEL = (1<<PH5)

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

	lds TEMP, PINH
	cbr TEMP, (1<<PH3)+(1<<PH4)
	sbrc CREG, 7
	sbr TEMP, (1<<PH4)
	sbrc CREG, 6
	sbr TEMP, (1<<PH3)
	sts PORTH, TEMP

	; CREG(5) -> PORTE(3)
	lds TEMP, PINE+0x20
	cbr TEMP, (1<<PE3)
	sbrc CREG, 5
	sbr TEMP, (1<<PE3)
	sts PORTE+0x20, TEMP

	; CREG(4) -> PORTG(5)
	lds TEMP, PING+0x20
	cbr TEMP, (1<<PG5)
	sbrc CREG, 4
	sbr TEMP, (1<<PG5)
	sts PORTG+0x20, TEMP

	; Pulse clock high
	lds TEMP, PINH
	sbr TEMP, (1<<PH6)
	sts PORTH, TEMP 
	
	; Wait for LCD_ENA microseconds
	ldi DREG, 0x05
	call dly_us
	
	; Pulse clock low.
	lds TEMP, PINH
	cbr TEMP,  (1<<PH6)
	sts PORTH, TEMP
 
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
	#ifdef SPBITS_22
	pop RET3
	#endif
	pop CREG
	#ifdef SPBITS_22
	push RET3
	#endif
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
	#ifdef SPBITS_22
	pop RET3
	#endif
	pop RET2
	pop RET1
	push CREG
	push RET1
	push RET2
	#ifdef SPBITS_22
	push RET3
	#endif
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
	#ifdef SPBITS_22
	pop RET3
	#endif
	pop CREG
	#ifdef SPBITS_22
	push RET3
	#endif
	push RET2
	push RET1

	; Set RS = 0
	lds TEMP, PINH
	cbr TEMP, (1<<PH5)
	sts PORTH, TEMP
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
	#ifdef SPBITS_22
	pop RET3
	#endif
	pop CREG
	#ifdef SPBITS_22
	push RET3
	#endif
	push RET2
	push RET1
	; Set RS = 1 (Write data to current DDRAM address)
	lds TEMP, PINH
	sbr TEMP, (1<<PH5)
	sts PORTH, TEMP
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
	#ifdef SPBITS_22
	pop RET3
	#endif
	pop TEMP
	#ifdef SPBITS_22
	push RET3
	#endif
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
	lds TEMP, DDRH
	sbr TEMP, (1<<PH3)+(1<<PH4)+(1<<PH5)+(1<<PH6)
	sts DDRH, TEMP
	lds TEMP, PINH
	cbr TEMP, (1<<PH3)+(1<<PH4)+(1<<PH5)+(1<<PH6)
	sts PORTH, TEMP
	
	lds TEMP, DDRE+0x20
	sbr TEMP, (1<<PE3)
	sts DDRE+0x20, TEMP
	lds TEMP, PINE+0x20
	cbr TEMP, (1<<PE3)
	sts PORTE+0x20, TEMP

	lds TEMP, DDRG+0x20
	sbr TEMP, (1<<PG5)
	sts DDRG+0x20, TEMP
	lds TEMP, PING+0x20
	cbr TEMP, (1<<PG5)
	sts PORTG+0x20, TEMP

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
	ldi TEMP, 0x0F		; Display On, Cursor On, Blink On
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
		; 0xFD * DREG * 16
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
	#ifdef SPBITS_22
	pop RET3
	#endif

	pop ZL
	pop ZH

	pop XL
	pop XH

	#ifdef SPBITS_22
	push RET3
	#endif
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
; Initialization values for String
init:	.db		0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x2C, 0xA0, 0x57 
init2:	.db		0x6F, 0x72, 0x6C, 0x64, 0x21, 0x00, 0x00, 0x00
init3:	.db		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
init4:	.db		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00



; ***
; Memory Allocation

.dseg
	str: .byte 33 ; Reserve 33 characters worth of memory (16x2 character LCD),
				  ; lcd_puts traverses memory until it finds a 0x00 byte. For
				  ; the love of god, make sure that (str+0x20) = 0x00 when you
				  ; set it.

	cursor_xy:	.byte 1 ; Reserve one byte for the current cursor position.
						; cursor_xy = rrrrcccc, where R is row (0x00 or (0x01)
						; and C is column (0x00 to 0xFF, for our display)
						; lcd_gotoxy handles memory addresses for this grid.
						; (Theoretically, one could have 16 rows and 16 columns;
						; The HD44780 doesn't actually support that many, but hey.
