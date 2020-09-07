@include

nmi_hijack:
		sta $0000
		lda #$0000
		tcd
		lda !context_index
		and #$00FF
		tay
		ldx byetudlr,y
		lda $00,x
		and #$0020
		beq .end
		ldx axlr,y
		lda $00,x
		bit #$0010
		bne save_state
		bit #$0020
		beq .end
		jmp load_state
		
	.end:
		rts

byetudlr:
	dw $00F8, $0FFC, $0FFC, $00F6, $00FA
	
axlr:
	dw $00FA, $0FFD, $0FFD, $00F8, $00FC

apu_mirrors:
	dw $0060, $1600, $1600, $1DE0, $1200



save_state:
		; play sound
		lda !context_index
		and #$00FF
		tay
		ldx apu_mirrors,y
		sep #$20
		lda #$5C
		sta $03,x
		; fblank and disable nmi
		lda #$80
		sta $2100
		stz $4200
		
		rep #$20
		sep #$10
		
		; wram -> $710000-$747FFF ($20000)
		stz $2181	; wram address
		ldx #$00
		stx $2183
		stz !dma_source
		ldx #$71
		stx !dma_source_bank
		lda #$8080	; 1 reg, B->A, $2180 source
		sta !dma_control
		lda #$8000
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		stz !dma_source
		ldx #$72
		stx !dma_source_bank
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		stz !dma_source
		ldx #$73
		stx !dma_source_bank
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		stz !dma_source
		ldx #$74
		stx !dma_source_bank
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		; cgram -> $702000-$7021FF ($200)
		ldx #$00	; cgram address
		stx $2121
		lda #$2000
		sta !dma_source
		ldx #$70
		stx !dma_source_bank
		lda #$0200
		sta !dma_size
		lda #$3B80	; 1 reg, B->A, $213B source
		sta !dma_control
		ldx #$01
		stx !dma_enable
		
		; vram -> $750000-$767FFF ($10000)
		ldx #$80	; increment on high byte reads
		stx $2115
		stz $2116	; vram address
		lda $2139	; vram dummy read
		stz !dma_source
		ldx #$75
		stx !dma_source_bank
		lda #$8000
		sta !dma_size
		lda #$3981	; 2 regs, B->A, $2139 source
		sta !dma_control
		ldx #$01
		stx !dma_enable
		
		lda #$4000	; vram address
		sta $2116
		lda $2139	; vram dummy read
		stz !dma_source
		ldx #$76
		stx !dma_source_bank
		lda #$8000
		sta !dma_size
		ldx #$01	; dma 0
		stx !dma_enable
		
		; sp -> $702200
		tsc
		sta $702200
		
	-	ldx $4212
		bpl -
		ldx $4210
		
		; turn on screen and reeanble nmi
		ldx #$0f
		stx $2100
		ldx #$81
		stx $4200
		rep #$10
		rts



load_state:
		sep #$20
		; fblank and disable nmi
		lda #$80
		sta $2100
		stz $4200
		
		rep #$20
		sep #$10
		
		; wram <- $710000-$747FFF ($20000)
		stz $2181	; wram address
		ldx #$00
		stx $2183
		stz !dma_source
		ldx #$71
		stx !dma_source_bank
		lda #$8000
		sta !dma_control	; 1 reg, A->B, $2180 dest
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		stz !dma_source
		ldx #$72
		stx !dma_source_bank
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		stz !dma_source
		ldx #$73
		stx !dma_source_bank
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		stz !dma_source
		ldx #$74
		stx !dma_source_bank
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		; cgram <- $702000-$7021FF ($200)
		ldx #$00	; cgram address
		stx $2121
		lda #$2000
		sta !dma_source
		ldx #$70
		stx !dma_source_bank
		lda #$0200
		sta !dma_size
		lda #$2202	; 1 reg twice, A->B, $2122 dest
		sta !dma_control
		ldx #$01
		stx !dma_enable
		
		; vram <- $750000-$767FFF ($10000)
		ldx #$80	; increment on high byte reads
		stx $2115
		stz $2116	; vram address
		stz !dma_source
		ldx #$75
		stx !dma_source_bank
		lda #$8000
		sta !dma_size
		lda #$1801	; 2 regs, B->A, $2118 dest
		sta !dma_control
		ldx #$01
		stx !dma_enable
		
		lda #$4000				; vram address
		sta $2116
		stz !dma_source
		ldx #$76
		stx !dma_source_bank
		lda #$8000
		sta !dma_size
		ldx #$01
		stx !dma_enable
		
		; sp <- $702200
		lda $702200
		tcs
		
		; fix music
		rep #$10
		lda !context_index
		and #$00ff
		tay
		ldx apu_mirrors,y
		sep #$20
		lda $06,x	; backup of current music
		cmp $2142
		beq +
		sta $2142
	+
	
		; why do i need this
		ldx byetudlr,y
		lda $00,x
		and #$10
		sta $00,x
		
		; reeanble nmi
		sep #$30
		lda #$81
		sta $4200
		ldx #!load_delay
		lda #$80
	-	dex
		bmi +
		ldy $4211
		wai
		sta $2100
		wai
		sta $2100
		bra -
	+	stz $2100
		rep #$30
		rts
