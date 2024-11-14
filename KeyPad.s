#include <xc.inc>
    
global  KeyPad_Setup, KeyPad_Transmit_Message

psect	udata_acs   ; reserve data space in access ram
KeyPad_counter: ds    1	    ; reserve 1 byte for variable KeyPad_counter

psect	keypad_code,class=CODE
KeyPad_Setup:
    bsf	    PADCFG1, REPU, 1
    clrf    LATE
    movlw   0x0f
    movwf   TRISE
    
;    bsf	    SPEN	; enable
;    bcf	    SYNC	; synchronous
;    bcf	    BRGH	; slow speed
;    bsf	    TXEN	; enable transmit
;    bcf	    BRG16	; 8-bit generator only
;    movlw   103		; gives 9600 Baud rate (actually 9615)
;    movwf   SPBRG1, A	; set baud rate
;    bsf	    TRISC, PORTC_TX1_POSN, A	; TX1 pin is output on RC6 pin
;					; must set TRISC6 to 1
    return

KeyPad_Transmit_Message:	    ; Message stored at FSR2, length stored in W
    movwf   KeyPad_counter, A
KeyPad_Loop_message:
    movf    POSTINC2, W, A
    call    KeyPad_Transmit_Byte
    decfsz  KeyPad_counter, A
    bra	    KeyPad_Loop_message
    return

KeyPad_Transmit_Byte:	    ; Transmits byte stored in W
    btfss   TX1IF	    ; TX1IF is set when TXREG1 is empty
    bra	    KeyPad_Transmit_Byte
    movwf   TXREG1, A
    return


