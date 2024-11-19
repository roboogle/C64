        .const AREA_MAIN_PROG = $1000
        .label USER_DATA = $02

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
        sei
        lda #$0f
        sta USER_DATA                // inizializza il contatore di riga
        lda #<irq
        sta CINV
        lda #>irq
        sta CINV+1

        // - set raster line 16 ---------------------------------------------
        lda #16
        sta RASTER
        lda SCROLY
        and #%01111111
        sta SCROLY
        // - end of set raster line 16 --------------------------------------

        lda #$01
        sta IRQMSK                      // setta il rasterbeam come possibile sorgente di interrupt
        lda #$7f
        sta CIAICR
        cli
        rts

irq:    inc EXTCOL                      //  cambia il colore del bordo
        inc RASTER                      //  setta la prossima linea come la successiva linea di interrupt
        dec USER_DATA                   //  decrementa il contatore di riga
        bne exit                        //  ultima riga?

        //  ultima riga: ricarica il contatore di riga, ripristina il bordo e le interruzioni
        lda #$0f
        sta USER_DATA
        lda #$fe
        sta EXTCOL
        lda #$10
        sta RASTER
exit:
        lsr VICIRQ                      //  permette le interruzioni successive
        jmp $ea81                       //  esce dall'interruzione


        // --------------------------------------------------
        // User data
        // --------------------------------------------------
