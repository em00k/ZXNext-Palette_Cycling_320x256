; this example demonstrates palette cycling on a precalculated 320x256 image

; em00k 16/07/23



        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        DEVICE ZXSPECTRUMNEXT
        CSPECTMAP "320Cycle.map"

        include "hardware.inc"                          ; hardware equates 

        output   main.bin 
        org     $8000

main:
        di 
        ; set up hardware 
        nextreg TURBO_CONTROL_NR_07,3                   ; 28mhz
        nextreg GLOBAL_TRANSPARENCY_NR_14,0             ; black 
        nextreg SPRITE_TRANSPARENCY_I_NR_4B,0           ; black 
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A,$0      ; black 
        nextreg SPRITE_CONTROL_NR_15,%00001011          ; Layer order 
	nextreg LAYER2_CONTROL_NR_70,%000'1'0000        ; 320x256 L2
        nextreg ULA_CONTROL_NR_68, %10000000            ; turn off ULA 
	        						
        nextreg LAYER2_RAM_BANK_NR_12,9                 ; layer2 rams   16kb banks so 9*2 = BANKS 18
	nextreg DISPLAY_CONTROL_NR_69,%10000000

        call    set_clipping                            ; clip L2 to 320x256 and ULA to 0x0

        nextreg PALETTE_CONTROL_NR_43,%00010000		; set L2 palette 
        ld      a, 200                                   ; lower value will use more colours form the palette                                           
        call    gen_palette                             ; generate palette 
        
        xor     a
        out     ($fe), a                                ; black border 


main_loop:

        call    Vsync                                   ; wait for vsync 
        call    pal_cycle                               ; cycle colours 
        
        jr      main_loop                               ; repeat loop 

;------------------------------------------------------------------------------
; Stack reservation
STACK_SIZE      equ     100

stack_bottom:
        defs    STACK_SIZE * 2
stack_top:
        defw    0

;------------------------------------------------------------------------------
; includes 

        include "utils.asm"
        include "layer2.asm"

        outend 

;------------------------------------------------------------------------------
; Data section 

palette_buffer:                                         ; used to cache palette for cycling 
        defs    512,0 

;------------------------------------------------------------------------------
; Memory banks

        mmu 7   n, 18                                   ; load to bank 18 which is the start of L2 memory
        org     $e000 
        incbin  "../assets/output320.bin"               ; precalculated image   
        mmu 7   n, 28
        org     $e000 
        incbin  "../assets/rainbow.pal"                 ; palette for cycling 


;------------------------------------------------------------------------------
; Output configuration
        SAVENEX OPEN "320Cycle.nex", main, stack_top 
        SAVENEX CORE 3,0,0
        SAVENEX CFG 7,0,0,0
        SAVENEX AUTO 
        SAVENEX CLOSE