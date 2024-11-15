#include <xc.inc>
    
global  KeyPad_Setup
global	KeyPad_output

psect	udata_acs   ; reserve data space in access ram
delay_count:	ds  1
KeyPad_counter:	ds  1
KeyPad_row:	ds  1
KeyPad_column:	ds  1
KeyPad_output:	ds  1

psect	keypad_code, class=CODE
delay:
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return

KeyPad_Setup:
    clrf    KeyPad_output
    clrf    KeyPad_row
    clrf    KeyPad_column
    clrf    KeyPad_counter

    bsf	    BSR, 4
    bsf	    REPU
    clrf    LATE, A
    clrf    KeyPad_counter
    movlw   00001111B
    movwf   TRISE, A
    movlw   0xff
    movwf   delay_count
;    call    delay
    goto    KeyPad_read

KeyPad_Setup_row:
    clrf    KeyPad_counter

    bsf	    BSR, 4
    bsf	    REPU
    clrf    LATE, A
    clrf    KeyPad_counter
    movlw   11110000B
    movwf   TRISE, A
    movlw   0xff
    movwf   delay_count
;    call    delay
    return

KeyPad_read:
    movlw   0x1
    btfss   PORTE, 0, A
    movwf   KeyPad_column
    btfss   PORTE, 0, A
    incf    KeyPad_counter

    movlw   0x2
    btfss   PORTE, 1, A
    movwf   KeyPad_column
    btfss   PORTE, 1, A
    incf    KeyPad_counter

    movlw   0x3
    btfss   PORTE, 2, A
    movwf   KeyPad_column
    btfss   PORTE, 2, A
    incf    KeyPad_counter

    movlw   0x4
    btfss   PORTE, 3, A
    movwf   KeyPad_column
    btfss   PORTE, 3, A
    incf    KeyPad_counter

    ; write errror message from counter

    call    KeyPad_Setup_row

    movlw   0x1
    btfss   PORTE, 4, A
    movwf   KeyPad_row
    btfss   PORTE, 4, A
    incf    KeyPad_counter

    movlw   0x2
    btfss   PORTE, 5, A
    movwf   KeyPad_row
    btfss   PORTE, 5, A
    incf    KeyPad_counter

    movlw   0x3
    btfss   PORTE, 6, A
    movwf   KeyPad_row
    btfss   PORTE, 6, A
    incf    KeyPad_counter

    movlw   0x4
    btfss   PORTE, 7, A
    movwf   KeyPad_row
    btfss   PORTE, 7, A
    incf    KeyPad_counter

    ; write errror message from counter
    
KeyPad_Analysis:
    goto    Check_Row1

Check_Row1:
    ; If Row 1 (RE4 is active)
    movlw   0x1
    cpfseq  KeyPad_row
    bra     Check_Row2

    ; Now determine the key in Row 1 based on column
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column
    retlw   '1'             ; Key '1'
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column
    retlw   '2'             ; Key '2'
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column
    retlw   '3'             ; Key '3'
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column
    retlw   'F'             ; Key 'F'
    goto    End_KeyAnalysis

Check_Row2:
    ; If Row 2 (RE5 is active)
    movlw   0x2
    cpfseq  KeyPad_row
    bra     Check_Row3
    ; Now determine the key in Row 2 based on column
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column
    retlw   '4'             ; Key '4'
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column
    retlw   '5'             ; Key '5'
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column
    retlw   '6'             ; Key '6'
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column
    retlw   'E'             ; Key 'E'
    goto    End_KeyAnalysis

Check_Row3:
    ; If Row 3 (RE6 is active)
    movlw   0x3
    cpfseq  KeyPad_row
    bra     Check_Row4
    ; Now determine the key in Row 3 based on column
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column
    retlw   '7'             ; Key '7'
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column
    retlw   '8'             ; Key '8'
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column
    retlw   '9'             ; Key '9'
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column
    retlw   'D'             ; Key 'D'
    goto    End_KeyAnalysis

Check_Row4:
    ; If Row 4 (RE7 is active)
    movlw   0x4
    cpfseq  KeyPad_row
    bra     No_KeyDetected
    ; Now determine the key in Row 4 based on column
    movlw   0x1            ; Column 1 (RE0)
    cpfseq  KeyPad_column
    retlw   'A'             ; Key 'A'
    movlw   0x2            ; Column 2 (RE1)
    cpfseq  KeyPad_column
    retlw   '0'             ; Key '0'
    movlw   0x3            ; Column 3 (RE2)
    cpfseq  KeyPad_column
    retlw   'B'             ; Key 'B'
    movlw   0x4            ; Column 4 (RE3)
    cpfseq  KeyPad_column
    retlw   'C'             ; Key 'C'
    goto    End_KeyAnalysis

No_KeyDetected:
    clrf    KeyPad_output   ; No key detected, set KeyPad_output to 0
    goto    KeyPad_Setup

End_KeyAnalysis:
    movwf   KeyPad_output   ; Store the result in KeyPad_output
    return
