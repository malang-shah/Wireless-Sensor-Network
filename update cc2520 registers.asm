/*
 * update_cc2520_registers.asm
 *
 *  Created: 6/12/2013 3:23:15 AM
 *   Author: DESKTOP
 */ 


















 //NOTE: All registers update value as per datasheet except FSCAL1 reg which does not output desired updated value as per datasheet.
























 
;*************************************************************************************
;stack initialisation at 0x10FF. The stack initialisation should be above 0x00FF and below 0x10FF of SRAM
;*************************************************************************************  
   SER R28		//Set Register 
   LDI R29,0x10		//Load immediate 
   OUT sph,R29		//Out to I/O location 
   OUT spl,R28

;*************************************************************************************



;*************************************************************************************
; SPI initialization
;*************************************************************************************

;Set PB2(MOSI), PB1(SCK), PB0(CSn) pins in DDRB to make them as output port pins
ldi R16, (1<<PB2)|(1<<PB1)|(1<<PB0)
out DDRB, R16


;Set PF7(VREG)and PF6(RESETn) pins in DDRF to make them as output port pins 
ldi R17, (1<<PF7)|(1<<PF6)
sts DDRF, R17 // since DDRF is in extended i/o ldi instruction is replaced with sts


;reset PA6(GPIO0) pin in DDRA to make it as an input port pin
ldi R18,(0<<PA6)
out DDRA, R18

;reset PC7(GPIO1), PC6(GPIO3), PC5(GPIO4) and PC4(GPIO5) to make it input port pins in DDRC
ldi R19,(0<<PC7)|(0<<PC6)|(0<<PC5)|(0<<PC4)
out DDRC, R19


; reset PE7(GPIO2) pin in DDRC to make it as an input port pin
ldi R20, (0<<PE7)
out DDRE, R20

; configuration of SPI peripheral of uc as master

;Enable SPI Interrupt, enable SPI, configure as Master, SCLK=fosc/16,first bit out will be MSB, SCLK low when idle
;and data sample at positive edge


;set SPIE, SPE, MSTR, SPR0 and reset DORD, CPOL, CPHA and SPR1 bits of SPCR register
ldi R21,(1<<SPIE)|(1<<SPE)|(1<<MSTR)|(1<<SPR0)|(0<<DORD)|(0<<CPOL)|(0<<CPHA)|(0<<SPR1)
out SPCR, R21


;reset SPI2X in SPSR register - Do not double the spi clk speed
ldi R22, (0<<SPI2X)
out SPSR, R22


; reset  PF7 (VREG) and PF6 (RESETn) to make sure they remain low in case made high
; in earlier part of the code 

ldi R23, 0x00
sts DDRF, R23

; enable voltage regulator to supply power to digital sections of CC2520 

;set PF7(VREG)
ldi R23, 0x80
sts PORTF, R23

; wait for >=0.1ms for voltage regulator to get stabilize
call delay


;Set PF6(RESETn) pin of Radio

ldi R25,0xC0	//keep VREG(PF7) high and set RESET(PF6)
sts PORTF,R25

;Wait for PB3(MISO) pin to go high which indicates oscillator of CC2520 is stabllized

wait_2520xosc_stable:
					sbis PINB, 3
					jmp wait_2520xosc_stable
;************************************************************************************




;*************************************************************************************
;USART initialization
;*************************************************************************************

// Enable transmitter
ldi r16, 0x08; 
sts UCSR1B,r16




// Set frame format: 8data, 2stop bit, even parity
ldi r16, 0x2E;
sts UCSR1C,r16




 
//Set baud rate 9600 for fosc 8 MHz
ldi r17, 0X00
ldi r16, 0x33; 
sts UBRR1H,r17
sts UBRR1L, r16

;*************************************************************************************




;*************************************************************************************
;Main Program
;*************************************************************************************

;NOTE: THIS IS ONE OF THE WORKAROUND SOLUTION AS MENTIONED IN ERRATA SHEET FOR THE BUG THAT REGWR DOES NOT WORK 
; AND VALUE ONLY GETS UPDATED IF SAME REGISTER IS WRITTEN TWICE WHICH IS DISCOVERED BY ME AND NOT MENTIONED IN ERRATA

