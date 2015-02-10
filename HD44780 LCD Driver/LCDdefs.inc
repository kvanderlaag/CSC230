.equ LCD_DAT		=	50		; Execute time in microseconds for data commands
.equ LCD_ENA		=	1		; Execute time in microseconds for clock pulse
.equ LCD_CLEAR		=	2		; Execute time for longer commands in ms

; Set the bit-width of the stack pointer for your processor.
.if RAMEND > $00FF
.equ SPBITS 		=	22		; Stack pointer width in bits for return addresses.
                ; Mega2560 = 22, some others = 16
.else
.equ SPBITS			=	16
.endif

; Register definitions used in this module
.def CREG=R18					; Command or data register used in routines
.def DREG=R19					; Delay values passed to dly_ms and dly_us
.def TEMP=R16					; Mnemonics for temporary values
.def TEMP2=R17
.def RET1=R7 		; These three registers can be used to store
.def RET2=R8 		; return addresses for working with the stack
.if SPBITS > 16	; If your processor has a 22-bit stack pointer, define
.def RET3=R9		; a third register byte
.endif
; ***
; End of Driver Register Definitions

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

#ifndef LCD_COLUMN
#error No LCD size defined!
#endif

#define lcd_length      (LCD_LINE * LCD_COLUMN) + 1

; Some constant definitions for Hitachi HD44780 Command instructions.
; Can be used with lcd_cmd by pushing them onto the stack before calling.
#define cmd_CLR			0x01
#define cmd_HOM			0x02

; Port/Pin Labels for D4
.if (LCD_PORT_D4 == PORTA)
.equ PORT_D4	=	PORTA+0x20
.equ PINS_D4	=	PINA+0x20
.equ DDR_D4		= DDRA+0x20
.elif (LCD_PORT_D4 == PORTB)
.equ PORT_D4	=	PORTB+0x20
.equ PINS_D4	=	PINB+0x20
.equ DDR_D4		= DDRB+0x20
.elif (LCD_PORT_D4 == PORTC)
.equ PORT_D4	=	PORTC+0x20
.equ PINS_D4	=	PINC+0x20
.equ DDR_D4		= DDRC+0x20
.elif (LCD_PORT_D4 == PORTD)
.equ PORT_D4	=	PORTD+0x20
.equ PINS_D4	=	PIND+0x20
.equ DDR_D4		= DDRD+0x20
.elif (LCD_PORT_D4 == PORTE)
.equ PORT_D4	=	PORTE+0x20
.equ PINS_D4	=	PINE+0x20
.equ DDR_D4		= DDRE+0x20
.elif (LCD_PORT_D4 == PORTF)
.equ PORT_D4	=	PORTF+0x20
.equ PINS_D4	=	PINF+0x20
.equ DDR_D4		= DDRF+0x20
.elif (LCD_PORT_D4 == PORTG)
.equ PORT_D4	=	PORTG+0x20
.equ PINS_D4	=	PING+0x20
.equ DDR_D4		= DDRG+0x20
.elif (LCD_PORT_D4 == PORTH)
.equ PORT_D4	=	PORTH
.equ PINS_D4	=	PINH
.equ DDR_D4		= DDRH
.elif (LCD_PORT_D4 == PORTJ)
.equ PORT_D4	=	PORTJ
.equ PINS_D4	=	PINJ
.equ DDR_D4		= DDRJ
.elif (LCD_PORT_D4 == PORTK)
.equ PORT_D4	=	PORTK
.equ PINS_D4	=	PINK
.equ DDR_D4		= DDRK
.elif (LCD_PORT_D4 == PORTL)
.equ PORT_D4	=	PORTL
.equ PINS_D4	=	PINL
.equ DDR_D4		= DDRL
.endif

; Port/Pin Labels for D5
.if (LCD_PORT_D5 == PORTA)
.equ PORT_D5	=	PORTA+0x20
.equ PINS_D5	=	PINA+0x20
.equ DDR_D5		= DDRA+0x20
.elif (LCD_PORT_D5 == PORTB)
.equ PORT_D5	=	PORTB+0x20
.equ PINS_D5	=	PINB+0x20
.equ DDR_D5		= DDRB+0x20
.elif (LCD_PORT_D5 == PORTC)
.equ PORT_D5	=	PORTC+0x20
.equ PINS_D5	=	PINC+0x20
.equ DDR_D5		= DDRC+0x20
.elif (LCD_PORT_D5 == PORTD)
.equ PORT_D5	=	PORTD+0x20
.equ PINS_D5	=	PIND+0x20
.equ DDR_D5		= DDRD+0x20
.elif (LCD_PORT_D5 == PORTE)
.equ PORT_D5	=	PORTE+0x20
.equ PINS_D5	=	PINE+0x20
.equ DDR_D5		= DDRE+0x20
.elif (LCD_PORT_D5 == PORTF)
.equ PORT_D5	=	PORTF+0x20
.equ PINS_D5	=	PINF+0x20
.equ DDR_D5		= DDRF+0x20
.elif (LCD_PORT_D5 == PORTG)
.equ PORT_D5	=	PORTG+0x20
.equ PINS_D5	=	PING+0x20
.equ DDR_D5		= DDRG+0x20
.elif (LCD_PORT_D5 == PORTH)
.equ PORT_D5	=	PORTH
.equ PINS_D5	=	PINH
.equ DDR_D5		=DDRH
.elif (LCD_PORT_D5 == PORTJ)
.equ PORT_D5	=	PORTJ
.equ PINS_D5	=	PINJ
.equ DDR_D5		= DDRJ
.elif (LCD_PORT_D5 == PORTK)
.equ PORT_D5	=	PORTK
.equ PINS_D5	=	PINK
.equ DDR_D5		= DDRK
.elif (LCD_PORT_D5 == PORTL)
.equ PORT_D5	=	PORTL
.equ PINS_D5	=	PINL
.equ DDR_D5		= DDRL
.endif

