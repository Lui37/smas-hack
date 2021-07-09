@include

table table.txt

gameplay_hijack:
		lda !menu_closing
		bne .do_close_menu
		lda !menu_flag
		bne .do_menu

		; check level reset (L+R)
		lda !axlr
		and #%00110000
		cmp #%00110000
		bne +
		; die instantly
		lda #$49
		sta $BB
		bra .exit_normal
	+

		; check menu open (R + start)
		lda !axlr
		and #%00010000
		beq .exit_normal
		lda !byetudlr_1f
		and #%00010000
		beq .exit_normal

		jsr hud_menu_init
		bra .exit_frozen

	.do_close_menu:
		dec !menu_closing
		bra .exit_frozen

	.do_menu:
		phb
		phk
		plb
		jsr hud_menu
		plb

	.exit_frozen:
		jml $0D817F

	.exit_normal:
		lda $0776
		lsr
		jml $0D8118



hud_menu_init:
		inc !menu_flag
		lda $0756
		sta !menu_powerup
		lda $075E
		sta !menu_coins
		lda $075C
		inc
		sta !menu_level
		lda $075F
		inc
		sta !menu_world
		%open_menu_sfx()
		rts



hud_menu:
		; check menu closing
		lda !byetudlr_1f
		and #%00010000
		beq .execute_option

		%close_menu_sfx()
		; clear hud space
		rep #$20
		ldx #25*2
		lda #$0028
	-	sta !menu_buffer,x
		dex
		dex
		bpl -
		sep #$20
		lda #!menu_close_delay
		sta !menu_closing
		stz !menu_flag
		jmp draw_hud


	.execute_option
		lda !menu_curr_option
		asl
		tax
		jsr (hud_option_ptrs,x)

	.check_navigation:
		lda !byetudlr_1f
		bit #%00000001
		beq .check_L
		lda !menu_curr_option
		inc
		cmp #!menu_options
		bcc +
		lda #$00
	+	sta !menu_curr_option
		%navigate_menu_sfx()
		bra .finish

	.check_L
		bit #%00000010
		beq .finish
		sta $666666
		lda !menu_curr_option
		dec
		bpl +
		lda #!menu_options-1
	+	sta !menu_curr_option
		%navigate_menu_sfx()

	.finish:
		rep #$20
		lda #$2C62
		sta !menu_buffer
		lda #$0028
		sta !menu_buffer+2
		sta !menu_buffer+(24*2)
		lda #$2C63
		sta !menu_buffer+(25*2)
		
draw_hud:
		rep #$30
		ldx !vram_buffer_index
		lda #$2358
		sta !vram_buffer_dest,x
		lda #$3300
		sta !vram_buffer_size,x
		ldy #$0000
	-	lda !menu_buffer,y
		sta !vram_buffer_data,x
		inx
		inx
		iny
		iny
		cpy.w #26*2
		bcc -
		lda #$FFFF
		sta !vram_buffer_data,x
		inx
		inx
		inx
		inx
		stx !vram_buffer_index
		sep #$30
		rts



hud_option_ptrs:
		dw edit_powerup
		dw edit_coins
		dw warp



edit_powerup:
		lda !byetudlr_1f
		bit #%00001000
		beq .check_dec
		lda !menu_powerup
		inc
		cmp #$03
		bcc +
		lda #$00
	+	sta !menu_powerup
		%edit_value_sfx()
		bra .check_confirm

	.check_dec:
		bit #%00000100
		beq .check_confirm
		lda !menu_powerup
		dec
		bpl +
		lda #$02
	+	sta !menu_powerup
		%edit_value_sfx()

	.check_confirm
		lda !byetudlr_1f
		bpl .draw
		lda !menu_powerup
		sta $0756
		bne .not_small
		lda #$01
		sta $0754
		%pipe_sfx()
		bra +
	.not_small:
		stz $0754
		%powerup_sfx()
	+

	.draw:
		rep #$10
		%draw_static_tiles()

		; draw powerup name
		rep #$20
		lda !menu_powerup
		and #$00FF
		asl
		tax
		lda .value_tiles_ptr,x
		sta $00
		ldx.w #(10+4)*2
		sep #$20
		ldy #$0004
	-	lda ($00),y
		sta !menu_buffer+4,x
		dex
		dex
		dey
		bpl -
		sep #$10
		rts

	.tiles:
		db "POWERUP = 00000       "
	.props:
		db "bbbbbbbbbblllllbbbbbbb"

	.value_tiles_ptr
		dw .small
		dw .big
		dw .fire

	.small:
		db "SMALL"
	.big:
		db "BIG  "
	.fire:
		db "FIRE "



