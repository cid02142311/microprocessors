#include <xc.inc>
    
global  KeyPad_Setup, KeyPad_Read
global	KeyPad_output

psect	udata_acs   ; reserve data space in access ram
KeyPad_row:	ds  1
KeyPad_column:	ds  1
KeyPad_output:	ds  1
delay_count:	ds  1
KeyPad_counter:	ds  1

psect	keypad_code, class=CODE
delay:
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return


KeyPad_Setup:
    banksel PADCFG1
    bsf	    REPU
    clrf    LATE, A
    return
    
    
KeyPad_Setup_col:
    movlw   00001111B
    movwf   TRISE, A
    movlw   0xff
    movwf   delay_count, A
    call    delay
    return
    
KeyPad_Setup_row:
    clrf    KeyPad_counter, A

    movlw   11110000B
    movwf   TRISE, A
    movlw   0xff
    movwf   delay_count, A
    call    delay
    return

KeyPad_Read:
    clrf    KeyPad_output, A
    clrf    KeyPad_row, A
    clrf    KeyPad_column, A
    clrf    KeyPad_counter, A
    call    KeyPad_Setup_col
    movlw   0x1
    btfss   PORTE, 0, A
    movwf   KeyPad_column, A
    btfss   PORTE, 0, A
    incf    KeyPad_counter, A

    movlw   0x2
    btfss   PORTE, 1, A
    movwf   KeyPad_column, A
    btfss   PORTE, 1, A
    incf    KeyPad_counter, A

    movlw   0x3
    btfss   PORTE, 2, A
    movwf   KeyPad_column, A
    btfss   PORTE, 2, A
    incf    KeyPad_counter, A

    movlw   0x4
    btfss   PORTE, 3, A
    movwf   KeyPad_column, A
    btfss   PORTE, 3, A
    incf    KeyPad_counter, A

    ; write errror message from counter

    call    KeyPad_Setup_row

    movlw   0x1
    btfss   PORTE, 4, A
    movwf   KeyPad_row, A
    btfss   PORTE, 4, A
    incf    KeyPad_counter, A

    movlw   0x2
    btfss   PORTE, 5, A
    movwf   KeyPad_row, A
    btfss   PORTE, 5, A
    incf    KeyPad_counter, A

    movlw   0x3
    btfss   PORTE, 6, A
    movwf   KeyPad_row, A
    btfss   PORTE, 6, A
    incf    KeyPad_counter, A

    movlw   0x4
    btfss   PORTE, 7, A
    movwf   KeyPad_row, A
    btfss   PORTE, 7, A
    incf    KeyPad_counter, A

    ; write errror message from counter
    
KeyPad_Analysis:
    goto    Check_Row1

Check_Row1:
    ; If Row 1 (RE4 is active)
    movlw   0x1
    cpfseq  KeyPad_row, A
    bra     Check_Row2
    bra    ret1

    ; Now determine the key in Row 1 based on column
ret1:
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column, A
    bra	    ret2
    retlw   '1'             ; Key '1'
ret2:
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column, A
    bra	    ret3
    retlw   '2'             ; Key '2'
ret3:
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column, A
    bra	    retf
    retlw   '3'             ; Key '3'
retf:
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column, A
    bra     No_KeyDetected
    retlw   'F'             ; Key 'F'


Check_Row2:
    ; If Row 2 (RE5 is active)
    movlw   0x2
    cpfseq  KeyPad_row, A
    bra     Check_Row3
    bra	    ret4

    ; Now determine the key in Row 2 based on column
ret4:
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column, A
    bra	    ret5
    retlw   '4'             ; Key '4'
ret5:
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column, A
    bra	    ret6
    retlw   '5'             ; Key '5'
ret6:
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column, A
    bra	    rete
    retlw   '6'             ; Key '6'
rete:
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column, A
    bra	    No_KeyDetected
    retlw   'E'             ; Key 'E'


Check_Row3:
    ; If Row 3 (RE6 is active)
    movlw   0x3
    cpfseq  KeyPad_row, A
    bra     Check_Row4
    bra	    ret7

    ; Now determine the key in Row 3 based on column
ret7:
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column, A
    bra	    ret8
    retlw   '7'             ; Key '7'
ret8:
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column, A
    bra	    ret9
    retlw   '8'             ; Key '8'
ret9:
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column, A
    bra	    retd
    retlw   '9'             ; Key '9'
retd:
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column, A
    bra	    No_KeyDetected
    retlw   'D'             ; Key 'D'


Check_Row4:
    ; If Row 4 (RE7 is active)
    movlw   0x4
    cpfseq  KeyPad_row, A
    bra     No_KeyDetected
    bra	    reta

    ; Now determine the key in Row 4 based on column
reta:
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column, A
    bra	    ret0
    retlw   'A'             ; Key 'A'
ret0:
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column, A
    bra	    retb
    retlw   '0'             ; Key '0'
retb:
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column, A
    bra	    retc
    retlw   'B'             ; Key 'B'
retc:
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column, A
    bra	    No_KeyDetected
    retlw   'C'             ; Key 'C'


No_KeyDetected:
    clrf    KeyPad_output, A   ; No key detected, set KeyPad_output to 0
    goto    KeyPad_Read