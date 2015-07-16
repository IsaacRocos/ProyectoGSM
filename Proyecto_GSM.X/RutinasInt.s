;******************************************************************************
; DESCRIPCIÓN: ESTE ARCHIVO CONTIENE ISR (INTERRUPT SERVICE ROUTINE)
; DISPOSITIVO: DSPIC30F3013
;******************************************************************************
    .equ __30F3013, 1
    .include "p30F3013.inc"
;******************************************************************************
; DECLARACIONES GLOBALES
;******************************************************************************
    .global _BIN_TO_BCD
    .global __T1Interrupt
    .global __U2RXInterrupt

     .equ   RST,    RD8
     .equ   PWRMON, RD9
     .equ   EH1,    RB8
     .equ   EH2,    RB9


;******************************************************************************
;DESCRICION:	ISR T1 (TIMER 1)
;******************************************************************************
__T1Interrupt:
    MOV     #SENSOR,  W0

    BTSC     PORTB,  #EH1  ; SKIP IF EH1 = 0
    GOTO     S1

    BTSC     PORTB,  #EH2  ; skip if EH2 = 0
    GOTO     S2

    MOV      #0,     W4
    MOV.B    W4,   [W2]   ;SENSOR = 0
    GOTO     FIN_T1

    S1:
        MOV      #1,     W4
        MOV.B    W4,     [W2]   ;SENSOR = 1
        GOTO        FIN_T1

    S2:
        MOV      #2,     W4
        MOV.B    W4,      [W2]   ;SENSOR = 2

    FIN_T1:
        BCLR   IFS0, #T1IF
RETFIE





;******************************************************************************
;DESCRICION:	Rutina de interrupcion para recepción de UART2
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
__U2RXInterrupt:
    PUSH    W0
    PUSH    W2
    MOV     U2RXREG,    W0
    MOV     W0,         [W2++]


    MOV     #0x0A,      W3
    CPSNE   W3,         W0
    GOTO    COMP1

    MOV     #0x0D,      W3
    CPSNE   W3,         W0
    GOTO    COMP2

    MOV     #0x3E,      W3      ; '>'
    CPSNE   W3,         W0
    GOTO    COMP3
    GOTO    FIN

    COMP1:
        MOV   #41,      W0      ; W0 = 'A'
        MOV   #CONT_LF, W4      ; W4 = CONT_LF
        DEC   [W4],     [W4]    ; CONT_LF --
        GOTO FIN

    COMP2:
        MOV   #68,      W0      ; W0 = 'D'
        GOTO FIN

    COMP3:
        MOV   #CONT_LF, W4      ; W4 = CONT_LF
        DEC   [W4],     [W4]    ; CONT_LF --

    FIN:
        MOV     W0,     U1TXREG
        NOP
        BCLR    IFS1,   #U2RXIF

    POP W2
    POP W0

    RETFIE



;******************************************************************************
;DESCRICION:	Obtiene la representacion VCD
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
_BIN_TO_BCD:
    PUSH.S
    MOV         #10, W4
    DIVIDE:
        REPEAT  #17          ; EJECUTA DIV.U 18 VECES
        DIV.U    W2, W4      ; Divide W2 ENTRE W4   ; ALMACENA EL COCIENTE en W0,  reciduo en W1 (VALOR A IMPRIMIR)

        CP0     W0
        BRA     Z,  FIN_DIV
        MOV     W0, W2
        GOTO    DIVIDE

    FIN_DIV:
        RETURN
.END