edit_coins:
		lda !byetudlr
		and #%01000000
		beq .check_inc
		lda !byetudlr_1f
		bit #%00001000
		beq .check_big_dec
		lda !menu_coins
		clc
		adc.b #10
		cmp.b #100
		bcc +
		sbc.b #100
	+	sta !menu_coins
		%edit_value_sfx()
		bra .check_confirm
		
	.check_big_dec
		bit #%00000100
		beq .check_confirm
		lda !menu_coins
		sec
		sbc.b #10
		bpl +
		adc.b #100
	+	sta !menu_coins
		%edit_value_sfx()
		bra .check_confirm
		
	.check_inc:
		lda !byetudlr_1f
		bit #%00001000
		beq .check_dec
		lda !menu_coins
		inc
		cmp.b #100
		bcc +
		lda #$00
	+	sta !menu_coins
		%edit_value_sfx()
		bra .check_confirm
		
	.check_dec:
		bit #%00000100
		beq .check_confirm
		lda !menu_coins
		dec
		bpl +
		lda.b #99
	+	sta !menu_coins
		%edit_value_sfx()
		
	.check_confirm
		lda !byetudlr_1f
		bpl .draw
		; update coin count
		lda !menu_coins
		sta $075E
		; update bcd coin count
		jsr hex_to_dec
		sty $07DE
		sta $07DF
		; update counter on the hud
		phb
		lda #$0D
		pha
		plb
		lda #$A2
		phk
		pea.w .jslrtsret-1
		pea $839F-1
		jml $0D983D
	.jslrtsret:
		plb
		%coin_sfx()
		
	.draw
		rep #$10
		%draw_static_tiles()
		sep #$10
		
		lda !menu_coins
		jsr hex_to_dec
		sty !menu_buffer+4+(8*2)
		sta !menu_buffer+4+(9*2)
		rts

	.tiles:
		db "COINS x 00            "
	.props:
		db "bbbbbbbbllbbbbbbbbbbbb"
		
hex_to_dec:
		ldy #0
	-	cmp #10
		bcc +
		sbc #10
		iny
		bra -
	+
		rts



