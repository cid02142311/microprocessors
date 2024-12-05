#include <xc.inc>

global	


psect	udata_acs   ; reserve data space in access ram
delay_count:	ds  1

psect	fans_code, class=CODE
delay:
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return


    
; Assuming the ADC is already configured and the ideal temperature is stored

; Define constants for temperature control
IDEAL_TEMP          EQU  25     ; Ideal temperature (in Celsius)
TEMP_THRESHOLD_HIGH EQU  30     ; Threshold to turn on fan (example)
TEMP_THRESHOLD_LOW  EQU  20     ; Threshold to turn on heater (example)

; Define PWM parameters
FAN_PIN             EQU  RC0    ; Pin controlling the fan (could be connected to a MOSFET)
HEATER_PIN          EQU  RC1    ; Pin controlling the heater (could be connected to a MOSFET)

; Main Program
Main:
    call    ADC_Read         ; Read temperature from LM35 via ADC
    movf    ADC_RESULT, W   ; Load the ADC result (temperature) into WREG

    ; Compare temperature with ideal value to control the fan/heater
    movlw   IDEAL_TEMP      ; Load the ideal temperature value
    subwf   ADC_RESULT, W   ; Subtract the ADC result from the ideal temperature
    btfss   STATUS, Z       ; If the temperature equals the ideal, skip the next instruction
    bra     Check_Heater_Fan; Skip comparison if temperature is not equal

    ; Execute if temperature is equal to ideal
    ; Adjust PWM duty cycle for the fan/heater based on temperature
    call    Adjust_PWM_Duty_Cycle
    goto    Main            ; Repeat the process

Check_Heater_Fan:
    ; Check if temperature is higher than ideal to turn on the fan
    movlw   TEMP_THRESHOLD_HIGH
    subwf   ADC_RESULT, W   ; Compare the temperature with the high threshold
    btfss   STATUS, Z       ; If the temperature is higher than the threshold, skip next instruction
    bra     Turn_On_Fan     ; Jump to fan control

    ; Check if temperature is lower than ideal to turn on the heater
    movlw   TEMP_THRESHOLD_LOW
    subwf   ADC_RESULT, W   ; Compare the temperature with the low threshold
    btfss   STATUS, Z       ; If the temperature is lower than the threshold, skip next instruction
    bra     Turn_On_Heater  ; Jump to heater control

    ; If no condition is met, turn off both fan and heater
    bcf     FAN_PIN         ; Turn off the fan
    bcf     HEATER_PIN      ; Turn off the heater
    goto    Main            ; Repeat the process

Turn_On_Fan:
    ; Turn on the fan (increase PWM duty cycle to full power)
    call    Set_PWM_Fan     ; Set the PWM duty cycle to maximum for the fan
    bsf     FAN_PIN         ; Turn on the fan (via PWM)
    bcf     HEATER_PIN      ; Turn off the heater
    goto    Main            ; Repeat the process

Turn_On_Heater:
    ; Turn on the heater (increase PWM duty cycle to full power)
    call    Set_PWM_Heater  ; Set the PWM duty cycle to maximum for the heater
    bsf     HEATER_PIN      ; Turn on the heater (via PWM)
    bcf     FAN_PIN         ; Turn off the fan
    goto    Main            ; Repeat the process

; Adjust PWM duty cycle based on temperature difference
Adjust_PWM_Duty_Cycle:
    ; Here we can scale the duty cycle based on how far the temperature is from the ideal
    ; Example: A larger temperature difference will result in a higher duty cycle
    movf    ADC_RESULT, W   ; Load temperature difference (absolute value) into W
    ; Apply scaling factor to adjust the PWM duty cycle
    ; (Simple example: the greater the difference, the higher the duty cycle)
    ; This part needs to be scaled depending on the range of temperatures
    return

; Set PWM duty cycle for the fan
Set_PWM_Fan:
    ; Configure PWM to maximum duty cycle (example: 100%)
    movlw   0xFF            ; Set maximum duty cycle (full on)
    movwf   CCPR1L          ; Set the duty cycle for fan
    return

; Set PWM duty cycle for the heater
Set_PWM_Heater:
    ; Configure PWM to maximum duty cycle (example: 100%)
    movlw   0xFF            ; Set maximum duty cycle (full on)
    movwf   CCPR1L          ; Set the duty cycle for heater
    return

; ADC Read function (assumed to be configured already)
ADC_Read:
    ; Your ADC reading function
    return


end
