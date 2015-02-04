.include "m2560def.inc"

.def CREG=R18
.def DREG=R19
.def TEMP=R16
.def TEMP2=R17

#define FCPU			16e6	; 16MHz
#define LCD_DAT			50		; 50us for data commands
#define LCD_ENA			1		; 1us for enable bit on/off
#define LCD_CLEAR		2000	; 2000us, or 2ms

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
; - Remove gratuitous profanity from comments
; - Document memory locations and registers used in subroutines
; - Clean up memory allocation: Use of "dat" questionable.
; - Make gotoxy subroutine more robust. Add cases for locations not displayed
;   on the 16x2 LCD
; - Implement generics and conditional assembly for other pin assignments
;   and other LCD sizes.

; End Notes
; ***

; ****
; Some tedious definitions for LCD sizes

//#define LCD_1X8
//#define LCD_1X16
//#define LCD_1X20
//#define LCD_1X40
//#define LCD_2X9
//#define LCD_2X12
#define LCD_2X16
//#define LCD_2X20
//#define LCD_2X24
//#define LCD_2X40
//#define LCD_4X16
//#define LCD_4X20

//#ifdef LCD_1X8
//#define LCD_COLUMN      8
//#define LCD_LINE        1
//#define LCD_LINE1       0x80
//#endif

//#ifdef LCD_1X16
//#define LCD_COLUMN      16
//#define LCD_LINE        1
//#define LCD_LINE1       0x80
//#endif

//#ifdef LCD_1X20
//#define LCD_COLUMN      20
//#define LCD_LINE        1
//#define LCD_LINE1       0x80
//#endif

//#ifdef LCD_1X40
//#define LCD_COLUMN      40
;#define LCD_LINE        1
;#define LCD_LINE1       0x80
;#endif

;#ifdef LCD_2X8
;#define LCD_COLUMN      8
;#define LCD_LINE        2
;#define LCD_LINE1       0x80
;#define LCD_LINE2       (0x80 + 0x40)
;#endif

;#ifdef LCD_2X12
;#define LCD_COLUMN      12
;#define LCD_LINE        2
;#define LCD_LINE1       0x80
;#define LCD_LINE2       (0x80 + 0x40)
;#endif

#ifdef LCD_2X16
#define LCD_COLUMN      16
#define LCD_LINE        2
#define LCD_LINE1       0x80
#define LCD_LINE2       (0x80 + 0x40)
#endif

;#ifdef LCD_2X20
;#define LCD_COLUMN      20
;#define LCD_LINE        2
;#define LCD_LINE1       0x80
;#define LCD_LINE2       (0x80 + 0x40)
;#endif

;#ifdef LCD_2X24
;#define LCD_COLUMN      24
;#define LCD_LINE        2
;#define LCD_LINE1       0x80
;#define LCD_LINE2       (0x80 + 0x40)
;#endif

;#ifdef LCD_2X40
;#define LCD_COLUMN      40
;#define LCD_LINE        2
;#define LCD_LINE1       0x80
;#define LCD_LINE2       (0x80 + 0x40)
;#endif

;#ifdef LCD_4X16
;#define LCD_COLUMN      16
;#define LCD_LINE        4
;#define LCD_LINE1       0x80
;#define LCD_LINE2       (0x80 + 0x40)
;#define LCD_LINE3       (0x80 + 0x10)
;#define LCD_LINE4       (0x80 + 0x50)
;#endif

;#ifdef  LCD_4X20
;#define LCD_COLUMN      20
;#define LCD_LINE        4
;#define LCD_LINE1       0x80
;#define LCD_LINE2       (0x80 + 0x40)
;#define LCD_LINE3       (0x80 + 0x14)
;#define LCD_LINE4       (0x80 + 0x54)
;#endif

//#define	LCD_TIME_ENA    1.0             // 1?s
//#define LCD_DAT    50            // 50us
//#define LCD_TIME_CLR    2000.0          // 2ms

// End of Tedious Definitions
; ***

; ***
; Now let's do some tedious definitions for LCD command values!

#define cmd_CLR			0x01
#define cmd_HOM			0x02

; End of more tedious definitions!
; ***

; Data Pins B4-B7
; B4=D4=G5
; B5=D5=E3
; B6=D6=H3
; B7=D7=H4

; Command Pins
; E (Clock) = D9 = H6
; RS (Cmd/Data) = D8 = H5
; RW (Read/Write) = Gnd = 0

