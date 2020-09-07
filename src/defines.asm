@include

; constants
!load_delay = 12
!menu_options = 3
!menu_close_delay = 12

; regs
!dma_control		= $4300
!dma_dest			= $4301
!dma_source			= $4302
!dma_source_bank	= $4304
!dma_size			= $4305
!dma_enable			= $420B

; global wram
!context_index		= $7FFF00

; smb1/smb2j wram
!byetudlr			= $0FF4
!byetudlr_1f		= $0FF6
!axlr				= $0FF8
!axlr_1f			= $0FFA
!byetudlr_r			= $0FFC
!axlr_r				= $0FFD
!vram_buffer_index	= $1700
!vram_buffer_dest	= $1702
!vram_buffer_size	= $1704
!vram_buffer_data	= $1706

!freeram = $1C00

!freeram_used = 0
macro def_freeram(id, size)
	!<id> := !freeram+!freeram_used
	!freeram_used #= !freeram_used+<size>
endmacro

%def_freeram(menu_flag, 1)
%def_freeram(menu_curr_option, 1)
%def_freeram(menu_closing, 1)
%def_freeram(menu_powerup, 1)
%def_freeram(menu_coins, 1)
%def_freeram(menu_world, 1)
%def_freeram(menu_level, 1)
%def_freeram(menu_buffer, 26)

; misc macros
macro draw_static_tiles()
		ldy.w #21
		ldx.w #21*2
	-	lda .tiles,y
		sta !menu_buffer+4,x
		lda .props,y
		sta !menu_buffer+5,x
		dex
		dex
		dey
		bpl -
endmacro

macro finish_draw()
		lda #$FF
		sta !vram_buffer_data,x
		inx
		inx
		inx
		inx
		stx !vram_buffer_index
endmacro

macro open_menu_sfx()
	lda #$0E
	sta $1603
endmacro

macro edit_value_sfx()
	lda #$4C
	sta $1603
endmacro

macro confirm_sfx()
	lda #$29
	sta $1603
endmacro

macro powerup_sfx()
	lda #$58
	sta $1603
endmacro

macro pipe_sfx()
	lda #$04
	sta $1600
endmacro

macro coin_sfx()
	lda #$01
	sta $1603
endmacro

macro navigate_menu_sfx()
	lda #$3D
	sta $1600
endmacro

macro close_menu_sfx()
	lda #$33
	sta $2140
endmacro
