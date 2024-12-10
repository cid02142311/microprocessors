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

; Assume the following:
; temp_diff = 0x01, temp_diff+1 = 0x02, temp_diff+2 = 0x03, temp_diff+3 = 0x04

; Convert temp_diff (4 ASCII hex digits) into a 16-bit hex number (0x4D2)

; Step 1: Convert temp_diff to decimal and shift
movf    temp_diff, W             ; Load the most significant digit (0x01)
movlw   0x03                     ; Multiply by 1000 (shift to the thousands place)
mulwf   WREG                     ; Multiply temp_diff by 1000
movwf   temp_diff_1000           ; Store the result in temp_diff_1000 (higher digits)

; Step 2: Convert temp_diff+1 to decimal and shift (hundreds place)
movf    temp_diff+1, W           ; Load the second digit (0x02)
movlw   0x02                     ; Multiply by 100 (shift to the hundreds place)
mulwf   WREG                     ; Multiply temp_diff+1 by 100
movwf   temp_diff_100            ; Store the result in temp_diff_100 (next digit)

; Step 3: Convert temp_diff+2 to decimal and shift (tens place)
movf    temp_diff+2, W           ; Load the third digit (0x03)
movlw   0x01                     ; Multiply by 10 (shift to the tens place)
mulwf   WREG                     ; Multiply temp_diff+2 by 10
movwf   temp_diff_10             ; Store the result in temp_diff_10 (next digit)

; Step 4: Convert temp_diff+3 to decimal (ones place)
movf    temp_diff+3, W           ; Load the fourth digit (0x04)
movwf   temp_diff_1              ; Store the result in temp_diff_1 (ones place)

; Step 5: Combine all the results to form the final 16-bit hex number
; temp_diff_1000 contains the thousands place (shifted)
; temp_diff_100 contains the hundreds place
; temp_diff_10 contains the tens place
; temp_diff_1 contains the ones place

; Add temp_diff_1000 to temp_diff_100
addwf   temp_diff_1000, F
movf    temp_diff_100, W
addwf   temp_diff_1000, F       ; Add hundreds place

; Add temp_diff_10 to temp_diff_1000
movf    temp_diff_10, W
addwf   temp_diff_1000, F       ; Add tens place

; Finally, add temp_diff_1 to temp_diff_1000
movf    temp_diff_1, W
addwf   temp_diff_1000, F       ; Add ones place

; Now temp_diff_1000 contains the 16-bit number 0x4D2
; This is the final result in hex

; You can store the result or display it as needed (e.g., send to the LCD, etc.)


end