;*************************************************************************************
;to write TXPOWER reg using MEMWR instruction instaed of REGWR
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x030 for reg TXPOWER
ldi R25, 0x20 
call SPI_transmission






ldi R25, 0x30 
call SPI_transmission





//;transmit status byte on USART
//in R25, SPDR
//call USART_Transmit


;settings to be stored 0x32 is for 0dBm power
ldi R25, 0x32
call SPI_transmission



;transmit data stored in TXPOWER reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)


;***********************write again once **********************************************


;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x030 for reg TXPOWER
ldi R25, 0x20 
call SPI_transmission






ldi R25, 0x30 
call SPI_transmission





//;transmit status byte on USART
//in R25, SPDR
//call USART_Transmit


;settings to be stored 0x32 is for 0dBm power
ldi R25, 0x32
call SPI_transmission



;transmit data stored in TXPOWER reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)


;*************************************************************************************
;to write CCACTRL0 reg using MEMWR instruction instaed of REGWR
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x036 for reg CCACTRL0
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x36 
call SPI_transmission





;settings to be stored 0xF8 is for 0dBm power
ldi R25, 0xF8
call SPI_transmission



;transmit data stored in CCACTRL0 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)




;***********************write once again  **********************************************


;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x030 for reg TXPOWER
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x36 
call SPI_transmission



;settings to be stored 0x32 is for 0dBm power
ldi R25, 0xF8
call SPI_transmission



;transmit data stored in CCACTRL0 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)





;*************************************************************************************
;to write MDMCTRL0 reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x046 for reg MDMCTRL0
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x46 
call SPI_transmission



;settings to be stored 0x85 to make sync word detection less likely
ldi R25, 0x85
call SPI_transmission



;transmit data stored in MDMCTRL0 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)





;*************************************************************************************
;NOTE:Writing twice in the register outputs the updated value as found by me 
;*************************************************************************************


;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x046 for reg MDMCTRL0
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x46 
call SPI_transmission



;settings to be stored 0x85 to make sync word detection less likely
ldi R25, 0x85
call SPI_transmission



;transmit data stored in MDMCTRL0 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)



;*************************************************************************************
;to write MDMCTRL1 reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x047 for reg MDMCTRL1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x47 
call SPI_transmission



;settings to be stored 0x14 
ldi R25, 0x14
call SPI_transmission



;transmit data stored in MDMCTRL1 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)



;*************************************************************************************
;NOTE:Writing twice in the register outputs the updated value as found by me 
;*************************************************************************************





;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x047 for reg MDMCTRL1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x47 
call SPI_transmission



;settings to be stored 0x14 
ldi R25, 0x14
call SPI_transmission



;transmit data stored in MDMCTRL1 reg
in R25, SPDR
call USART_Transmit





;*************************************************************************************
;to write RXCTRL reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x04A for reg RXCTRL
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x4A 
call SPI_transmission



;settings to be stored 0x3F to adjust current in RX related analog modules
ldi R25, 0x3F
call SPI_transmission



;transmit data stored in RXCTRL reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)



;*************************************************************************************
;Note: Writing twice the same reg outputs the updated value as found by me 
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x04A for reg RXCTRL
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x4A 
call SPI_transmission



;settings to be stored 0x3F to adjust current in RX related analog modules
ldi R25, 0x3F
call SPI_transmission



;transmit data stored in RXCTRL reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)



;*************************************************************************************
;to write FSCTRL reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x04C for reg FSCTRL
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x4C 
call SPI_transmission



;settings to be stored 0x5A to adjust current in synthesizer
ldi R25, 0x5A
call SPI_transmission



;transmit data stored in FSCTRL reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)








;*************************************************************************************
;Note: Writing the same reg outputs the updated value as found by me
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x04C for reg FSCTRL
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x4C 
call SPI_transmission



;settings to be stored 0x5A to adjust current in synthesizer
ldi R25, 0x5A
call SPI_transmission



;transmit data stored in FSCTRL reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)






























//Note: this program for FSCAL1 does not output desired upated value as per datasheet








;*************************************************************************************
;to write FSCAL1 reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x04F for reg FSCAL1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x4F 
call SPI_transmission



;settings to be stored 0x2B to adjust current in synthesizer
ldi R25, 0x2B
call SPI_transmission



;transmit data stored in FSCAL1 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)




