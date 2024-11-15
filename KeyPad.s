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
    
KeyPad_Analysis:
    ; Check which row is active
    movf    KeyPad_row, W   ; Load KeyPad_row into WREG

    ; If Row 1 (RE4 is active)
    movlw   0x00
    cpfseq  WREG
    bra     Check_Row2
    ; Now determine the key in Row 1 based on column
    movf    KeyPad_column, W
    movlw   0x00            ; Column 1 (RE0)
    cpfseq  WREG
    movlw   '1'             ; Key '1'
    movlw   0x01            ; Column 2 (RE1)
    cpfseq  WREG
    movlw   '2'             ; Key '2'
    movlw   0x02            ; Column 3 (RE2)
    cpfseq  WREG
    movlw   '3'             ; Key '3'
    movlw   0x03            ; Column 4 (RE3)
    cpfseq  WREG
    movlw   'F'             ; Key 'F'
    goto    End_KeyAnalysis

Check_Row2:
    ; If Row 2 (RE5 is active)
    movlw   0x01
    cpfseq  KeyPad_row
    bra     Check_Row3
    ; Now determine the key in Row 2 based on column
    movf    KeyPad_column, W
    movlw   0x00            ; Column 1 (RE0)
    cpfseq  WREG
    movlw   '4'             ; Key '4'
    movlw   0x01            ; Column 2 (RE1)
    cpfseq  WREG
    movlw   '5'             ; Key '5'
    movlw   0x02            ; Column 3 (RE2)
    cpfseq  WREG
    movlw   '6'             ; Key '6'
    movlw   0x03            ; Column 4 (RE3)
    cpfseq  WREG
    movlw   'E'             ; Key 'E'
    goto    End_KeyAnalysis

Check_Row3:
    ; If Row 3 (RE6 is active)
    movlw   0x02
    cpfseq  KeyPad_row
    bra     Check_Row4
    ; Now determine the key in Row 3 based on column
    movf    KeyPad_column, W
    movlw   0x00            ; Column 1 (RE0)
    cpfseq  WREG
    movlw   '7'             ; Key '7'
    movlw   0x01            ; Column 2 (RE1)
    cpfseq  WREG
    movlw   '8'             ; Key '8'
    movlw   0x02            ; Column 3 (RE2)
    cpfseq  WREG
    movlw   '9'             ; Key '9'
    movlw   0x03            ; Column 4 (RE3)
    cpfseq  WREG
    movlw   'D'             ; Key 'D'
    goto    End_KeyAnalysis

Check_Row4:
    ; If Row 4 (RE7 is active)
    movlw   0x03
    cpfseq  KeyPad_row
    bra     No_KeyDetected
    ; Now determine the key in Row 4 based on column
    movf    KeyPad_column, W
    movlw   0x00            ; Column 1 (RE0)
    cpfseq  WREG
    movlw   'A'             ; Key 'A'
    movlw   0x01            ; Column 2 (RE1)
    cpfseq  WREG
    movlw   '0'             ; Key '0'
    movlw   0x02            ; Column 3 (RE2)
    cpfseq  WREG
    movlw   'B'             ; Key 'B'
    movlw   0x03            ; Column 4 (RE3)
    cpfseq  WREG
    movlw   'C'             ; Key 'C'
    goto    End_KeyAnalysis

No_KeyDetected:
    clrf    KeyPad_output   ; No key detected, set KeyPad_output to 0

End_KeyAnalysis:
    movwf   KeyPad_output   ; Store the result in KeyPad_output
    return
    
    
    



