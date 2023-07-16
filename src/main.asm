; this example demonstrates how you can have your souce data eg. bitmap tiles in slot 0 $0000 and also write to L2
; in the same memory location. 

; em00k 16/07/23



        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        DEVICE ZXSPECTRUMNEXT
        CSPECTMAP "L2_on_SLOT01.map"

        include "hardware.inc"                          ; hardware equates 

        org     $8000

main:
        di 
        ; set up hardware 
        nextreg TURBO_CONTROL_NR_07,3                   ; 28mhz
        nextreg GLOBAL_TRANSPARENCY_NR_14,0             ; black 
        nextreg SPRITE_TRANSPARENCY_I_NR_4B,0           ; black 
        nextreg TRANSPARENCY_FALLBACK_COL_NR_4A,$0      ; black 
        nextreg SPRITE_CONTROL_NR_15,%000'100'00        ; Layer order 
        nextreg LAYER2_CONTROL_NR_70,%00000000          ; 256x192
        nextreg DISPLAY_CONTROL_NR_69,%10000000         ; bit 7 enable L2 

        ; we will use a simple map to draw L2 tiles to screen
        ; we will do this by having the source data in the same
        ; slot location as L2 writes

        xor     a
        out     ($fe), a                        ; black border 

        ld      ix, testmap                     ; point to test map data 
        ld      iy, (32*256)+24                 ; width = 32, height = 24
        
        call    draw_map                        ; draw the map 

        jr   $                                  ; repeat loop 

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

testmap:
        incbin "../assets/testmap.nxm"


;------------------------------------------------------------------------------
; Memory banks

        mmu 7   n, 26
        org     $e000 
        incbin  "../assets/testmap.nxt"                 ; L2 software tiles 


;------------------------------------------------------------------------------
; Output configuration
        SAVENEX OPEN "L2_on_SLOT01.nex", main, stack_top 
        SAVENEX CORE 3,0,0
        SAVENEX CFG 7,0,0,0
        SAVENEX AUTO 
        SAVENEX CLOSE