@include

if !savestates
	org $0082F6
			jsr nmi_hijack
endif

; smb2j hijacks

org $0D8114
		jml gameplay_hijack

org $0D8E0F
		jsl og_hud_init
		nop

org $0D8849
		jsl world_win
		
org $0DD769
		jsl level_win
		nop
		
org $0DAC02
		jsr level_tick_hijack
org $0DFFF4
level_tick_hijack:
		jsl level_tick
		rts

warnpc $0DFFFF

org $0FD99F
		jsr pause_check
org $0FFD01
pause_check:
		lda !menu_closing
		ora !menu_flag
		bne .no_pause
		lda !axlr
		and #%00010000
		bne .no_pause
		lda !byetudlr_1f
		rts

	.no_pause:
		lda #$00
		rts

warnpc $0FFFFF

		