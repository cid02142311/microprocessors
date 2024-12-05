#include <xc.inc>
    
extrn	OUT3, OUT2, OUT1, OUT0
extrn	target_temp

global	subtraction
global	temp_diff

psect	udata_acs   ; reserve data space in access ram
temp_diff:  ds  4
arg1_1:	    ds  1
arg1_2:	    ds  1
arg1_3:	    ds  1
arg1_4:	    ds  1
arg2_1:	    ds  1
arg2_2:	    ds  1
arg2_3:	    ds  1
arg2_4:	    ds  1

psect	subtraction_code, class=CODE
subtraction:

comparison_1:
    movf    target_temp, W, A
    cpfseq  OUT3, A
    goto    great_check_1
    goto    comparison_2
great_check_1:
    cpfsgt  OUT3, A
    goto    reverse
    goto    no_reverse

comparison_2:
    movf    target_temp+1, W, A
    cpfseq  OUT2, A
    goto    great_check_2
    goto    comparison_3
great_check_2:
    cpfsgt  OUT2, A
    goto    reverse
    goto    no_reverse

comparison_3:
    movf    target_temp+2, W, A
    cpfseq  OUT1, A
    goto    great_check_3
    goto    comparison_4
great_check_3:
    cpfsgt  OUT1, A
    goto    reverse
    goto    no_reverse

comparison_4:
    movf    target_temp+3, W, A
    cpfseq  OUT0, A
    goto    great_check_4
    goto    equal
great_check_4:
    cpfsgt  OUT0, A
    goto    reverse
    goto    no_reverse

equal:
    movlw   0x00
    movwf   temp_diff, A
    movwf   temp_diff+1, A
    movwf   temp_diff+2, A
    movwf   temp_diff+3, A
    return

reverse:
    movff   target_temp, arg1_1
    movff   target_temp+1, arg1_2
    movff   target_temp+2, arg1_3
    movff   target_temp+3, arg1_4
    movff   OUT3, arg2_1
    movff   OUT2, arg2_2
    movff   OUT1, arg2_3
    movff   OUT0, arg2_4
    call    sub
    return

no_reverse:
    movff   OUT3, arg1_1
    movff   OUT2, arg1_2
    movff   OUT1, arg1_3
    movff   OUT0, arg1_4
    movff   target_temp, arg2_1
    movff   target_temp+1, arg2_2
    movff   target_temp+2, arg2_3
    movff   target_temp+3, arg2_4
    call    sub
    return


sub:
    clrf    STATUS, A
    movff   arg1_4, temp_diff+3
    movf    arg2_4, W, A
    subwf   temp_diff+3, A
    btfss   STATUS, 0, A
    goto    borrow_1
    goto    skip_borrow_1

borrow_1:
    movlw   0x01
    subwf   arg1_3, A
    movlw   0x0a
    addwf   temp_diff+3, A

skip_borrow_1:
    movff   arg1_3, temp_diff+2
    movf    arg2_3, W, A
    subwf   temp_diff+2, A
    btfss   STATUS, 0, A
    goto    borrow_2
    goto    skip_borrow_2

borrow_2:
    movlw   0x01
    subwf   arg1_2, A
    movlw   0x0a
    addwf   temp_diff+2, A

skip_borrow_2:
    movff   arg1_2, temp_diff+1
    movf    arg2_2, W, A
    subwf   temp_diff+1, A
    btfss   STATUS, 0, A
    goto    borrow_3
    goto    skip_borrow_3

borrow_3:
    movlw   0x01
    subwf   arg1_1, A
    movlw   0x0a
    addwf   temp_diff+1, A

skip_borrow_3:
    movff   arg1_1, temp_diff
    movf    arg2_1, W, A
    subwf   temp_diff, A
    return

end