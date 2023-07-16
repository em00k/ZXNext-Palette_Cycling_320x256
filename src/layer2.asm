clsL2:
	; Clears L2 252x192 with A as colour 
	; IN A > colour 
	; USES : hl, de, bc, a 	
	 
	ld          (.colour+1), a 
	ld          a, $12 
	call        getRegister 
	add         a, a                ; A = start of L2 ram 
	ld          b, 3                ; 3 blocks to do 
.L2loop:
	push        bc 
	nextreg     MMU0_0000_NR_50, a  ; set 0 - $1fff 
	inc         a 
	nextreg     MMU1_2000_NR_51, a  ; set 0 - $1fff 
	inc         a 

	ld          hl, 0 
	ld          de, 1 
.colour: 
	ld          (hl), 20            ; smc from above 
	ld          bc, $3fff
	ldir 
	pop         bc 
	djnz        .L2loop 
	
	; restore ROMS 

	nextreg     MMU0_0000_NR_50, $ff 
	nextreg     MMU1_2000_NR_51, $ff 

	; clear ULA 
	ld          hl, 16384
	ld          de, 16385
	ld          bc, 6912
	ld          (hl), 0 
	ldir 

	ret     


draw_map:

	; draws nn tiles from x,y to fille the screen 
	; IN IX > map to draw 
	; IN IY > width x height 

	ld          a, 0            ; black 
	call        clsL2           ; clear L2 

	ld 			d, iyh 			; width 
	ld 			e, iyl			; height 
	mul 		d, e 	
	ld 			b, d 
	ld 			c, e 			; number of tiles to draw  			

	ld          de,$00'00           ; d = x  e = y 


.maploop:       ; lets draw 768 tiles 
	 
	push        bc              ; save tile counter 
	ld          h, (ix)         ; get the tile at ix 
	ld          a, 26           ; bank 

	call        dotile_8x8
	
	inc         ix              ; move to next tile 
	inc         d               ; X + 1 
	ld          a, d 
	cp          iyh              ; is X = width?

	jr          nz, .no_inc_e   ; no, then skip to .no_inc_e

	inc         e               ; X=32 so make Y+1
	ld          d, 0            ; X = 0 

.no_inc_e:

	pop         bc              ; bring back tile counter 
	dec         bc 
	ld          a, b 
	or          c 
	jr          nz,.maploop 

	ret 


dotile_8x8:

	; a > bank 
	; h > tile 
	; de > xy 


	; Draws a tile h from bank a. de = x y .Total tile size can be 16kb
	; required bank is auto paged into $0000-$3FFF
	; 256x192 L2 8x8 256 colour tile

	push        de                                                              ; save XY 
	bit         7,h			; 8 t 		                                        ; is the tile >=128?
	jr          z,.noinc	 	; 12 / 7t 	20                                  ; no then jump forward 
	inc         a 			; 4 		24                                      ; yes increase base bank to 8192-16384

.noinc: 

	nextreg     MMU0_0000_NR_50, a                                              ; set 0 - $1fff ,a 		; set correct bank 

	; Grab tile, x, y 
	ld          a,h			        ; tile
	ld          l,d			        ; x
	ld          h,e			        ; y
	
	and         127                 ; we need to wrap over 127 as we have adjusted the base bank 

	; modified from the original dotile8x8 by Michael "Flash" Ware
	
	ld          d,64                ; find offset in data, each tile is 8x8 = 64, so multiply 64*tilenumber 
	ld          e,a					; 11
	mul         d,e                 ; de holds offset 

	ld          a,%00000000			; tiles at $0
	or          d		 			; or MSB of offset 
	ex          de,hl				; swap offset with xy
	ld          h,a					; 
	ld          a,e
	rlca
	rlca
	rlca
	ld          e,a					; 4+4+4+4+4 = 20	; mul x,8
	ld          a,d
	rlca
	rlca
	rlca
	ld          d,a					; 4+4+4+4+4 = 20	; mul y,8
	and         192
	or          3						; or 3 to keep layer on				; 8
	ld          bc,LAYER2_ACCESS_P_123B
	out         (c),a      			; 21			; select bank

	ld          a,d
	and         63
	ld          d,a					; clear top bits of y (dest) (4+4+4 = 12)
	; T96 here
	ld          a,8					; 7
.plotTilesLoop2:
	push        de					; 11
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi		    ; 8 * 16 = 128
	
	pop         de					; 11
	inc         d					; 4 add 256 for next line down
	dec         a					; 4
	jr          nz,.plotTilesLoop2			; 12/7

	
	ld          a,2                 ; writes off, L2 enable 
	ld          bc,LAYER2_ACCESS_P_123B
	out         (c),a               ; 21			; select bank
	pop         de                  ; restore xy 

	ret 



hide_ula:

	; clips ULA to 0,0

	nextreg     CLIP_ULA_LORES_NR_1A, 0 
	nextreg     CLIP_ULA_LORES_NR_1A, 0 
	nextreg     CLIP_ULA_LORES_NR_1A, 0 
	nextreg     CLIP_ULA_LORES_NR_1A, 0 
	ret 