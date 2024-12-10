#include <xc.inc>	

extrn	target_temp
extrn	temp_diff
extrn	temp_rate_diff

global	Temperature_Control


psect	udata_acs   ; reserve data space in access ram
delay_count:	ds  1
;; Define PWM parameters
FAN_PIN	    EQU  0x00	; Pin controlling the fan (could be connected to a MOSFET)
HEATER_PIN  EQU  0x00	; Pin controlling the heater (could be connected to a MOSFET)
PWM_counter:	ds  4


psect	fans_code, class=CODE
delay:
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
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

;    movlw   IDEAL_TEMP      ; Load the ideal temperature value
;    subwf   ADC_RESULT, W   ; Subtract the ADC result from the ideal temperature
;    btfss   STATUS, 2 A		; If the temperature equals the ideal, skip the next instruction
;    bra     Check_Heater_Fan; Skip comparison if temperature is not equal
    ; Execute if temperature is equal to ideal
    ; Adjust PWM duty cycle for the fan/heater based on temperature
;    call    Adjust_PWM_Duty_Cycle
;    return


no_action:
    bcf     PORTF, FAN_PIN, A
    bcf     PORTG, HEATER_PIN, A
    return

action:
    movlw   '+'
    cpfseq  temp_diff+4, A
    bra     Turn_On_Fan		    ; Jump to fan control
    
    movlw   '-'
    cpfseq  temp_diff+4, A
    bra     Turn_On_Heater	    ; Jump to heater control


Turn_On_Fan:
    ; Turn on the fan (increase PWM duty cycle to full power)
    call    Adjust_PWM_Fan	    ; Set the PWM duty cycle to maximum for the fan
    bsf     PORTF, FAN_PIN, A	    ; Turn on the fan (via PWM)
    bcf     PORTG, HEATER_PIN, A    ; Turn off the heater
    return

Turn_On_Heater:
    ; Turn on the heater (increase PWM duty cycle to full power)
    call    Adjust_PWM_Heater	    ; Set the PWM duty cycle to maximum for the heater
    bsf     PORTG, HEATER_PIN, A    ; Turn on the heater (via PWM)
    bcf     PORTF, FAN_PIN, A	    ; Turn off the fan
    return


Adjust_PWM_Fan:
    ; Adjust PWM duty cycle based on temperature difference (temp_diff)
    ; Example: Larger temperature difference will result in a higher duty cycle
    ; Scale temperature difference to PWM duty cycle (0-255 range)
    call    calculation
    movlw   0x64		    ; Scaling factor (example: 100% max for large temperature difference)
    mulwf   WREG, A		    ; Multiply temperature difference with scaling factor
    movwf   CCPR1L, A		    ; Store result in CCPR1L (duty cycle register)
    return

Adjust_PWM_Heater:
    ; Adjust PWM duty cycle for the heater based on temperature difference
    ; Scale temperature difference to PWM duty cycle (0-255 range)
    call    calculation
    movlw   0x64		    ; Scaling factor (example: 100% max for large temperature difference)
    mulwf   WREG, A		    ; Multiply temperature difference with scaling factor
    movwf   CCPR1L, A		    ; Store result in CCPR1L (duty cycle register)
    return


calculation:
    movf    temp_diff, W, A
    mullw   0x100
    


end
