#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message   ; external UART subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_FirstLine, LCD_SecondLine
					    ; external LCD subroutines
extrn	ADC_Setup, ADC_Read		    ; external ADC subroutines
extrn	KeyPad_Setup, KeyPad_Read	    ; external KeyPad subroutines
extrn	KeyPad_Int_Hi
extrn	OUT3, OUT2, OUT1, OUT0

global	KeyPad_Int_Hi_Output


psect	udata_acs   ; reserve data space in access ram
counter:	ds  1    ; reserve one byte for a counter variable
delay_count:	ds  1    ; reserve one byte for counter in the delay routine
delay_count_2:	ds  1
delay_count_3:	ds  1
delay_count_4:	ds  1
KeyPad_TEMP:	ds  1
target_temp:	ds  4
temp_diff:	ds  4

psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data
; ******* myTable, data in programme memory, and its length *****
Enter_Temp:
    db	'E','n','t','e','r',' ','T','E','M','P',':',0x0a
				; message, plus carriage return
    Enter_Temp_l  EQU	12	; length of data
    align	  2
degrees:
    db	' ',' ',' ','.',' ',' ','d','e','g','r','e','e','s',0x0a
				; message, plus carriage return
    degrees_l  EQU	14	; length of data
    align	  2
Current_Temp:
    db	'C','u','r','r','e','n','t',' ','T','E','M','P',':',0x0a
				; message, plus carriage return
    Current_Temp_l  EQU	14	; length of data
    align	    2


psect	code, abs	
rst:
    org	    0x0
    goto    setup
    org	    0x0008		; High-priority interrupts
    goto    H_interrupts
    org	    0x0018		; Low-priority interrupts
    goto    L_interrupts

H_interrupts:
    goto    KeyPad_Int_Hi
KeyPad_Int_Hi_Output:
    movwf   KeyPad_TEMP, A
    decf    counter, A
    return

L_interrupts:
    goto    $    

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
    call    write_Enter_Temp
    call    KeyPad_Enter
    call    write_Current_Temp
    goto    Current_Temp_loop


write_Enter_Temp:
    call    LCD_FirstLine
    lfsr    0, myArray		; Load FSR0 with address in RAM	
    movlw   low highword(Enter_Temp)   ; address of data in PM
    movwf   TBLPTRU, A		; load upper bits to TBLPTRU
    movlw   high(Enter_Temp)	; address of data in PM
    movwf   TBLPTRH, A		; load high byte to TBLPTRH
    movlw   low(Enter_Temp)	; address of data in PM
    movwf   TBLPTRL, A		; load low byte to TBLPTRL
    movlw   Enter_Temp_l	; bytes to read
    movwf   counter, A		; our counter register
enter_loop:
    tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		; count down to zero
    bra	    enter_loop		; keep going until finished

    movlw   Enter_Temp_l-1	; output message to LCD
				; don't send the final carriage return to LCD
    lfsr    2, myArray
    call    LCD_Write_Message
    return


KeyPad_Enter:
    call    LCD_SecondLine
    lfsr    0, myArray		; Load FSR0 with address in RAM	
    movlw   low highword(degrees)   ; address of data in PM
    movwf   TBLPTRU, A		; load upper bits to TBLPTRU
    movlw   high(degrees)	; address of data in PM
    movwf   TBLPTRH, A		; load high byte to TBLPTRH
    movlw   low(degrees)	; address of data in PM
    movwf   TBLPTRL, A		; load low byte to TBLPTRL
    movlw   degrees_l		; bytes to read
    movwf   counter, A		; our counter register
degrees_loop:
    tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		; count down to zero
    bra	    degrees_loop	; keep going until finished

    movlw   degrees_l-1	; output message to LCD
				; don't send the final carriage return to LCD
    lfsr    2, myArray
    call    LCD_Write_Message
    movlw   0x04
    movwf   counter, A
    call    delay3
KeyPad_loop:
    movlw   0x03
    cpfseq  counter, A
    goto    continue1
    call    KeyPad_Enter_1
continue1:
    movlw   0x02
    cpfseq  counter, A
    goto    continue2
    call    KeyPad_Enter_2
continue2:
    movlw   0x01
    cpfseq  counter, A
    goto    continue3
    call    KeyPad_Enter_3
continue3:
    movlw   0x00
    cpfseq  counter, A
    bra	    KeyPad_loop
    call    KeyPad_Enter_4
    call    delay1
    return

