#include <xc.inc>	

extrn	target_temp
extrn	temp_diff
extrn	temp_rate_diff
extrn	threshold

global	PWM_Setup, Temperature_Control


psect	udata_acs   ; reserve data space in access ram
delay_count:	ds  1
PWM_counter:	ds  2


psect	fans_code, class=CODE
delay:
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return


PWM_Setup:
    movlw   0xFF
    movwf   PR2, A
    banksel CCPR2L
    movlw   00001100B
    movwf   CCP2CON, B
    movlw   0x00
    movwf   CCPR2L, B
    banksel 0
    movlw   00000101B
    movwf   T2CON, A
    clrf    TRISC, A

    movlw   00000000B
    movwf   TRISD, A

    return


Temperature_Control:

    ; Compare temperature with ideal value to control the fan/heater
    comp1:
    movlw   0x00
    cpfsgt  temp_diff, A
    goto    comp2
    goto    action
    comp2:
    movlw   0x00
    cpfsgt  temp_diff+1, A
    goto    comp3
    goto    action
    comp3:
    movf    threshold, W, A
    cpfsgt  temp_diff+2, A
    goto    no_action
    goto    action


no_action:
    banksel CCPR2L
    movlw   0x00
    movwf   CCPR2L, B
    banksel 0
    movlw   00000000B
    movwf   PORTD, A
    return

action:
    movlw   '-'
    cpfseq  temp_diff+4, A
    bra     Turn_On_Fan		    ; Jump to fan control
    bra     Turn_On_Heater	    ; Jump to heater control


Turn_On_Fan:
    ; Turn on the fan (increase PWM duty cycle to full power)
    call    Adjust_PWM_Fan	    ; Set the PWM duty cycle to maximum for the fan

    movlw   00000000B
    movwf   PORTD, A
    return

Turn_On_Heater:
    ; Turn on the heater (increase PWM duty cycle to full power)
    banksel CCPR2L
    movlw   0x00
    movwf   CCPR2L, B

    banksel 0
    movlw   00000010B
    movwf   PORTD, A
    return


Adjust_PWM_Fan:
    ; Adjust PWM duty cycle based on temperature difference (temp_diff)
    ; Example: Larger temperature difference will result in a higher duty cycle
    ; Scale temperature difference to PWM duty cycle (0-255 range)
    call    calculation
    movf    PWM_counter+1, W, A
    banksel CCPR2L
    movwf   CCPR2L, B		    ; Store result in CCPR1L (duty cycle register)
    return

;Adjust_PWM_Heater:
;    ; Adjust PWM duty cycle for the heater based on temperature difference
;    ; Scale temperature difference to PWM duty cycle (0-255 range)
;    call    calculation
;    movf    PWM_counter+1, W, A
;    movwf   CCPR1L, A		    ; Store result in CCPR1L (duty cycle register)
;    movf    PWM_counter, W, A
;    movwf   CCPR1H, A
;    return


calculation:
    movlw   0xff
    mulwf   temp_diff, A
    MOVFF   PRODH, PWM_counter
    MOVFF   PRODL, PWM_counter+1
    
    movlw   0xff
    mulwf   temp_diff+1, A
    movf    PRODL, W, A
    addwf   PWM_counter+1, A
    movf    PRODH, W, A
    addwfc  PWM_counter, A

    movlw   0x0A
    mulwf   temp_diff+2, A
    movf    PRODL, W, A
    addwf   PWM_counter+1, A
    movf    PRODH, W, A
    addwfc  PWM_counter, A

    movlw   0xff
    mulwf   temp_rate_diff, A
    movf    PRODL, W, A
    addwf   PWM_counter+1, A
    movf    PRODH, W, A
    addwfc  PWM_counter, A

    movlw   0x64
    mulwf   temp_rate_diff+1, A
    movf    PRODL, W, A
    addwf   PWM_counter+1, A
    movf    PRODH, W, A
    addwfc  PWM_counter, A

    movlw   0x00
    cpfseq  PWM_counter, A
    call    set_max
    return

set_max:
    movlw   0xff
    movwf   PWM_counter+1, A
    return

end
