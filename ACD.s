#include <xc.inc>

global  ADC_Setup, ADC_Read    

psect	udata_acs
ARG1H:	ds  1
ARG1M:	ds  1
ARG1L:	ds  1
ARG2H:	ds  1
ARG2L:	ds  1
RES3:	ds  1
RES2:	ds  1
RES1:	ds  1
RES0:	ds  1
OUT3:	ds  1
OUT2:	ds  1
OUT1:	ds  1
OUT0:	ds  1

psect	adc_code, class=CODE

; ADC Setup - Configuring the ADC for AN0 (RA0) input
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

; ADC Read - Read the ADC value from AN0 (RA0)
ADC_Read:
    bsf	    GO		; Start conversion by setting GO bit in ADCON0

    ; ADC value is now available in ADRESH and ADRESL
    MOVFF   ADRESL, ARG1L
    MOVFF   ADRESH, ARG1H

    ; Set constant multiplier 0x418A (24-bit constant)
    MOVLW   0x41	; Load the high byte of the constant (0x418A)
    MOVWF   ARG2H, A	; Store in ARG2H (higher byte of constant)
    MOVLW   0x8A	; Load the low byte of the constant (0x418A)
    MOVWF   ARG2L, A	; Store in ARG2L (lower byte of constant)

    MOVF    ARG1L, W, A
    MULWF   ARG2L, A	; ARG1L * ARG2L->
			; PRODH:PRODL
    MOVFF   PRODH, RES1 ;
    MOVFF   PRODL, RES0 ;
;
    MOVF    ARG1H, W, A
    MULWF   ARG2H, A	; ARG1H * ARG2H->
			; PRODH:PRODL
    MOVFF   PRODH, RES3	;
    MOVFF   PRODL, RES2	;
;
    MOVF    ARG1L, W, A
    MULWF   ARG2H, A	; ARG1L * ARG2H->
			; PRODH:PRODL
    MOVF    PRODL, W, A	;
    ADDWF   RES1, F, A	; Add cross
    MOVF    PRODH, W, A	; products
    ADDWFC  RES2, F, A	;
    CLRF    WREG, A	;
    ADDWFC  RES3, F, A	;
;
    MOVF    ARG1H, W, A	;
    MULWF   ARG2L, A	; ARG1H * ARG2L->
			; PRODH:PRODL
    MOVF    PRODL, W, A	;
    ADDWF   RES1, F, A	; Add cross
    MOVF    PRODH, W, A	; products
    ADDWFC  RES2, F, A	;
    CLRF    WREG, A	;
    ADDWFC  RES3, F, A	;

    MOVF    RES3, A
    ADDWF   0x30
    MOVWF   OUT3, A
    
    ;Step 2
    MOVFF   RES2, ARG1H
    MOVFF   RES1, ARG1M
    MOVFF   RES0, ARG1L
    MOVLW   0x0a
    MOVWF   ARG2L

    ; Multiply the ADC result (8-bit) by the 24-bit constant
    CALL    MULTIPLY_8_24    ; Call multiplication routine

    ; The result of the multiplication is in RES3 (most significant byte)
    ; RES2, RES1, RES0 (least significant byte)

adc_loop:
    btfsc   GO		; check to see if finished
    bra	    adc_loop
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

end
