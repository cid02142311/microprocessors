#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message
extrn	KeyPad_Setup, KeyPad_Read

psect	udata_acs   ; reserve data space in access ram
counter:	ds  1    ; reserve one byte for a counter variable
delay_count:	ds  1    ; reserve one byte for counter in the delay routine
delay_count_2:	ds  1
delay_count_3:	ds  1
myChar:		ds  1
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

; psect	data    
; ******* myTable, data in programme memory, and its length *****
;myTable:
;	db	'N','o','n','e',0x0a
;					; message, plus carriage return
;	myTable_l   EQU	5	; length of data
;	align	2

psect	code, abs
main:
    org	    0x0
    goto    setup
    org	    0x100

; ******* Programme FLASH read Setup Code ***********************
setup:	
    bcf	    CFGS	; point to Flash program memory  
    bsf	    EEPGD 	; access Flash program memory
    call    UART_Setup	; setup UART
    call    LCD_Setup	; setup UART
    call    KeyPad_Setup
    goto    start

; ******* Main programme ****************************************
start: 	
    call    KeyPad_Read
    movwf   myChar, A
    
    lfsr    0, myArray	; Load FSR0 with address in RAM
    movf    myChar, W, A
    movwf   POSTINC0, A
    movlw   0x0a
    movwf   POSTINC0, A

    movlw   2
    lfsr    2, myArray
    call    UART_Transmit_Message

    movlw   1
    lfsr    2, myArray
    call    LCD_Write_Message

    movlw   0xff
    movwf   delay_count, A
    call    delay

    goto    start

;    movlw   low highword(myTable)	; address of data in PM
;    movwf   TBLPTRU, A		; load upper bits to TBLPTRU
;    movlw   high(myTable)	; address of data in PM
;    movwf   TBLPTRH, A		; load high byte to TBLPTRH
;    movlw   low(myTable)	; address of data in PM
;    movwf   TBLPTRL, A		; load low byte to TBLPTRL
;    movlw   myTable_l	; bytes to read
;    movwf   counter, A		; our counter register

;loop: 	
;    tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;    movff   TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;    decfsz  counter, A		; count down to zero
;    bra	loop		; keep going until finished
;		
;    movlw   myTable_l	; output message to UART
;    lfsr    2, myArray
;    call    UART_Transmit_Message
;
;    movlw   myTable_l	; output message to LCD
;    addlw   0xff		; don't send the final carriage return to LCD
;    lfsr    2, myArray
;    call    LCD_Write_Message
;;    clrf    LATB, A
;    goto    $		; goto current line in code

; a delay subroutine if you need one, times around loop in delay_count
delay:	
    movlw   0xff
    movwf   delay_count_2, A
    call    delay2
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return

delay2:	
    movlw   0x08
    movwf   delay_count_3, A
    call    delay3
    decfsz  delay_count_2, A	; decrement until zero
    bra	    delay2
    return

delay3:
    decfsz  delay_count_3, A
    bra	    delay3
    return

end main