; Port/Pin Labels for D6
.if (LCD_PORT_D6 == PORTA)
.equ PORT_D6	=	PORTA+0x20
.equ PINS_D6	=	PINA+0x20
.equ DDR_D6		= DDRA+0x20
.elif (LCD_PORT_D6 == PORTB)
.equ PORT_D6	=	PORTB+0x20
.equ PINS_D6	=	PINB+0x20
.equ DDR_D6		= DDRB+0x20
.elif (LCD_PORT_D6 == PORTC)
.equ PORT_D6	=	PORTC+0x20
.equ PINS_D6	=	PINC+0x20
.equ DDR_D6		= DDRC+0x20
.elif (LCD_PORT_D6 == PORTD)
.equ PORT_D6	=	PORTD+0x20
.equ PINS_D6	=	PIND+0x20
.equ DDR_D6		= DDRD+0x20
.elif (LCD_PORT_D6 == PORTE)
.equ PORT_D6	=	PORTE+0x20
.equ PINS_D6	=	PINE+0x20
.equ DDR_D6		= DDRE+0x20
.elif (LCD_PORT_D6 == PORTF)
.equ PORT_D6	=	PORTF+0x20
.equ PINS_D6	=	PINF+0x20
.equ DDR_D6		= DDRF+0x20
.elif (LCD_PORT_D6 == PORTG)
.equ PORT_D6	=	PORTG+0x20
.equ PINS_D6	=	PING+0x20
.equ DDR_D6		= DDRG+0x20
.elif (LCD_PORT_D6 == PORTH)
.equ PORT_D6	=	PORTH
.equ PINS_D6	=	PINH
.equ DDR_D6		= DDRH
.elif (LCD_PORT_D6 == PORTJ)
.equ PORT_D6	=	PORTJ
.equ PINS_D6	=	PINJ
.equ DDR_D6		= DDRJ
.elif (LCD_PORT_D6 == PORTK)
.equ PORT_D6	=	PORTK
.equ PINS_D6	=	PINK
.equ DDR_D6		= DDRK
.elif (LCD_PORT_D6 == PORTL)
.equ PORT_D6	=	PORTL
.equ PINS_D6	=	PINL
.equ DDR_D6		= DDRL
.endif

; Port/Pin Labels for D7
.if (LCD_PORT_D7 == PORTA)
.equ PORT_D7	=	PORTA+0x20
.equ PINS_D7	=	PINA+0x20
.equ DDR_D7		= DDRA+0x20
.elif (LCD_PORT_D7 == PORTB)
.equ PORT_D7	=	PORTB+0x20
.equ PINS_D7	=	PINB+0x20
.equ DDR_D7		= DDRB+0x20
.elif (LCD_PORT_D7 == PORTC)
.equ PORT_D7	=	PORTC+0x20
.equ PINS_D7	=	PINC+0x20
.equ DDR_D7		= DDRC+0x20
.elif (LCD_PORT_D7 == PORTD)
.equ PORT_D7	=	PORTD+0x20
.equ PINS_D7	=	PIND+0x20
.equ DDR_D7		= DDRD+0x20
.elif (LCD_PORT_D7 == PORTE)
.equ PORT_D7	=	PORTE+0x20
.equ PINS_D7	=	PINE+0x20
.equ DDR_D7		= DDRE+0x20
.elif (LCD_PORT_D7 == PORTF)
.equ PORT_D7	=	PORTF+0x20
.equ PINS_D7	=	PINF+0x20
.equ DDR_D7		= DDRF+0x20
.elif (LCD_PORT_D7 == PORTG)
.equ PORT_D7	=	PORTG+0x20
.equ PINS_D7	=	PING+0x20
.equ DDR_D7		= DDRG+0x20
.elif (LCD_PORT_D7 == PORTH)
.equ PORT_D7	=	PORTH
.equ PINS_D7	=	PINH
.equ DDR_D7		= DDRH
.elif (LCD_PORT_D7 == PORTJ)
.equ PORT_D7	=	PORTJ
.equ PINS_D7	=	PINJ
.equ DDR_D7		= DDRJ
.elif (LCD_PORT_D7 == PORTK)
.equ PORT_D7	=	PORTK
.equ PINS_D7	=	PINK
.equ DDR_D7		= DDRK
.elif (LCD_PORT_D7 == PORTL)
.equ PORT_D7	=	PORTL
.equ PINS_D7	=	PINL
.equ DDR_D7		= DDRL
.endif

