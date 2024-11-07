	#include <xc.inc>

psect	code, abs

main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISC, A	    ; Port C all outputs
	movlw	0x00
	movwf	0x06, A
	call	check
	bra 	test
check:
	movlw	0x00
	btfsc	PORTD, 0
	addlw	0x01
	btfsc	PORTD, 1
	addlw	0x02
	btfsc	PORTD, 2
	addlw	0x04
	btfsc	PORTD, 3
	addlw	0x08
	btfsc	PORTD, 4
	addlw	0x10
	btfsc	PORTD, 5
	addlw	0x20
	btfsc	PORTD, 6
	addlw	0x40
	btfsc	PORTD, 7
	addlw	0x80
	movwf	0x00
	return
delay:
	movlw	0xff
	movwf	0x21, A
	call	delay1
	decfsz	0x20, A
	bra	delay
	return
delay1:
	movlw	0x0f
	movwf	0x22, A
	call	delay2
	decfsz	0x21, A
	bra	delay1
	return
delay2:
	decfsz	0x22, A
	bra	delay2
	return
stop:
	goto	stop
loop:
	movff 	0x06, PORTC
	incf 	0x06, A
	movlw	0xff
	movwf	0x20, A
	call	delay
test:
;	movlw	0x63
	movf 	0x00, W
	cpfsgt 	0x06, A
	bra 	loop		    ; Not yet finished goto start of loop again
;	goto 	0x0		    ; Re-run program from start
	goto	stop
	end	main
