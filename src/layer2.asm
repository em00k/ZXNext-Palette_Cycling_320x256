clsL2:
	; Clears L2 320x256 with A as colour 
	; IN A > colour 
	; USES : hl, de, bc, a 	
	 
		ld          (.colour+1), a 
		ld          a, $12 				; $12 is L2 RAM start bank register 
		call        getRegister 		; get L2 ram bank in a 
		add         a, a                ; A = start of L2 ram, we need to *2 
		ld          b, 5                ; 3 blocks to do 

.L2loop:
		push        bc 					; save loop counter 

		nextreg     MMU0_0000_NR_50, a  ; set 0 - $1fff 
		inc         a 
		nextreg     MMU1_2000_NR_51, a  ; set 0 - $1fff 
		inc         a 

		ld          hl, 0 				; start at address 0 
		ld          de, 1 
.colour: 
		ld          (hl), 20            ; smc colour from above 
		ld          bc, $3fff			; bytes to clear 
		ldir 
		pop         bc 					; bring back loop counter 
		djnz        .L2loop 			; repeat until b = 0 
		
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


set_clipping:

	; clips ULA to 0,0

		nextreg     CLIP_ULA_LORES_NR_1A, 0 
		nextreg     CLIP_ULA_LORES_NR_1A, 0 
		nextreg     CLIP_ULA_LORES_NR_1A, 0 
		nextreg     CLIP_ULA_LORES_NR_1A, 0 


		nextreg		CLIP_LAYER2_NR_18, 0 
		nextreg		CLIP_LAYER2_NR_18, 255
		nextreg		CLIP_LAYER2_NR_18, 0
		nextreg		CLIP_LAYER2_NR_18, 255 


		ret 


gen_palette:

		; A > offset 

		nextreg 		$52,28 								; bring in palette to $4000 
		ld      		hl, $4000							; point hl to start of palette 
		add     		hl, a								; hl = @palette+offset 
		ld      		de, palette_buffer					; point de to palette 
		ld      		bc, 512								; 
.uploop1:
		ldi 												; copy offset to de
		inc 			hl 									; move to next colour 
		ld      		a, b 								; have we done 512 loops?
		or      		c 
		jr      		nz,.uploop1							; no then jump to uploop1
		ld      		hl,palette_buffer					; point hl to palette_buffer 
		ld      		b,0									; 256 loops 
		nextreg 		PALETTE_CONTROL_NR_43, %00010001	; ensure L2 palette is selected 
		nextreg 		$40,0 								; move to index 0 
.uploop:
		ld      		a,(hl)								; get colour 
		nextreg 		$44, a  							; set colout 
		inc     		hl 									; move to RGB9 Blue bit but ignore 
		nextreg 		$44, 0								; 332 RGB mode so set extra bit to 0 
		inc     		hl 									; move to next colour 
		djnz    		.uploop								; repeat 
		nextreg			$44,0								; set first colour to 0
		nextreg			$44,0

		nextreg 		$52,2								; bring back bank 2 to $4000 
		ret 


pal_cycle: 

	; cycles the colours from hl 

		ld			hl,palette_buffer
		ld 			b,31									; number of colours to cycle?

		ld 			a,0										; offset into colour index 

.loadpal:

		ld 			de,palette_buffer						; set de to palette 

		ld 			a,(de)									; get the first colour 
		push 		af 										; save the value 
		ld 			hl,palette_buffer+1						; copy palette+1 back 1 space 
		ld 			de,palette_buffer
		ld 			bc,254									; do for 255 colours 
		ldir 												; 
		pop 		af 										; bring back fist colour 
		ld 			(de),a 									; place at end 
		ld 			hl,palette_buffer								; point hl to updated palette 

		ld 			b,255									; 255 loops 
		xor 		a										; flatten a 
.palloop:
		
		nextreg 	PALETTE_INDEX_NR_40,a					; move palette index to a 
		ld 			d,a 									; save a in d 
		ld 			a,(hl)									; load first value, send to NextReg
		nextreg 	$41,a 									; set the colour 
		inc 		hl 										; increase palette location 
		ld 			a,d 									; bring back palette index 
		inc 		a 										; incread palette index 
		djnz 		.palloop								; loop until all colours done 
		ret 