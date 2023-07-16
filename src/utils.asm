
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


;----------------------------------------------------------------------------
;
; Jump index
;
; In:
;	A = Pointer index
;    (SP) = Pointer to jump addresses list
;
;----------------------------------------------------------------------------

JumpIndex:
		    pop	    hl				    ; Pointer to list

            add     a,  a
            add     hl, a 
		    ld	    e, (hl)
		    inc	    hl
		    ld	    d, (hl)			    ; DE = Address to jump
		    ex	    de,	hl
		    jp	    (hl)


; Vsync wait 

Vsync:	
            ld      hl, 1
.readline:	
			ld 		a,VIDEO_LINE_LSB_NR_1F
			ld 		bc,TBBLUE_REGISTER_SELECT_P_243B
			out 	(c),a
			inc 	b
			in 		a,(c)
			cp 		192				; line to wait for 
			jr 		nz,.readline
			dec 	hl 
			ld 		a,h
			or 		l 
			jr 		nz,.readline 
            ret 