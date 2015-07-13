;******************************************************************************
; DESCRIPCIÓN: ESTE ARCHIVO CONTIENE ISR (INTERRUPT SERVICE ROUTINE)
; DISPOSITIVO: DSPIC30F3013
;******************************************************************************
    .equ __30F3013, 1
    .include "p30F3013.inc"
;******************************************************************************
; DECLARACIONES GLOBALES
;******************************************************************************
    .global _activarT3
    .global _BIN_TO_BCD
    .global _INTERRUPCION_ADC
    .global __ADCInterrupt
    .global __AD1Interrupt
    .global __ADC1Interrupt
    .global __ADC2Interrupt
    .global __T3Interrupt


;******************************************************************************
;DESCRICION:	ESTA RUTINA INICIALIZA INTERRUPCION T3 (TIMER 3)
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
_activarT3:
    BCLR    IFS0, #T3IF
    BSET    IEC0, #T3IE
RETURN

;******************************************************************************
;DESCRICION:	ISR T3 (TIMER 3)
;******************************************************************************
__T3Interrupt:
    ;BTG    LATD, #RD8
    BTG     LATD, #LATD8
    NOP
    BCLR   IFS0, #T3IF
RETFIE
;******************************************************************************
;DESCRICION:	ISR ADC
;******************************************************************************
__ADCInterrupt:
    BCLR    IFS0, #ADIF
    NOP
RETFIE
;******************************************************************************
;DESCRICION:	ISR ADC
;******************************************************************************
__AD1Interrupt:
    BCLR    IFS0, #ADIF
    NOP
RETFIE
;******************************************************************************
;DESCRICION:	ISR ADC
;******************************************************************************
__ADC1Interrupt:
    BCLR    IFS0, #ADIF
    NOP
RETFIE

;******************************************************************************
;DESCRICION:	ISR ADC
;******************************************************************************
__ADC2Interrupt:
    BCLR    IFS0, #ADIF
    NOP
RETFIE




;***********************************************
; Provisional mientras vemos qué pasa con ADCInt
;***********************************************
_INTERRUPCION_ADC:
    ;Envio a UART --------------
    MOV     ADCBUF0,    W0
                                    ; Se copia w0 a w2 ya que _BIN_to_BCD usa el registro W2 como dividendo
    MOV     W0,         W2

    MOV     W0,         W1
    AND     #0x3F,      W1          ; Parte baja de registro
    
    LSR     W0,         #6,     W3  ; Parte alta de registro
    BSET    W3,         #7

    MOV     W1,         U1TXREG
    NOP
    MOV     W3,         U1TXREG
    CALL   _BIN_TO_BCD
   
    MOV     ADCBUF1,    W2
    CALL   _BIN_TO_BCD
   
    BCLR    IFS0, #ADIF
    NOP
RETFIE


;******************************************************************************
;DESCRICION:	Obtiene la representacion VCD
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
_BIN_TO_BCD:
    PUSH.S
    MOV     #10, W4
    DIVIDE:
        REPEAT  #17          ; EJECUTA DIV.U 18 VECES
        DIV.U    W2, W4      ; Divide W2 ENTRE W4   ; ALMACENA EL COCIENTE en W0,  reciduo en W1 (VALOR A IMPRIMIR)

        CP0     W0
        BRA     Z, FIN_DIV
        MOV     W0 , W2
        GOTO    DIVIDE

    FIN_DIV:
        RETURN



.END
