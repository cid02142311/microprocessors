#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message	    ; external UART subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Write_Hex ; external LCD subroutines
extrn	ADC_Setup, ADC_Read			    ; external ADC subroutines
extrn	KeyPad_Setup, KeyPad_Read		    ; external KeyPad subroutines
extrn	OUT3, OUT2, OUT1, OUT0


psect	udata_acs   ; reserve data space in access ram
counter:	ds  1    ; reserve one byte for a counter variable
delay_count:	ds  1    ; reserve one byte for counter in the delay routine
delay_count_2:	ds  1
delay_count_3:	ds  1
myChar:		ds  1

psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data
; ******* myTable, data in programme memory, and its length *****
myTable:
	db	'H','e','l','l','o',' ','W','o','r','l','d','!',0x0a
					; message, plus carriage return
	myTable_l   EQU	13	; length of data
	align	2


psect	code, abs	
main:
    org	    0x0
    goto    setup
    org	    0x0008		; High-priority interrupts
    goto    H_interrupts
    org	    0x0018		; Low-priority interrupts
    goto    L_interrupts
    org	    0x100

H_interrupts:
    

L_interrupts:
    

; ******* Programme FLASH read Setup Code ***********************
setup:
    bcf	    CFGS		; point to Flash program memory  
    bsf	    EEPGD		; access Flash program memory
    call    UART_Setup		; setup UART
    call    LCD_Setup		; setup LCD
    call    ADC_Setup		; setup ADC
    call    KeyPad_Setup	; setup KeyPad
    goto    start

; ******* Main programme ****************************************
start:
    lfsr    0, myArray		    ; Load FSR0 with address in RAM	
    movlw   low highword(myTable)   ; address of data in PM
    movwf   TBLPTRU, A		    ; load upper bits to TBLPTRU
    movlw   high(myTable)	    ; address of data in PM
    movwf   TBLPTRH, A		    ; load high byte to TBLPTRH
    movlw   low(myTable)	    ; address of data in PM
    movwf   TBLPTRL, A		    ; load low byte to TBLPTRL
    movlw   myTable_l		    ; bytes to read
    movwf   counter, A		    ; our counter register
loop:
    tblrd*+			    ; one byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	    ; move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		    ; count down to zero
    bra	    loop		    ; keep going until finished

    movlw   myTable_l		    ; output message to UART
    lfsr    2, myArray
    call    UART_Transmit_Message

    movlw   myTable_l-1		    ; output message to LCD
				    ; don't send the final carriage return to LCD
    lfsr    2, myArray
    call    LCD_Write_Message

measure_loop:
    call    ADC_Read
;    movf    ADRESH, W, A
;    call    LCD_Write_Hex
;    movf    ADRESL, W, A
;    call    LCD_Write_Hex
    lfsr    0, myArray
    movff   OUT3, POSTINC0
    movff   OUT2, POSTINC0
    movff   OUT1, POSTINC0
    movff   OUT0, POSTINC0
    lfsr    2, myArray
    movlw   4
    call    LCD_Write_Message
    goto    measure_loop	    ; goto current line in code

; some delay subroutines
delay:
    decfsz  delay_count, A	    ; decrement until zero
    bra	    delay
    return

delay1:
    movlw   0xff
    movwf   delay_count_2, A
    call    delay2
    decfsz  delay_count, A	    ; decrement until zero
    bra	    delay
    return

delay2:
    movlw   0x08
    movwf   delay_count_3, A
    call    delay3
    decfsz  delay_count_2, A	    ; decrement until zero
    bra	    delay2
    return

delay3:
    decfsz  delay_count_3, A
    bra	    delay3
    return

end main
