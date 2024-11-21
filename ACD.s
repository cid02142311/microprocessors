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
global  ADC_Setup, ADC_Read

psect   adc_code, class=CODE

; ADC Setup - Configuring the ADC for AN0 (RA0) input
ADC_Setup:
    bsf     TRISA, PORTA_RA0_POSN, A   ; pin RA0==AN0 input
    movlb   0x0f
    bsf     ANSEL0                      ; set AN0 to analog
    movlb   0x00
    movlw   0x01                        ; select AN0 for measurement
    movwf   ADCON0, A                   ; and turn ADC on
    movlw   0x30                        ; Select 4.096V positive reference
    movwf   ADCON1, A                   ; 0V for -ve reference and -ve input
    movlw   0xF6                        ; Right justified output
    movwf   ADCON2, A                   ; Fosc/64 clock and acquisition times
    return

; ADC Read - Read the ADC value from AN0 (RA0)
ADC_Read:
    bsf     GO      ; Start conversion by setting GO bit in ADCON0
adc_loop:
    btfsc   GO      ; Check to see if conversion is finished
    bra     adc_loop
    return

; Multiply 8-bit by 24-bit
; Multiply ARG1L (8-bit) by ARG2L, ARG2H, and ARG2U (24-bit)
MULTIPLY_8_24:
    ; Multiply ARG1L (8-bit) by ARG2L (low byte of 24-bit number)
    MOVF    ARG1L, W       ; Load ARG1L (ADC result low byte) into WREG
    MULWF   ARG2L          ; Multiply by ARG2L (low byte of constant)
    MOVFF   PRODH, RES1    ; Store the high byte of result in RES1
    MOVFF   PRODL, RES0    ; Store the low byte of result in RES0

    ; Multiply ARG1L (8-bit) by ARG2H (middle byte of 24-bit number)
    MOVF    ARG1L, W       ; Load ARG1L again into W
    MULWF   ARG2H          ; Multiply by ARG2H (middle byte of constant)
    MOVFF   PRODH, RES2    ; Store high byte of result in RES2
    MOVFF   PRODL, TEMP    ; Store low byte temporarily in TEMP
    ADDWF   RES1, F        ; Add to RES1 (previous high byte)
    MOVF    TEMP, W        ; Get the carry from the lower part
    ADDWFC  RES2, F        ; Add carry to RES2 (final result)

    ; Multiply ARG1L (8-bit) by ARG2U (upper byte of 24-bit number)
    MOVF    ARG1L, W       ; Load ARG1L again into W
    MULWF   ARG2U          ; Multiply by ARG2U (upper byte of constant)
    MOVFF   PRODH, RES3    ; Store high byte of result in RES3
    MOVFF   PRODL, TEMP    ; Store low byte temporarily in TEMP
    ADDWF   RES2, F        ; Add to RES2 (previous result)
    MOVF    TEMP, W        ; Get the carry from the lower part
    ADDWFC  RES3, F        ; Add carry to RES3 (final result)

    return

; Main program logic
psect code, abs
main:
    org     0x0
    goto    setup

    org     0x100

setup:
    call    ADC_Setup         ; Initialize ADC
    call    ADC_Read          ; Read ADC value

    ; ADC value is now available in ADRESH and ADRESL
    ; Store the result in ARG1L and ARG1H
    MOVF    ADRESL, W         ; Move low byte of ADC result to WREG
    MOVWF   ARG1L             ; Store it in ARG1L
    MOVF    ADRESH, W         ; Move high byte of ADC result to WREG
    MOVWF   ARG1H             ; Store it in ARG1H

    ; Set constant multiplier 0x418A (24-bit constant)
    MOVLW   0x41             ; Load the high byte of the constant (0x418A)
    MOVWF   ARG2U            ; Store in ARG2U (upper byte of constant)
    MOVLW   0x8A             ; Load the low byte of the constant (0x418A)
    MOVWF   ARG2L            ; Store in ARG2L (lower byte of constant)
    MOVLW   0x00             ; Set middle byte to 0 for 24-bit constant
    MOVWF   ARG2H            ; Store in ARG2H (middle byte of constant)

    ; Multiply the ADC result (8-bit) by the 24-bit constant
    CALL    MULTIPLY_8_24    ; Call multiplication routine

    ; The result of the multiplication is in RES3 (most significant byte)
    ; RES2, RES1, RES0 (least significant byte)

    ; Display or process the result in RES3, RES2, RES1, RES0
    ; For example, display result on LCD
    ; (Further code for displaying on LCD would go here)

    goto    $   ; Infinite loop to halt

end

    
   