; 075c -> level number
; 075f -> world number
; 0760 -> sublevel number (world relative)
warp:
		lda !byetudlr
		and #%01000000
		beq .check_inc
		lda !byetudlr_1f
		bit #%00001000
		beq .check_big_dec
		lda !menu_world
		inc
		cmp #$0E
		bcc +
		lda #$01
	+	sta !menu_world
		%edit_value_sfx()
		bra .check_confirm
		
	.check_big_dec:
		bit #%00000100
		beq .check_confirm
		lda !menu_world
		dec
		bne +
		lda #$0D
	+	sta !menu_world
		%edit_value_sfx()
		bra .check_confirm
		
	.check_inc:
		lda !byetudlr_1f
		bit #%00001000
		beq .check_dec
		lda !menu_level
		inc
		cmp #$05
		bcc ++
		lda !menu_world
		inc
		cmp #$0E
		bcc +
		lda #$01
	+	sta !menu_world
		lda #$01
	++	sta !menu_level
		%edit_value_sfx()
		bra .check_confirm

	.check_dec:
		bit #%00000100
		beq .check_confirm
		lda !menu_level
		dec
		bne ++
		lda !menu_world
		dec
		bne +
		lda #$0D
	+	sta !menu_world
		lda #$04
	++	sta !menu_level
		%edit_value_sfx()

	.check_confirm
		lda !byetudlr_1f
		bpl .draw
		; set destination level
		lda !menu_level
		dec
		sta $075C
		lda !menu_world
		dec
		sta $075F
		asl
		asl
		adc $075C
		tax
		lda .sublevels,x
		sta $0760
		; internal area id and map type handler
		jsl $0EC34C
		
		; warp away
		stz $0772
		stz !menu_flag
		; warp type
		stz $0752
		; hidden 1up flag
		lda #$01	
		sta $075D
		; restart timer
		sta $0757
		; normal gameplay
		sta $0770
		; enable hard mode for letter worlds
		ldy #$00
		lda $075F
		cmp #$09
		bcc +
		iny
	+	sty $07FB
		sty $076A
		%confirm_sfx()

		; clear hud
		rep #$20
		ldx #25*2
		lda #$0028
	-	sta !menu_buffer,x
		dex
		dex
		bpl -
		; oops
		pla
		sep #$20
		jmp draw_hud

	.draw:
		rep #$10
		%draw_static_tiles()
		sep #$10

		lda !menu_world
		sta !menu_buffer+4+(8*2)
		lda !menu_level
		sta !menu_buffer+4+(10*2)
		rts

	.tiles:
		db "WARP TO 0-0           "
	.props:
		db "bbbbbbbblllbbbbbbbbbbb"

	.sublevels:
		db $00,$02,$03,$04 ; w1
		db $00,$01,$02,$03 ; w2
		db $00,$02,$03,$04 ; w3
		db $00,$01,$02,$03 ; w4
		db $00,$02,$03,$04 ; w5
		db $00,$02,$03,$04 ; w6
		db $00,$01,$02,$03 ; w7
		db $00,$01,$02,$03 ; w8
		db $00,$01,$02,$03 ; w9
		db $00,$02,$03,$04 ; wA
		db $00,$02,$03,$04 ; wB
		db $00,$01,$02,$03 ; wC
		db $00,$01,$02,$03 ; wD



level_tick:
		; not on title screen
		lda $0770
		beq +
		; player action
		lda $0F
		cmp #$08
		bcc +
		cmp #$0B
		beq +
		lda $BB
		cmp #$02
		bpl +
		lda $078F
		beq +

		rep #$30
		ldx !vram_buffer_index
		lda #$7C58
		sta !vram_buffer_dest,x
		lda #$0100
		sta !vram_buffer_size,x
		sep #$20
		lda $078F
		dec
		sta !vram_buffer_data,x
		lda #$20
		sta !vram_buffer_data+1,x
		inx
		inx
		lda #$FF
		sta !vram_buffer_data,x
		inx
		inx
		inx
		inx
		stx !vram_buffer_index
		sep #$30
	+
		rtl



og_hud_init:
		; clean up rule excess
		rep #$21
		lda #$4B58
		sta !vram_buffer_dest,y
		lda #$0500
		sta !vram_buffer_size,y
		lda #$0028
		sta !vram_buffer_data,y
		sta !vram_buffer_data+2,y
		sta !vram_buffer_data+4,y
		tya
		adc.w #10
		tay
		sep #$20
		lda #$FF
		sta $1702,y
		rtl



level_win:
		jsr draw_21rule_excess
		lda #$06
		sta $07A2,x
		rtl
		
world_win:
		jsr draw_21rule_excess
		lda #$08
		rtl

draw_21rule_excess:
		phx
		rep #$20
		ldx !vram_buffer_index
		lda #$4B58
		sta !vram_buffer_dest,x
		lda #$0500
		sta !vram_buffer_size,x
		lda #$201B
		sta !vram_buffer_data,x
		lda #$2064
		sta !vram_buffer_data+2,x
		sep #$20
		lda $0787
		sta !vram_buffer_data+4,x
		lda #$20
		sta !vram_buffer_data+5,x
		lda #$FF
		sta !vram_buffer_data+6,x
		rep #$21
		txa
		adc.w #10
		sta !vram_buffer_index
		sep #$30
		plx
		rts

