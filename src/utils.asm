
;------------------------------------------------------------------------------
; Utils 

getRegister:

; IN A > Register to read 
; OUT A < Value of Register 
    
    push    bc                                  ; save BC 
    ld      bc, TBBLUE_REGISTER_SELECT_P_243B
    out     (c), a 
    inc     b 
    in      a, (c) 
    pop     bc 
    ret 