; Port/Pin Labels for RS
.if (LCD_PORT_RS == PORTA)
.equ PORT_RS	=	PORTA+0x20
.equ PINS_RS	=	PINA+0x20
.equ DDR_RS		= DDRA+0x20
.elif (LCD_PORT_RS == PORTB)
.equ PORT_RS	=	PORTB+0x20
.equ PINS_RS	=	PINB+0x20
.equ DDR_RS		= DDRB+0x20
.elif (LCD_PORT_RS == PORTC)
.equ PORT_RS	=	PORTC+0x20
.equ PINS_RS	=	PINC+0x20
.equ DDR_RS		= DDRC+0x20
.elif (LCD_PORT_RS == PORTD)
.equ PORT_RS	=	PORTD+0x20
.equ PINS_RS	=	PIND+0x20
.equ DDR_RS		= DDRD+0x20
.elif (LCD_PORT_RS == PORTE)
.equ PORT_RS	=	PORTE+0x20
.equ PINS_RS	=	PINE+0x20
.equ DDR_RS		= DDRE+0x20
.elif (LCD_PORT_RS == PORTF)
.equ PORT_RS	=	PORTF+0x20
.equ PINS_RS	=	PINF+0x20
.equ DDR_RS		= DDRF+0x20
.elif (LCD_PORT_RS == PORTG)
.equ PORT_RS	=	PORTG+0x20
.equ PINS_RS	=	PING+0x20
.equ DDR_RS		= DDRG+0x20
.elif (LCD_PORT_RS == PORTH)
.equ PORT_RS	=	PORTH
.equ PINS_RS	=	PINH
.equ DDR_RS		= DDRH
.elif (LCD_PORT_RS == PORTJ)
.equ PORT_RS	=	PORTJ
.equ PINS_RS	=	PINJ
.equ DDR_RS		= DDRJ
.elif (LCD_PORT_RS == PORTK)
.equ PORT_RS	=	PORTK
.equ PINS_RS	=	PINK
.equ DDR_RS		= DDRK
.elif (LCD_PORT_RS == PORTL)
.equ PORT_RS	=	PORTL
.equ PINS_RS	=	PINL
.equ DDR_RS		= DDRL
.endif

; Port/Pin Labels for ENA
.if (LCD_PORT_ENA == PORTA)
.equ PORT_ENA	=	PORTA+0x20
.equ PINS_ENA	=	PINA+0x20
.equ DDR_ENA	=	DDRA+0x20
.elif (LCD_PORT_ENA == PORTB)
.equ PORT_ENA	=	PORTB+0x20
.equ PINS_ENA	=	PINB+0x20
.equ DDR_ENA	=	DDRB+0x20
.elif (LCD_PORT_ENA == PORTC)
.equ PORT_ENA	=	PORTC+0x20
.equ PINS_ENA	=	PINC+0x20
.equ DDR_ENA	=	DDRC+0x20
.elif (LCD_PORT_ENA == PORTD)
.equ PORT_ENA	=	PORTD+0x20
.equ PINS_ENA	=	PIND+0x20
.equ DDR_ENA	=	DDRD+0x20
.elif (LCD_PORT_ENA == PORTE)
.equ PORT_ENA	=	PORTE+0x20
.equ PINS_ENA	=	PINE+0x20
.equ DDR_ENA	=	DDRE+0x20
.elif (LCD_PORT_ENA == PORTF)
.equ PORT_ENA	=	PORTF+0x20
.equ PINS_ENA	=	PINF+0x20
.equ DDR_ENA	=	DDRF+0x20
.elif (LCD_PORT_ENA == PORTG)
.equ PORT_ENA	=	PORTG+0x20
.equ PINS_ENA	=	PING+0x20
.equ DDR_ENA	=	DDRG+0x20
.elif (LCD_PORT_ENA == PORTH)
.equ PORT_ENA	=	PORTH
.equ PINS_ENA	=	PINH
.equ DDR_ENA	=	DDRH
.elif (LCD_PORT_ENA == PORTJ)
.equ PORT_ENA	=	PORTJ
.equ PINS_ENA	=	PINJ
.equ DDR_ENA	=	DDRJ
.elif (LCD_PORT_ENA == PORTK)
.equ PORT_ENA	=	PORTK
.equ PINS_ENA	=	PINK
.equ DDR_ENA	=	DDRK
.elif (LCD_PORT_ENA == PORTL)
.equ PORT_ENA	=	PORTL
.equ PINS_ENA	=	PINL
.equ DDR_ENA	=	DDRL
.endif
