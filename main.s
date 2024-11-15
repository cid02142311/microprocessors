#include <xc.inc>

extern	KeyPad_Setup

psect	code, abs

main:
    org	    0x0
    goto    start
    org	    0x100

start:
    call    KeyPad_Setup
    
end main

