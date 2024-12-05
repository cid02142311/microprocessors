#include <xc.inc>

global	


psect	udata_acs   ; reserve data space in access ram
delay_count:	ds  1

psect	fans_code, class=CODE
delay:
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return



end
