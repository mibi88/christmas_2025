; Small demo for christmas 2025.
;
; Copyright (c) 2025 Mibi88.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
; this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
; this list of conditions and the following disclaimer in the documentation
; and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
; contributors may be used to endorse or promote products derived from this
; software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.

.export MAIN

.segment "ZEROPAGE"

sprite_rotation: .res 1
seed: .res 1
randtmp: .res 1

countdown: .res 1

.segment "BSS"

sprites: .res $100

.segment "TEXT"

.include "nmi.inc"
.include "std.inc"
.include "nes.inc"
.include "ppu.inc"

.proc RAND
        STX randtmp
        LDX seed
        LDA RAND_DATA, X
        INX
        STX seed
        LDX randtmp

        RTS
.endproc

.proc UPDATE_SPRITES
        LDX sprite_rotation
        LDY #$00

    LOOP:
        LDA sprites, X
        STA $0200, Y
        INX
        INY
        BNE LOOP

        ; Rotate the sprite data by 8 sprites next time
        LDA sprite_rotation
        CLC
        ADC #4
        STA sprite_rotation

        RTS
.endproc

.proc INIT_SPRITES
        LDX #$00

    LOOP:
        JSR RAND
        STA sprites, X
        JSR RAND
        STA sprites+3, X

        TXA
        CLC
        ADC #$04
        TAX
        BNE LOOP

        RTS
.endproc

.proc MOVE_SPRITES
        LDX #$00

    LOOP:
        INC sprites, X

        LDY sprites+3, X
        JSR RAND
        AND #$03
        BEQ CONTINUE
        CMP #$01
        BEQ MOVE_RIGHT

    MOVE_LEFT:
        DEY
        TYA
        STA sprites+3, X
        JMP CONTINUE

    MOVE_RIGHT:
        INY
        TYA
        STA sprites+3, X

    CONTINUE:

        JSR RAND
        AND #$03
        BNE SKIP

        INC sprites, X

    SKIP:

        TXA
        CLC
        ADC #$04
        TAX
        BNE LOOP

        INC seed

        RTS
.endproc

.proc MAIN
        LDA #$80
        STA $2000

        JSR PPU_INIT

        LDA #%10000000
        STA ppu_ctrl
        STA PPUCTRL
        LDA #%00000000
        STA ppu_mask

        LDX #>PALETTE
        LDA #<PALETTE
        JSR LOAD_PALETTE

        LDX #$20
        LDA #$00
        JSR SET_PPU_ADDR

        LDX #>TITLE_NAM
        LDA #<TITLE_NAM
        JSR LOAD_RLE_NAM

        LDX #$00
        LDA #$00
        JSR SET_PPU_ADDR

        LDX #>TILES
        LDA #<TILES
        JSR LOAD_RLE_NAM

        LDA #%00011110
        STA ppu_mask
        LDA #%10001000
        STA ppu_ctrl

        JSR INIT_SPRITES

    LOOP:
        LDA nmi
        BEQ LOOP
        LDA #$00
        STA nmi

        LDX countdown
        CPX #$08
        BNE SKIP

        JSR MOVE_SPRITES
        LDX #$00

    SKIP:
        INX
    UPDATE:
        STX countdown
        JSR UPDATE_SPRITES

        JMP LOOP
.endproc

PALETTE:
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36

    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36
    .byte $03, $30, $16, $36

TITLE_NAM:
    .incbin "data/title.nam.rle"

TILES:
    .incbin "data/chr.chr.rle"

RAND_DATA:
    .incbin "rand.bin"
