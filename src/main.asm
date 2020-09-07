lorom

; enable in-game savestates
!savestates ?= 1

incsrc "defines.asm"

incsrc "edits.asm"
incsrc "hijacks.asm"

if !savestates
	org $00E5C4
	incsrc "save.asm"

	warnpc $00FFC0
endif

org $0EF4C8
incsrc "hud.asm"

warnpc $0EFFFF
