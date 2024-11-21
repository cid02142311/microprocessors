#include <xc.inc>

global  ADC_Setup, ADC_Read    
    
psect	adc_code, class=CODE
    
ADC_Setup:
    bsf	    TRISA, PORTA_RA0_POSN, A  ; pin RA0==AN0 input
    movlb   0x0f
    bsf	    ANSEL0	; set AN0 to analog
    movlb   0x00
    movlw   0x01	; select AN0 for measurement
    movwf   ADCON0, A	; and turn ADC on
    movlw   0x30	; Select 4.096V positive reference
    movwf   ADCON1, A   ; 0V for -ve reference and -ve input
    movlw   0xF6	; Right justified output
    movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
    return

ADC_Read:
    bsf	    GO		; Start conversion by setting GO bit in ADCON0

    MOVF    ARG1L, W 
    MULWF   ARG2L	; ARG1L * ARG2L-> 
			; PRODH:PRODL 
    MOVFF   PRODH, RES1 ; 
    MOVFF   PRODL, RES0 ; 
; 
    MOVF    ARG1H, W 
    MULWF   ARG2H	; ARG1H * ARG2H-> 
			; PRODH:PRODL 
    MOVFF   PRODH, RES3	; 
    MOVFF   PRODL, RES2	; 
; 
    MOVF    ARG1L, W 
    MULWF   ARG2H	; ARG1L * ARG2H-> 
			; PRODH:PRODL 
    MOVF    PRODL, W	; 
    ADDWF   RES1, F	; Add cross 
    MOVF    PRODH, W	; products 
    ADDWFC  RES2, F	; 
    CLRF    WREG	; 
    ADDWFC  RES3, F	; 
; 
    MOVF    ARG1H, W	; 
    MULWF   ARG2L	; ARG1H * ARG2L-> 
			; PRODH:PRODL 
    MOVF    PRODL, W	; 
    ADDWF   RES1, F	; Add cross 
    MOVF    PRODH, W	; products 
    ADDWFC  RES2, F	; 
    CLRF    WREG	; 
    ADDWFC  RES3, F	; 

adc_loop:
    btfsc   GO		; check to see if finished
    bra	    adc_loop
    return

end

; Hexadecimal to Decimal conversion for PIC18
    ; Assumes the 12-bit ADC value is already in ADRESH:ADRESL
    ; Using multiplier k = 0x418A

    global  hex_to_decimal
    psect   code

hex_to_decimal:
    ; Initialize variables (this will use registers)
    ; Assume that ADRESH:ADRESL contains the ADC result
    
    ; Load ADC result into temporary registers
    movf    ADRESH, W          ; Move high byte of ADC result to W
    movwf   TEMP1              ; Store in TEMP1 (for 8-bit part)
    movf    ADRESL, W          ; Move low byte of ADC result to W
    movwf   TEMP2              ; Store in TEMP2 (for lower 8-bit part)
    
    ; Step 1: Multiply ADC value by 0x418A
    ; First multiply by low part of k (0x8A)
    movlw   0x8A
    mulwf   TEMP2              ; TEMP2 * 0x8A -> PRODH:PRODL
    movf    PRODH, W           ; Move high byte of result to W
    movwf   TEMP3              ; Store high part of result in TEMP3
    movf    PRODL, W           ; Move low byte of result to W
    movwf   TEMP4              ; Store low part of result in TEMP4
    
    ; Now multiply by high part of k (0x41)
    movlw   0x41
    mulwf   TEMP2              ; TEMP2 * 0x41 -> PRODH:PRODL
    addwf   TEMP3, F           ; Add high byte to TEMP3
    movf    PRODL, W           ; Move low byte of result to W
    addwf   TEMP4, F           ; Add low byte to TEMP4

    ; Now we have the result in TEMP3:TEMP4 (16-bit result)

    ; Step 2: Extract the first decimal digit by dividing by 10
    ; The result is in TEMP3:TEMP4, we divide it by 10
    movf    TEMP3, W
    movwf   TEMP5              ; Move high byte to TEMP5
    movf    TEMP4, W
    movwf   TEMP6              ; Move low byte to TEMP6

    ; Divide TEMP5:TEMP6 by 10 (simple division loop)
    ; We perform division using subtraction method
    movlw   10                 ; Load 10 (divisor)
    clrf    QUOTIENT           ; Clear quotient register
    clrf    REMAINDER          ; Clear remainder register

div_loop:
    movf    TEMP6, W           ; Load low byte
    subwf   TEMP5, W           ; Subtract TEMP5 from W
    btfss   STATUS, C          ; Check if borrow
    bra     done_div           ; If no borrow, division is complete
    addlw   10                 ; Otherwise add 10 to quotient
    movf    REMAINDER, W
    movwf   REMAINDER
done_div:
    ; This loop will be completed to extract the quotient (decimal digit)
    
    ; Repeat steps to extract remaining digits as necessary

    return