; Initilization Process is as follows:
; 1. Wait for ~50ns from Arduino powerup to allow
; HD44780 to power up
; 2. Send 4-bit enable command three times
;    (This is RS=0, B7=0, B6=0, B5=1, B4=1)
;	 So, set RS and B4-7, then toggle E on and off 3
;	 times for three clock cycles of the HD44780
; 3. Now set interface mode to 4-bit
;		RS=0, B7=0, B6=0, B5=1, B4=0
; 4. Then set Display Lines, Font Size
;		RS=0 B7=0 B6=0 B5=1 B4=0
;		RS=0 B7=1 B6=0, B5=0, B4=0
; 5. Then set Display Off, Cursor On, Blink On
;		RS=0 B7=0 B6=0 B5=0 B4=0
;		RS=0 B7=1 B6=D=0 B5=C=1 B4=B=1
; 6. Display Clear
;		RS=0 B7=0 B6=0 B5=0 B4=0
;		RS=0 B7=0 B6=0 B5=0 B4=1
; 7. Entry Mode Set
;		RS=0 B7=0 B6=0 B5=0 B4=0
;		RS=0 B7=0 B6=1 B5=1 B4=0
; Then you should have a display ready to accept commands.


; ** OKAY LET'S ACTUALLY DO SOME SHIT
.cseg

	call lcd_init	; Initialize the fucking LCD

	ldi TEMP, 0x13
	sts cursor_xy, TEMP
	call lcd_gotoxy
	
	ldi XH, high(str)
	ldi XL, low(str)
	ldi TEMP, 0x46
	st X+, TEMP
	ldi TEMP, 0x75
	st X+, TEMP
	ldi TEMP, 0x63
	st X+, TEMP
	ldi TEMP, 0x6B
	st X+, TEMP
	ldi TEMP, 0xA0
	st X+, TEMP
	ldi TEMP, 0x59
	st X+, TEMP
	ldi TEMP, 0x6F
	st X+, TEMP
	ldi TEMP, 0x75
	st X+, TEMP
	ldi TEMP, 0x21
	st X+, TEMP
	call lcd_puts

mainloop:			; Main program shit

	; There is nothing here. How sad.	

	jmp mainloop	; Go do main program shit again




finito: jmp finito ; JUST IN CASE you fucking morons decide to do something
				   ; stupid in mainloop

; *** ***
; HEY THESE ARE ALL THE BULLSHIT FUNCTIONS FOR THE LCD CONTROLLER
; Don't fuck with these, and don't let your code run into them.

lcd_nbl: ; sends the high nibble of CREG, pulses clock off after
	lds TEMP, PINH
	cbr TEMP, (1<<PH3)+(1<<PH4)
	sbrc CREG, 7
	sbr TEMP, (1<<PH4)
	sbrc CREG, 6
	sbr TEMP, (1<<PH3)
	sts PORTH, TEMP

	;CREG	( 7)( 6)( 5)( 4)( 3)( 2)( 1)( 0)
	; 		(H4)(H3)(E3)(G5)( x)( x)( x)( x)
	lds TEMP, PINE+0x20
	cbr TEMP, (1<<PE3)
	sbrc CREG, 5
	sbr TEMP, (1<<PE3)
	sts PORTE+0x20, TEMP

	lds TEMP, PING+0x20
	cbr TEMP, (1<<PG5)
	sbrc CREG, 4
	sbr TEMP, (1<<PG5)
	sts PORTG+0x20, TEMP

	lds TEMP, PINH
	sbr TEMP, (1<<PH6)
	sts PORTH, TEMP 	; pulse the fucking clock
	
	; Wait for LCD_ENA microseconds.(LCD_ENA for our LCD is 1)
	ldi DREG, 0x05
	call dly_us
	lds TEMP, PINH			; These two instructions occupy the last two NOPs
	cbr TEMP,  (1<<PH6)    ; Of the 1us delay.
	sts PORTH, TEMP
 

	ret

lcd_byte: ; gets the command stored in byte dat into CREG,
		  ; uses lcd_nbl to send the high nibble, then shifts the low nibble
		  ; into the high nibble, clears the low nibble, and sends the new high nibble.
	lds CREG, dat
	call lcd_nbl
	ldi DREG, 0x32
	call dly_us
	swap CREG
	call lcd_nbl
	ldi DREG, 0x32		; wait 50us for the command to finish.
	call dly_us
						; the ret occupies the last instruction in the delay
	ret

lcd_cmd:		; set RS=0, sends the command in byte dat
	lds TEMP, PINH
	cbr TEMP, (1<<PH5)
	sts PORTH, TEMP
	call lcd_byte
	swap CREG
	cpi CREG, 0x04
	brsh cmd_fin
	ldi DREG, 0x02
	call dly_ms
cmd_fin:
	ret

lcd_putchar:	; set RS=1, send high nibble of DAT, pulse clock off,
		  		; send low nibble of DAT, pulse clock off.
	lds TEMP, PINH
	sbr TEMP, (1<<PH5)
	sts PORTH, TEMP
	call lcd_byte
	lds TEMP, cursor_xy
	inc TEMP
	cpi TEMP, 0x10
	breq newln
	cpi TEMP, 0x20
	breq retln
	sts cursor_xy, TEMP
	ret
