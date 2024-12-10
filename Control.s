#include <xc.inc>	

extrn	target_temp
extrn	temp_diff
extrn	temp_rate_diff

global	PWM_Setup, Temperature_Control


psect	udata_acs   ; reserve data space in access ram
delay_count:	ds  1
;; Define PWM parameters
FAN_PIN	    EQU  0x00	; Pin controlling the fan (could be connected to a MOSFET)
HEATER_PIN  EQU  0x00	; Pin controlling the heater (could be connected to a MOSFET)
PWM_counter:	ds  2


psect	fans_code, class=CODE
delay:
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return


PWM_Setup:
    bsf	    TRISF, 0, A
    bsf	    TRISG, 0, A

;    movlw   0xff
;    movwf   PR2, A
;    movlw   0x0c
;    movwf   CCP1CON, A
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
    movlw   0x02
    cpfsgt  temp_diff+2, A
    goto    no_action
    goto    action


no_action:
    bcf     PORTF, FAN_PIN, A
    bcf     PORTG, HEATER_PIN, A
    return

action:
    movlw   '-'
    cpfseq  temp_diff+4, A
    bra     Turn_On_Fan		    ; Jump to fan control
    bra     Turn_On_Heater	    ; Jump to heater control


Turn_On_Fan:
    ; Turn on the fan (increase PWM duty cycle to full power)
;    call    Adjust_PWM_Fan	    ; Set the PWM duty cycle to maximum for the fan
    bsf     PORTF, FAN_PIN, A	    ; Turn on the fan (via PWM)
    bcf     PORTG, HEATER_PIN, A    ; Turn off the heater
    return

Turn_On_Heater:
    ; Turn on the heater (increase PWM duty cycle to full power)
;    call    Adjust_PWM_Heater	    ; Set the PWM duty cycle to maximum for the heater
    bsf     PORTG, HEATER_PIN, A    ; Turn on the heater (via PWM)
    bcf     PORTF, FAN_PIN, A	    ; Turn off the fan
    return


Adjust_PWM_Fan:
    ; Adjust PWM duty cycle based on temperature difference (temp_diff)
    ; Example: Larger temperature difference will result in a higher duty cycle
    ; Scale temperature difference to PWM duty cycle (0-255 range)
    call    calculation
    movf    PWM_counter+1, W, A
    movwf   CCPR1L, A		    ; Store result in CCPR1L (duty cycle register)
    movf    PWM_counter, W, A
    movwf   CCPR1H, A
    return

Adjust_PWM_Heater:
    ; Adjust PWM duty cycle for the heater based on temperature difference
    ; Scale temperature difference to PWM duty cycle (0-255 range)
    call    calculation
    movf    PWM_counter+1, W, A
    movwf   CCPR1L, A		    ; Store result in CCPR1L (duty cycle register)
    movf    PWM_counter, W, A
    movwf   CCPR1H, A
    return


calculation:
    movlw   0x64
    mulwf   temp_diff, A
    MOVFF   PRODH, PWM_counter
    MOVFF   PRODL, PWM_counter+1
    
    movlw   0x0A
    mulwf   temp_diff+1, A
    movf    PRODL, W, A
    addwf   PWM_counter+1, A
    movf    PRODH, W, A
    addwfc  PWM_counter, A

    movlw   0x01
    mulwf   temp_diff+2, A
    movf    PRODL, W, A
    addwf   PWM_counter+1, A
    movf    PRODH, W, A
    addwfc  PWM_counter, A
 
;    movlw   0x0A
;    mulwf   temp_rate_diff, A
;    movf    PRODL, W, A
;    addwf   PWM_counter+1, A
;    movf    PRODH, W, A
;    addwfc  PWM_counter, A
;
;    movlw   0x01
;    mulwf   temp_rate_diff+1, A
;    movf    PRODL, W, A
;    addwf   PWM_counter+1, A
;    movf    PRODH, W, A
;    addwfc  PWM_counter, A

    return

end
