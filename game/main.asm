        .const HAVE_CHARS = true

        // --------------------------------------------------
        // AREAS
        // --------------------------------------------------
        .const AREA_MAIN_PROG = $1000
        .const AREA_GAME_DATA = $1500
        .const AREA_SCREEN_DATA = $2000
        .const AREA_SPRITE_DATA = $2800
        // --------------------------------------------------

.if (mod(AREA_SPRITE_DATA, 64) != 0) {
        .error "AREA_SPRITE_DATA is not multiple of 64"
}
        .const SPRITE_PAGE = AREA_SPRITE_DATA / 64

        #import "mapping.asm"

        // --------------------------------------------------
        // Basic begin
        // --------------------------------------------------
        BasicUpstart2(start)


        // --------------------------------------------------
        // Main program
        // --------------------------------------------------
        * = AREA_MAIN_PROG "Main program"
start:

        jsr init_screen1
        .if (HAVE_CHARS) {
        jsr load_screen1
        }
        jsr load_sprites
        jsr computecarpos
        jsr initscore
        jsr wait_key
        jsr SCRCLR   // clear the screen
        rts

wait_key:
        ldx #0
        jsr CHKIN
!loop:  jsr GETIN
        beq !loop-
        rts

init_screen1:
        lda #$00        // Colour black
        sta EXTCOL      // border colour
        sta BGCOL0      // background colour
        rts

load_screen1:
.if (HAVE_CHARS) {
        // Load screen characters and colors
        ldx #$00
!loop:
        lda screen1_chars +$0000, x  // 0000-00ff
        sta VICSCN        +$0000, x
        lda screen1_colors+$0000, x
        sta VICCOL        +$0000, x

        lda screen1_chars +$0100, x  // 0100-01ff
        sta VICSCN        +$0100, x
        lda screen1_colors+$0100, x
        sta VICCOL        +$0100, x

        lda screen1_chars +$0200, x  // 0200-02ff
        sta VICSCN        +$0200, x
        lda screen1_colors+$0200, x
        sta VICCOL        +$0200, x

        inx
        bne !loop-

        ldx #$e8        // here x is in e8..1
!loop:
        lda screen1_chars +$0300-1, x
        sta VICSCN        +$0300-1, x  // 0300-03e7 (final)
        lda screen1_colors+$0300-1, x
        sta VICCOL        +$0300-1, x

        dex
        bne !loop-

        rts
        }

load_sprites:
        lda #%00000000 // No sprites
        sta XXPAND     // expanded X
        sta YXPAND     // expanded Y
        sta SPBGPR     // behind bg

        lda #%11111111
        sta SPENA      // All sprites enable

        lda #$00
        sta SPSPCL      // Init collision

        lda #5          // Fairer collision timer
        sta colltimer

        // Video Matrix Base Address Nibble of the VIC-II Memory Control Register
        //lda #$14        // Default C64 charset
        //sta VMCSB       // mode BANK

        // Sets sprint data and color
        ldx #$00
!loop:
        lda #SPRITE_PAGE    // This make sprite_x data address point
        sta VICSP1A, x      // to 13*64=$0340 which is in TBUFFER area

        lda carcolor, x
        sta SP0COL, x       // set sprite color
        inx
        cpx #8
        bne !loop-

        // set cars logical position
        ldx #$00
!loop:
        lda startpos, x
        sta carpos, x
        inx
        cpx #16 // 16 bytes position
        bne !loop-
        rts


// Convert all virtual car positions to
// hardware sprite positions.
computecarpos:
        ldx #$00
!loop:
        lda carpos+1, x         // Read Y position
        sta SP0Y, x             // Store sprite Y
        lda carpos, x           // Read X position

        // set msb (it works only with 8 cars)
        asl                     // take the msb -> carry
        ror MSIGX               // carry -> msb X sprite pos

        sta SP0X, x             // Store sprite X
        inx                     // X sprite pos
        inx                     // Y sprite pos
        cpx #16 // 16 positions
        bne !loop-
        rts

initirq:                                //Prepare IRQ raster interrupt
        sei
        ldx #<irq_raster                // IRQ flag pos lo
        ldy #>irq_raster                // IRQ flag pos hi
        stx CINV                        // Store IRQ flag lo
        sty CINV+1                      // Store IRQ flag hi

        lda #%01111111
        sta CIAICR                      // disable all interrupts
        sta CI2ICR
        lda #50                         // Raster pos line 50
        sta RASTER
        lda #%00011011                        // VScreen default
        sta SCROLY
        lda #$01                        // IRQ speeder
        sta IRQMSK
        cli                             // Clear IRQ
        rts


initscore:  // Initialize score to 000000
        ldx #$07
        lda #$30 // digit 0
!loop:  sta score-1,x
        dex
        bne !loop-
        jsr maskpanel
        rts

maskpanel:
        rts

irq_raster:
        rts

// -----------------------------------------------
// Data area
// --------------------------------------------------
        .if (HAVE_CHARS) {
        * = AREA_SCREEN_DATA  "Screens area"
        #import "screens.asm"
        }
        /* Here we use the Cassette I/O Buffer to store sprite data that
        can be directly accessed by VIC */
        * = AREA_SPRITE_DATA  "Sprite data"
        #import "sprites.asm"

        * = AREA_GAME_DATA "Game data"
colltimer:
        .byte 0

carcolor:
        .byte $0a,$0d,$0f,$0e
        .byte $04,$07,$0a,$0c

        // Start car position table.
        // Data are pairs of (X, Y) positions
startpos:
        .byte $56,$da //Car 1-Sprite 0
        .byte $2e,$80 //Car 2-Sprite 1
        .byte $42,$c0 //Car 3-Sprite 2
        .byte $56,$40 //Car 4-Sprite 3
        .byte $6a,$80 //Car 5-Sprite 4
        .byte $42,$c0 //Car 6-Sprite 5
        .byte $7e,$00 //Car 7-Sprite 6
        .byte $2e,$40 //Car 8-Sprite 7

        // Car position table. Car 1 is the main
        // player. Cars 2 - 8 are the baddies.
        // Data are pairs of (X, Y) positions
carpos:
        .fill 8, [$00,$00]  // Cars positions

        // six digits for the score
score:
        .fill 6, $00
