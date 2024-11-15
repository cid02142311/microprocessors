#include <xc.inc>
    
global  KeyPad_Setup

psect	udata_acs   ; reserve data space in access ram
KeyPad_counter:	ds  1
KeyPad_row:	ds  1
KeyPad_column:	ds  1
KeyPad_output:	ds  1

psect	keypad_code, class=CODE
KeyPad_Setup:
    bsf	    REPU, 1
    clrf    LATE, A
    clrf    KeyPad_counter
    movlw   00001111B
    movwf   TRISE, A
    goto    Check_KeyPad_column

KeyPad_Setup_row:
    bsf	    REPU, 1
    clrf    LATE, A
    clrf    KeyPad_counter
    movlw   11110000B
    movwf   TRISE, A
    return

Check_KeyPad_column:
    movlw   00001111B
    cpfseq  PORTE, A
    bra	Check_KeyPad_column

KeyPad_read:
    movlw   0x00
    btfss   PORTE, 0, A
    movwf   KeyPad_column
    btfss   PORTE, 0, A
    incf    KeyPad_counter
    movlw   0x01
    btfss   PORTE, 1, A
    movwf   KeyPad_column
    btfss   PORTE, 1, A
    incf    KeyPad_counter
    movlw   0x02
    btfss   PORTE, 2, A
    movwf   KeyPad_column
    btfss   PORTE, 2, A
    incf    KeyPad_counter
    movlw   0x03
    btfss   PORTE, 3, A
    movwf   KeyPad_column
    btfss   PORTE, 3, A
    incf    KeyPad_counter
    ; write errror message from counter
    call    KeyPad_Setup_row
    movlw   0x00
    btfss   PORTE, 4, A
    movwf   KeyPad_row
    btfss   PORTE, 4, A
    incf    KeyPad_counter
    movlw   0x01
    btfss   PORTE, 5, A
    movwf   KeyPad_row
    btfss   PORTE, 5, A
    incf    KeyPad_counter
    movlw   0x02
    btfss   PORTE, 6, A
    movwf   KeyPad_row
    btfss   PORTE, 6, A
    incf    KeyPad_counter
    movlw   0x03
    btfss   PORTE, 7, A
    movwf   KeyPad_row
    btfss   PORTE, 7, A
    incf    KeyPad_counter
    movf    KeyPad_row
    ; write errror message from counter
    
# Analysis:
#     movlw   0x00
#     cpfseq   KeyPad_row
#     bra	Row1
#     movlw   0x00
#     cpfseq  KeyPad_column
#     bra	Column1
#     mov
    
    
    



