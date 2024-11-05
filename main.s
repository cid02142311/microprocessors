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
;	call	delay
	movlw	0xfe		    ; Do not use 0xff: overflow
	cpfsgt	INDF0, A
	bra increment_phase
decrement_phase:
	movf	INDF0, W
	movwf	PORTE, A
	decf	INDF0, f
;	call	delay
	movlw	0x00
	cpfseq	INDF0, A
	bra decrement_phase
	bra increment_phase 
delay:
	movlw	0xff
	movwf	0x21, A
	call	delay1
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

