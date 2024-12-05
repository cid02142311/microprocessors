#include <xc.inc>
    
extrn	OUT1, OUT0
extrn	POUT1, POUT0

global	differentiation
global	temp_rate_diff

psect	udata_acs   ; reserve data space in access ram
temp_rate_diff: ds  2
arg3_1:		ds  1
arg3_2:		ds  1
arg4_1:		ds  1
arg4_2:		ds  1

psect	subtraction_code, class=CODE
differentiation:

comparison_1:
    movf    POUT1, W, A
    cpfseq  OUT1, A
    goto    great_check_1
    goto    comparison_2
great_check_1:
    cpfsgt  OUT1, A
    goto    reverse
    goto    no_reverse

comparison_2:
    movf    POUT0, W, A
    cpfseq  OUT0, A
    goto    great_check_2
    goto    equal
great_check_2:
    cpfsgt  OUT0, A
    goto    reverse
    goto    no_reverse

equal:
    movlw   0x00
    movwf   temp_rate_diff, A
    movwf   temp_rate_diff+1, A
    return

reverse:
    movff   POUT1, arg3_1
    movff   POUT0, arg3_2
    movff   OUT1, arg4_1
    movff   OUT0, arg4_2
    call    sub
    return

no_reverse:
    movff   OUT1, arg3_1
    movff   OUT0, arg3_2
    movff   POUT1, arg4_1
    movff   POUT0, arg4_2
    call    sub
    return


sub:
    clrf    STATUS, A
    movff   arg3_2, temp_rate_diff+3
    movf    arg4_2, W, A
    subwf   temp_rate_diff+3, A
    btfss   STATUS, 0, A
    goto    borrow_1
    goto    skip_borrow_1

borrow_1:
    movlw   0x01
    subwf   arg3_1, A
    movlw   0x0a
    addwf   temp_rate_diff+3, A

skip_borrow_1:
    movff   arg3_1, temp_rate_diff+2
    movf    arg4_1, W, A
    subwf   temp_rate_diff+2, A

end