newln:
	sts cursor_xy, TEMP
	call lcd_gotoxy
	ret
retln:
	clr TEMP
	sts cursor_xy, TEMP
	call lcd_gotoxy
	ret
	
	

lcd_puts:		; Load two-byte address in str into X register
				
		ldi XH, high(str)
		ldi XL, low(str)
	parse:
		ld TEMP, X+
		cpi TEMP, 0
		breq donestr
		sts dat, TEMP
		call lcd_putchar
		rjmp parse
	donestr:
		ret


lcd_gotoxy:
	lds TEMP, cursor_xy
	ldi TEMP2, 0x80
	ldi R20, 0x40
	; cursor_xy
	; High -> Row. (0= Row 1, 1= Row 2)
	; Low -> Col (0= Col 1, F= Col 16)
	; Line 1 = 0x80
	; Line 2 = 0x80 + 0x40
	sbrc TEMP, 4
	add TEMP2, R20
	andi TEMP, 0x0F
	add TEMP2, TEMP
	sts dat, TEMP2
	call lcd_cmd
	ret


; ** lcd_clr: Clear the LCD, return cursor to (0,0)
lcd_clr:		; Sends the clear command to the LCD, returns cursor to home
	ldi TEMP, cmd_CLR
	sts dat, TEMP
	call lcd_cmd
	ret
; ** End lcd_clr


; ** lcd_init: Initialize our LCD

lcd_init:		; Initializes LCD.as per specs above

	; First let's set all of our pin data directions correctly.

	; H3-H6 = output
	; E3 = output
	; G5 = output
	; I'm also just going to turn those pins off right away because seriously
	; who even knows what the fuck is going on right now.
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

	; Okay, now let's actually initialize this fucker

	ldi DREG, 0xF	; wait 15ms to power up
	call dly_ms
	ldi CREG, 0x30	; send the first half of 0x30 (8-bit mode) three times
	call lcd_nbl
	ldi DREG, 0x5	; wait 5ms before sending the second set command
	call dly_ms
	ldi CREG, 0x30
	call lcd_nbl
	ldi R20, 0x8	; wait 15ms (max for dly_ms) 7 times is ~100ms
dly_init:			
	ldi DREG, 0xF	; wait 100ms before sending the last one
	call dly_ms
	dec R20  		; dec temp counter (not used in dly_ms)
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
	sts dat, TEMP
	call lcd_cmd
	ldi TEMP, 0x08		; Display Off, Cursor Off, Blink Off
	sts dat, TEMP
	call lcd_cmd
	ldi TEMP, 0x01		; Display Clear
	sts dat, TEMP
	call lcd_cmd
	ldi DREG, 0x02
	call dly_ms
	ldi TEMP, 0x06		; Increment cursor, no Display Shift
	sts dat, TEMP
	call lcd_cmd
	ldi TEMP, 0x0C		; Display On, Cursor On, Blink On
	sts dat, TEMP
	call lcd_cmd
	ldi TEMP, 0x80
	sts cursor_xy, TEMP

	ret
; ** End lcd_init

; ** dly_us: Wait DREG microseconds

dly_us:		; Waits DREG microseconds in a busy-wait loop.
			; DREG can be any number of microseconds from 0 to 255.
dlyus_dreg:	ldi TEMP, 0x05
dlyus_in:	dec TEMP
			brne dlyus_in	
			dec DREG
			brne dlyus_dreg

	ret
; ** End dly_us


; ** dly_ms: Wait (DREG>>4)&0F milliseconds.

dly_ms:	; I AM USING THE Y REGISTER FOR THIS i am a grown-ass man you can't
		; tell me not to.
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
		; R1 = 2hhhh 1hhhhh
		; R0 = 2llll 1lllll
		; TEMP = 2hhhh 1hhhh
		; TEMP = 1hhhh 2hhhh
		; TEMP = 1hhhh 0000
		; YH = TEMP = 1hhhh 0000
		; TEMP = R0 = 2llll 1llll
		; TEMP = 1llll 2llll
		; TEMP2 = TEMP = 1llll 2llll
		; TEMP = 1llll 0000
		; YL = TEMP
		; TEMP2 = 0000 2llll
		; YH = YH ^ TEMP2
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

; *** ***
; HEY THESE BULLSHIT FUNCTIONS ARE DONE

; Now here's some bullshit data allocation

.dseg
	str: .byte 32 ; Reserve 32 characters worth of memory (16x2 character LCD)
	dat: .byte 1  ; Reserve one byte for a command sent to the LCD controller
;	dly: .byte 2
	cursor_xy:	.byte 1
