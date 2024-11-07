	#include <xc.inc>

psect	code, abs

main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	clrf	TRISE, A
	clrf	PORTE, A
	lfsr	0, 0x10
	movlw	0x00
	movwf	INDF0, A
increment_phase:
	movf	INDF0, W
	movwf	PORTE, A
	incf	INDF0, f
	call	delay
	movlw	0xfe		    ; Do not use 0xff: overflow
	cpfsgt	INDF0, A
	bra increment_phase
decrement_phase:
	movf	INDF0, W
	movwf	PORTE, A
	decf	INDF0, f
	call	delay
	movlw	0x00
	cpfseq	INDF0, A
	bra decrement_phase
	bra increment_phase 
delay:
	movlw	0xff
	movwf	0x21, A
;	call	delay1
	decfsz	0x20, A
	bra	delay
	return
delay1:
	movlw	0xff
	movwf	0x22, A
	call	delay2
	decfsz	0x21, A
;	bra	delay1
	return
delay2:
	decfsz	0x22, A
	bra	delay2
	return
	end	main

SPI_MasterInit:
; Set Clock edge to negative
	bcf	CKE2	; CKE bit in SSP2STAT,
	; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
	movlw 	(SSP2CON1_SSPEN_MASK)|(SSP2CON1_CKP_MASK)|(SSP2CON1_SSPM1_MASK)
	movwf 	SSP2CON1, A
	; SDO2 output; SCK2 output
	bcf	TRISD, PORTD_SDO2_POSN, A   ; SDO2 output
	bcf	TRISD, PORTD_SCK2_POSN, A   ; SCK2 output
	return
SPI_MasterTransmit:
; Start transmission of data (held in W)
	movwf 	SSP2BUF, A  ; write data to output buffer
Wait_Transmit:
; Wait for transmission to complete
	btfss 	PIR2, 5	; check interrupt flag to see if data has been sent
	bra 	Wait_Transmit
	bcf 	PIR2, 5	; clear interrupt flag
	return