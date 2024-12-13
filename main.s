#include <xc.inc>

;extrn	UART_Setup, UART_Transmit_Message   ; external UART subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_FirstLine, LCD_SecondLine
					    ; external LCD subroutines
extrn	ADC_Setup, ADC_Read		    ; external ADC subroutines
extrn	KeyPad_Setup, KeyPad_Read	    ; external KeyPad subroutines
extrn	KeyPad_Int_Hi
extrn	OUT3, OUT2, OUT1, OUT0		    ; ascii chars
extrn	subtraction
extrn	temp_diff			    ; 4 dec digits
extrn	differentiation
extrn	temp_rate_diff			    ; 2 dec digits
extrn	PWM_Setup, Temperature_Control

global	KeyPad_Int_Hi_Output
global	target_temp
global	POUT1, POUT0
global	threshold


psect	udata_acs   ; reserve data space in access ram
counter:	ds  1    ; reserve one byte for a counter variable
delay_count:	ds  1    ; reserve one byte for counter in the delay routine
delay_count_2:	ds  1
delay_count_3:	ds  1
delay_count_4:	ds  1
KeyPad_detector:ds  1
KeyPad_TEMP:	ds  1
target_temp:	ds  4
POUT1:		ds  1
POUT0:		ds  1
threshold:	ds  1

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
    db	' ',' ',' ','.','0',' ','d','e','g','r','e','e','s',0x0a
				; message, plus carriage return
    degrees_l	    EQU 14	; length of data
    align	    2
Current_Temp:
    db	'C','u','r','r','e','n','t',' ','T','E','M','P',':',0x0a
				; message, plus carriage return
    Current_Temp_l  EQU	14	; length of data
    align	    2
Temp_Diff:
    db	'T','E','M','P',' ','d','i','f','f',':',0x0a
				; message, plus carriage return
    Temp_Diff_l	    EQU	11	; length of data
    align	    2
Temp_Rate_Diff:
    db	'T','E','M','P',' ','r','a','t','e',' ','d','i','f','f',':',0x0a
				; message, plus carriage return
    Temp_Rate_Diff_l	EQU 16	; length of data
    align	    2
Threshold:
    db	'T','h','r','e','s','h','o','l','d',':',0x0a
				; message, plus carriage return
    Threshold_l	EQU 11	; length of data
    align	    2


psect	code, abs	
rst:
    org	    0x0
    movlw   0x02
    movwf   threshold, A
    goto    setup
    org	    0x0008		; High-priority interrupts
    goto    H_interrupts
    org	    0x0018		; Low-priority interrupts
    goto    L_interrupts

H_interrupts:
    goto    KeyPad_Int_Hi
KeyPad_Int_Hi_Output:
    movwf   KeyPad_TEMP, A
    decf    KeyPad_detector, A
    return

L_interrupts:
    goto    $    


; ******* Programme FLASH read Setup Code ***********************
setup:
    bcf	    CFGS		; point to Flash program memory  
    bsf	    EEPGD		; access Flash program memory
;    call    UART_Setup		; setup UART
    call    LCD_Setup		; setup LCD
    call    ADC_Setup		; setup ADC
    call    KeyPad_Setup	; setup KeyPad
    call    PWM_Setup
    goto    start


; ******* Main programme ****************************************
start:
    call    write_Enter_Temp
    call    KeyPad_Enter
    goto    Current_Temp_


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


write_degrees:
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
    return

KeyPad_Enter:
    call    write_degrees
    movlw   0x03
    movwf   KeyPad_detector, A
    call    delay3
KeyPad_loop:
    movlw   0x02
    cpfseq  KeyPad_detector, A
    goto    continue1
    call    KeyPad_Enter_1
continue1:
    movlw   0x01
    cpfseq  KeyPad_detector, A
    goto    continue2
    call    KeyPad_Enter_2
continue2:
    movlw   0x00
    cpfseq  KeyPad_detector, A
    bra	    KeyPad_loop
    call    KeyPad_Enter_3
    movlw   '0'
    movwf   target_temp+3, A
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
    lfsr    2, myArray
    movlw   3
    call    LCD_Write_Message
    call    delay3
    return


; ***** show Current Temperature *****
Current_Temp_:
    movlw   0x01
    movwf   KeyPad_detector, A
    call    write_Current_Temp
    call    write_degrees

Current_Temp_loop:
    call    ADC_Read

    call    LCD_SecondLine
    lfsr    0, myArray
    movff   OUT3, POSTINC0
    movff   OUT2, POSTINC0
    movff   OUT1, POSTINC0
    movlw   0x2e
    movwf   POSTINC0, A
    movff   OUT0, POSTINC0
    lfsr    2, myArray
    movlw   5
    call    LCD_Write_Message
    call    delay3

    call    subtraction
    call    differentiation
    movff   OUT1, POUT1
    movff   OUT0, POUT0

    call    Temperature_Control

    movlw   0x00
    cpfseq  KeyPad_detector, A
    bra	    Current_Temp_loop	    ; goto current line in code
    call    KeyPad_judgement
    call    LCD_Setup
    goto    Temp_Diff_


; ***** show Temperature difference *****
Temp_Diff_:
    movlw   0x01
    movwf   KeyPad_detector, A
    call    write_Temp_Diff
    call    write_degrees

Temp_Diff_loop:
    call    ADC_Read
    
    call    subtraction
    call    differentiation
    movff   OUT1, POUT1
    movff   OUT0, POUT0

    call    Temperature_Control

    movlw   0x30
    addwf   temp_diff, A
    addwf   temp_diff+1, A
    addwf   temp_diff+2, A
    addwf   temp_diff+3, A
    call    LCD_SecondLine
    lfsr    0, myArray
    movff   temp_diff+4, POSTINC0
