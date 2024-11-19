// Esempio di sincronizzazione con doppio interrupt
        .label SCAN = $e5cd

BasicUpstart2(start)

        * = $c000
start:
        lda #$01
        sta $dc0d                       // disattiva il timer A (keyscan manuale)
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315                       // setta il primo gestore di interrupt
        lda #$0d
        sta $d012                       // la prima IRQ viene generata alla linea 13
        lda #$7f
        and $d011
        sta $d011
        lda #$01
        sta $d01a
        rts

//                 CICLI DI CLOCK
//               TRASCORSI DALL'IRQ
//              --------------------

irq1:
        lda #<irq2                      // 40-46
        sta $0314                       // 44-50
        lda #>irq2                      // 46-52
        sta $0315                       // 50-56
        lda #$0f                        // 52-58
        sta $d012                       // 56-62
        inc $d019                       // 62-68 - il raster potrebbe gia' essere sulla linea video 14
        //       (per questo e' settato l'IRQ alla linea 15)

        cli                             // linea 14    cicli 1-7 (riattiva la modalita' IRQ)

        /*
        inc $0313                       // linea 14    cicli 7-13
        dec $0313                       // linea 14    cicli 13-19
        inc $0313                       // linea 14    cicli 19-25
        dec $0313                       // linea 14    cicli 25-31
        inc $0313                       // linea 14    cicli 31-37
        dec $0313                       // linea 14    cicli 37-43
        inc $0313                       // linea 14    cicli 43-49
        dec $0313                       // linea 14    cicli 49-55
        inc $0313                       // linea 14    cicli 55-61
        nop                             // linea 14    cicli 57-63
        nop                             //  - possibile IRQ
        nop                             //  - possibile IRQ
        nop                             //  - possibile IRQ
        nop                             //  - possibile IRQ
        nop                             //  nop di margine
           */
        jmp $ea31                       //  permette al C64 le operazioni di routine
        jmp SCAN

irq2:
        ldy #$10                        // linea 15    cicli 40-41
        inc $0313                       // linea 15    cicli 46-47
        dec $0313                       // linea 15    cicli 52-53
        lda $0313                       // linea 15    cicli 56-57
fill:   inc $d020                       // linea 16    cicli 62-63  +6  -  aggiorna il bordo ogni 63 cicli di clock
        dey                             // linea 16    cicli 1-2    +2     (la durata esatta di una linea di raster)
        beq ret                         // linea 16    cicli 3-4*   +2*
        inc $0313                       // linea 16    cicli 9-10   +6
        dec $0313                       // linea 16    cicli 15-16  +6
        inc $0313                       // linea 16    cicli 21-22  +6
        dec $0313                       // linea 16    cicli 27-28  +6
        inc $0313                       // linea 16    cicli 33-34  +6
        dec $0313                       // linea 16    cicli 39-40  +6
        inc $0313                       // linea 16    cicli 45-46  +6
        dec $0313                       // linea 16    cicli 51-52  +6
        nop                             // linea 16    cicli 53-54  +2
        jmp fill                        // linea 16    cicli 56-57  +3

ret:    lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315                       // ripristina il primo GI
        lda #$0d
        sta $d012
        inc $d019                       // riabilita le interruzioni del rasterbeam
        jmp $ea81                       // torna dall'IRQ

// NOTE
// * 3 cicli quando avviene il salto (irrilevante)