;*************************************************************************************
;Note: Writing the same reg outputs the updated value as found by me
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0


;opcode for instruction MEMWR and bits a11..a0 of memory location 0x04F for reg FSCAL1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x4F 
call SPI_transmission



;settings to be stored 0x2B to adjust current in synthesizer
ldi R25, 0x2B
call SPI_transmission



;transmit data stored in FSCAL1 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)




;*************************************************************************************
;to write AGCCTRL1 reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x053 for reg AGCCTRL1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x53 
call SPI_transmission






;settings to be stored 0x11 to adjust target value for AGC control loop 
ldi R25, 0x11
call SPI_transmission



;transmit data stored in AGCCTRL1 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)



;*************************************************************************************
;NOTE: writing same reg twice outputs the updated value
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x053 for reg AGCCTRL1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x53 
call SPI_transmission






;settings to be stored 0x11 to adjust target value for AGC control loop 
ldi R25, 0x11
call SPI_transmission



;transmit data stored in AGCCTRL1 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)





;*************************************************************************************
;to write ADCTEST0 reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x056 for reg ADCTEST0
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x56 
call SPI_transmission



;settings to be stored 0x10 to tune ADC performance
ldi R25, 0x10
call SPI_transmission



;transmit data stored in ADCTEST0 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)



;*************************************************************************************
;NOTE: writing same reg twice outputs the updated value
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x056 for reg ADCTEST0
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x56 
call SPI_transmission



;settings to be stored 0x10 to tune ADC performance
ldi R25, 0x10
call SPI_transmission



;transmit data stored in ADCTEST0 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)








;*************************************************************************************
;to write ADCTEST1 reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x057 for reg ADCTEST1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x57 
call SPI_transmission





;settings to be stored 0x0E to tune ADC performance
ldi R25, 0x0E
call SPI_transmission



;transmit data stored in ADCTEST1 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)



;*************************************************************************************
;NOTE: Writing same reg twice outputs the updated value 
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x057 for reg ADCTEST1
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x57 
call SPI_transmission





;settings to be stored 0x0E to tune ADC performance
ldi R25, 0x0E
call SPI_transmission



;transmit data stored in ADCTEST1 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)





;*************************************************************************************
;to write ADCTEST2 reg
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x058 for reg ADCTEST2
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x58 
call SPI_transmission






;settings to be stored 0x0E to tune ADC performance
ldi R25, 0x03
call SPI_transmission



;transmit data stored in ADCTEST2 reg
in R25, SPDR
call USART_Transmit


;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)




;*************************************************************************************
;Note: writing same reg twice outputs the updated value
;*************************************************************************************




;enable slave by pulling low CSn
cbi PORTB,0

;opcode for instruction MEMWR and bits a11..a0 of memory location 0x058 for reg ADCTEST2
ldi R25, 0x20 
call SPI_transmission



ldi R25, 0x58 
call SPI_transmission






;settings to be stored 0x0E to tune ADC performance
ldi R25, 0x03
call SPI_transmission



;transmit data stored in ADCTEST2 reg
in R25, SPDR
call USART_Transmit

;Signal end of packet by pulling high CSn
sbi PORTB,0 //Set PB0(CSn)










//Infinite loop to display string only once
loop:jmp loop


;*************************************************************************************
;USART Transmit subroutine
;*************************************************************************************

USART_Transmit:
				; Wait for empty transmit buffer
				lds R16,UCSR1A
				sbrs R16,5
				rjmp USART_Transmit
				sts UDR1,R25
				RET

;*************************************************************************************






;*************************************************************************************
;subroutine for SPI trasmission
;*************************************************************************************

SPI_transmission: 
out SPDR, R25
wait_for_transmission_to_complete:
									sbis SPSR, SPIF
									jmp wait_for_transmission_to_complete
									RET	
;*************************************************************************************



;*************************************************************************************
; subroutine for delay
;*************************************************************************************
delay:

; load register 1 with user defined value
ldi R16,02 // settings for register1=0x02 and register2=0xFF for 191.99us delay for 8MHz fosc
; an increment by 1 in register1 gives 95us delay approximately
;load register2 with user defined value
load_register2:
				ldi R17, 0xFF
decrement_register2:
					dec R17
					brne decrement_register2
					dec R16
					brne load_register2
					RET

;*************************************************************************************