;    movff   temp_diff, POSTINC0
    movff   temp_diff+1, POSTINC0
    movff   temp_diff+2, POSTINC0
    movlw   0x2e
    movwf   POSTINC0, A
    movff   temp_diff+3, POSTINC0
    lfsr    2, myArray
    movlw   5
    call    LCD_Write_Message
    call    delay3

    movlw   0x00
    cpfseq  KeyPad_detector, A
    bra	    Temp_Diff_loop	    ; goto current line in code
    call    KeyPad_judgement
    call    LCD_Setup
    goto    Temp_Rate_Diff_


; ***** show Temperature rate difference *****
Temp_Rate_Diff_:
    movlw   0x01
    movwf   KeyPad_detector, A
    call    write_Temp_Rate_Diff

Temp_Rate_Diff_loop:
    call    ADC_Read
    
    call    subtraction
    call    differentiation
    movff   OUT1, POUT1
    movff   OUT0, POUT0

    call    Temperature_Control

    movlw   0x30
    addwf   temp_rate_diff, A
    addwf   temp_rate_diff+1, A
    call    LCD_SecondLine
    lfsr    0, myArray
    movff   temp_rate_diff+2, POSTINC0
    movff   temp_rate_diff, POSTINC0
    movff   temp_rate_diff+1, POSTINC0
    lfsr    2, myArray
    movlw   2
    call    LCD_Write_Message
    call    delay3

    movlw   0x00
    cpfseq  KeyPad_detector, A
    bra	    Temp_Rate_Diff_loop	    ; goto current line in code
    call    KeyPad_judgement
    call    LCD_Setup
    goto    Current_Temp_


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

write_Temp_Diff:
    call    LCD_FirstLine
    lfsr    0, myArray		; Load FSR0 with address in RAM	
    movlw   low highword(Temp_Diff)   ; address of data in PM
    movwf   TBLPTRU, A		; load upper bits to TBLPTRU
    movlw   high(Temp_Diff)	; address of data in PM
    movwf   TBLPTRH, A		; load high byte to TBLPTRH
    movlw   low(Temp_Diff)	; address of data in PM
    movwf   TBLPTRL, A		; load low byte to TBLPTRL
    movlw   Temp_Diff_l		; bytes to read
    movwf   counter, A		; our counter register
diff_loop:
    tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		; count down to zero
    bra	    diff_loop	; keep going until finished

    movlw   Temp_Diff_l-1	; output message to LCD
				; don't send the final carriage return to LCD
    lfsr    2, myArray
    call    LCD_Write_Message
    return

write_Temp_Rate_Diff:
    call    LCD_FirstLine
    lfsr    0, myArray		; Load FSR0 with address in RAM	
    movlw   low highword(Temp_Rate_Diff)   ; address of data in PM
    movwf   TBLPTRU, A		; load upper bits to TBLPTRU
    movlw   high(Temp_Rate_Diff)	; address of data in PM
    movwf   TBLPTRH, A		; load high byte to TBLPTRH
    movlw   low(Temp_Rate_Diff)	; address of data in PM
    movwf   TBLPTRL, A		; load low byte to TBLPTRL
    movlw   Temp_Rate_Diff_l		; bytes to read
    movwf   counter, A		; our counter register
rate_diff_loop:
    tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		; count down to zero
    bra	    rate_diff_loop	; keep going until finished

    movlw   Temp_Rate_Diff_l-1	; output message to LCD
				; don't send the final carriage return to LCD
    lfsr    2, myArray
    call    LCD_Write_Message
    return


KeyPad_judgement:
    movlw   'A'
    cpfseq  KeyPad_TEMP, A
    goto    KeyPad_judgement_continue
    goto    Threshold_Set
KeyPad_judgement_continue:
    movlw   'C'
    cpfseq  KeyPad_TEMP, A
    return
    goto    rst


Threshold_Set:
    clrf    threshold, A
    call    LCD_Setup
write_Threshold_Temp:
    call    LCD_FirstLine
    lfsr    0, myArray		; Load FSR0 with address in RAM	
    movlw   low highword(Threshold)   ; address of data in PM
    movwf   TBLPTRU, A		; load upper bits to TBLPTRU
    movlw   high(Threshold)	; address of data in PM
    movwf   TBLPTRH, A		; load high byte to TBLPTRH
    movlw   low(Threshold)	; address of data in PM
    movwf   TBLPTRL, A		; load low byte to TBLPTRL
    movlw   Threshold_l		; bytes to read
    movwf   counter, A		; our counter register
Threshold_loop:
    tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
    movff   TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
    decfsz  counter, A		; count down to zero
    bra	    Threshold_loop	; keep going until finished

    movlw   Threshold_l-1	; output message to LCD
				; don't send the final carriage return to LCD
    lfsr    2, myArray
    call    LCD_Write_Message

Threshold_Enter:
    movlw   0x01
    movwf   KeyPad_detector, A
    call    delay3
Threshold_Enter_loop:
    movlw   0x00
    cpfseq  KeyPad_detector, A
    bra	    Threshold_Enter_loop
    call    Threshold_Enter_1
    call    delay1
    goto    setup

Threshold_Enter_1:
    call    LCD_SecondLine
    movff   KeyPad_TEMP, threshold
    lfsr    0, myArray
    movff   threshold, POSTINC0
    lfsr    2, myArray
    movlw   1
    call    LCD_Write_Message
    movlw   0x30
    subwf   threshold, 1, 0
    call    delay3
    return


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