KeyPad_Enter_1:
    call    LCD_SecondLine
    movff   KeyPad_TEMP, target_temp
    lfsr    0, myArray
    movff   target_temp, POSTINC0
    lfsr    2, myArray
    movlw   1
    call    LCD_Write_Message
    call    delay3
    return

KeyPad_Enter_2:
    call    LCD_SecondLine
    movff   KeyPad_TEMP, target_temp+1
    lfsr    0, myArray
    movff   target_temp, POSTINC0
    movff   target_temp+1, POSTINC0
    lfsr    2, myArray
    movlw   2
    call    LCD_Write_Message
    call    delay3
    return

KeyPad_Enter_3:
    call    LCD_SecondLine
    movff   KeyPad_TEMP, target_temp+2
    lfsr    0, myArray
    movff   target_temp, POSTINC0
    movff   target_temp+1, POSTINC0
    movff   target_temp+2, POSTINC0
    movlw   0x2e
    movwf   POSTINC0, A
    lfsr    2, myArray
    movlw   4
    call    LCD_Write_Message
    call    delay3
    return

KeyPad_Enter_4:
    call    LCD_SecondLine
    movff   KeyPad_TEMP, target_temp+3
    lfsr    0, myArray
    movff   target_temp, POSTINC0
    movff   target_temp+1, POSTINC0
    movff   target_temp+2, POSTINC0
    movlw   0x2e
    movwf   POSTINC0, A
    movff   target_temp+3, POSTINC0
    lfsr    2, myArray
    movlw   5
    call    LCD_Write_Message
    call    delay3
    return


write_Current_Temp:
    call    LCD_FirstLine
    lfsr    0, myArray		; Load FSR0 with address in RAM	
    movlw   low highword(Current_Temp)   ; address of data in PM
    movwf   TBLPTRU, A		; load upper bits to TBLPTRU
    movlw   high(Current_Temp)	; address of data in PM
    movwf   TBLPTRH, A		; load high byte to TBLPTRH
    movlw   low(Current_Temp)	; address of data in PM
    movwf   TBLPTRL, A		; load low byte to TBLPTRL
    movlw   Current_Temp_l	; bytes to read
    movwf   counter, A		; our counter register
current_loop:
    tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		; count down to zero
    bra	    current_loop	; keep going until finished

    movlw   Current_Temp_l-1	; output message to LCD
				; don't send the final carriage return to LCD
    lfsr    2, myArray
    call    LCD_Write_Message
    return


Current_Temp_loop:
    call    ADC_Read
    call    LCD_SecondLine
;    lfsr    0, myArray
;    movff   OUT3, POSTINC0
;    movff   OUT2, POSTINC0
;    movff   OUT1, POSTINC0
;    movlw   0x2e
;    movwf   POSTINC0, A
;    movff   OUT0, POSTINC0
;    lfsr    2, myArray
;    movlw   5
;    call    LCD_Write_Message

    movff   OUT3, temp_diff
    movf    target_temp, A
    subwf   temp_diff, 1, 0
    movlw   0x30
    addwf   temp_diff, A

    movff   OUT2, temp_diff+1
    movf    target_temp+1, A
    subwf   temp_diff+1, 1, 0
    movlw   0x30
    addwf   temp_diff+1, A

    movff   OUT1, temp_diff+2
    movf    target_temp+2, A
    subwf   temp_diff+2, 1, 0
    movlw   0x30
    addwf   temp_diff+2, A

    movff   OUT0, temp_diff+3
    movf    target_temp+3, A
    subwf   temp_diff+3, 1, 0
    movlw   0x30
    addwf   temp_diff+3, A

    lfsr    0, myArray
    movff   temp_diff, POSTINC0
    movff   temp_diff+1, POSTINC0
    movff   temp_diff+2, POSTINC0
    movlw   0x2e
    movwf   POSTINC0, A
    movff   temp_diff+3, POSTINC0
    lfsr    2, myArray
    movlw   5
    call    LCD_Write_Message

    goto    Current_Temp_loop	    ; goto current line in code


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
    movlw   0xff
    movwf   delay_count_3, A
    call    delay3
    decfsz  delay_count_2, A	    ; decrement until zero
    bra	    delay2
    return

delay3:
    movlw   0xff
    movwf   delay_count_4, A
    call    delay4
    decfsz  delay_count_3, A
    bra	    delay3
    return

delay4:
    decfsz  delay_count_4, A
    bra	    delay4
    return

end rst
