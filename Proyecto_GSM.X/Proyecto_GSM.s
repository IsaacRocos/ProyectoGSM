
;******************************************************************************
; DESCRIPCIÓN:
; DISPOSITIVO: DSPIC30F3013
;******************************************************************************
    .equ __30F3013, 1
    .include "p30F3013.inc"


     .equ   RST,    RD8
     .equ   PWRMON, RD9
     .equ   EH1,    RB8
     .equ   EH2,    RB9


;******************************************************************************
; BITS DE CONFIGURACIÓN
;******************************************************************************
;..............................................................................
;SE DESACTIVA EL CLOCK SWITCHING Y EL FAIL-SAFE CLOCK MONITOR (FSCM) Y SE
;ACTIVA EL OSCILADOR INTERNO (FAST RC) PARA TRABAJAR
;FSCM: PERMITE AL DISPOSITIVO CONTINUAR OPERANDO AUN CUANDO OCURRA UNA FALLA
;EN EL OSCILADOR. CUANDO OCURRE UNA FALLA EN EL OSCILADOR SE GENERA UNA TRAMPA
;Y SE CAMBIA EL RELOJ AL OSCILADOR FRC
;..............................................................................
    config __FOSC, CSW_FSCM_OFF & FRC
;..............................................................................
;SE DESACTIVA EL WATCHDOG
;..............................................................................
    config __FWDT, WDT_OFF
;..............................................................................
;SE ACTIVA EL POWER ON RESET (POR), BROWN OUT RESET (BOR), POWER UP TIMER (PWRT)
;Y EL MASTER CLEAR (MCLR)
;POR: AL MOMENTO DE ALIMENTAR EL DSPIC OCURRE UN RESET CUANDO EL VOLTAJE DE
;ALIMENTACIÓN ALCANZA UN VOLTAJE DE UMBRAL (VPOR), EL CUAL ES 1.85V
;BOR: ESTE MODULO GENERA UN RESET CUANDO EL VOLTAJE DE ALIMENTACIÓN DECAE
;POR DEBAJO DE UN CIERTO UMBRAL ESTABLECIDO (2.7V)
;PWRT: MANTIENE AL DSPIC EN RESET POR UN CIERTO TIEMPO ESTABLECIDO, ESTO AYUDA
;A ASEGURAR QUE EL VOLTAJE DE ALIMENTACIÓN SE HA ESTABILIZADO (16ms)
;..............................................................................
    config __FBORPOR, PBOR_ON & BORV20 & PWRT_16 & MCLR_EN
;..............................................................................
;SE DESACTIVA EL CÓDIGO DE PROTECCIÓN
;..............................................................................
    config __FGS, CODE_PROT_OFF & GWRP_OFF
;******************************************************************************
; DECLARACIONES GLOBALES
;******************************************************************************
;..............................................................................
;ETIQUETA DE LA PRIMER LINEA DE CÓDIGO
;..............................................................................
    .global __reset
;******************************************************************************
;VARIABLES NO INICIALIZADAS EN EL ESPACIO X DE LA MEMORIA DE DATOS
;******************************************************************************
    .section .xbss, bss, xmemory
        var:    .space 10
;******************************************************************************
;CONSTANTES ALMACENADAS EN EL ESPACIO DE LA MEMORIA DE PROGRAMA
;******************************************************************************
    .section .myconstbuffer, code
    .palign 2
    INIT_COM:
        .BYTE   'A','T',0x0D
    NO_ECO:
        .BYTE   'A','T','E','0',0x0D
    TXT_MOD:
        .BYTE   'A','T','+','C','M','G','F','=','1',0x0D
    TELEFONO:
        .BYTE   'A','T','+','C','M','G','S','=','+','5','2','5','5','4','9','0','8','4','8','2','9',0x0D
    MSG_ENV:
        .BYTE   'H','O','L','A','-','E','S','C','O','M',0x0D
    DIR_LEER:
        .BYTE   'A','T','+','C','M','G','R','=','1',0x0D
    DEL_MSJ_RECV:
        .BYTE   'A','T','+','C','M','G','D','=','1',0x0D

;******************************************************************************
;SECCION DE CODIGO EN LA MEMORIA DE PROGRAMA
;******************************************************************************

.text
    __reset:
    CALL    INI_PILA_COMANDOS
    CALL    INI_PERIFERICOS
    CALL    CONFIG_UART
    CALL    CONFIG_TIMER
    CALL    CONFIG_INTERRUPCIONES
    CALL    _iniciarLCD4bits
    CALL    ACTIVAR_PERIFERICOS




INI_PILA_COMANDOS:
    MOV		#__SP_init,     W15
    MOV 	#__SPLIM_init,  W0
    MOV 	W0, SPLIM
    MOV     #tblpage(INIT_COM),  W0
    MOV     W0, TBLPAG

    RETURN

;******************************************************************************
;DESCRICION:	ESTA RUTINA INICIALIZA LOS PERIFERICOS
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
INI_PERIFERICOS:
    CLR     PORTB
    NOP
    CLR     LATB
    NOP
    MOV     #0x030F, W0     ; RB8,RB9, RB0-RB3
    MOV     W0, TRISB       ; AN0, AN1, AN2
    NOP

    CLR     PORTF
    NOP
    CLR     LATF
    NOP
    CLR     TRISF           ; F2, F3, F6, F5(UART2 TX)
    NOP
    BSET    TRISF, #TRISF4  ; UART2 RX
    NOP
    
    CLR     PORTC
    NOP
    CLR     LATC
    NOP
    BCLR    TRISC, #TRISC13 ; UART1 TX
    NOP
    BSET    TRISC, #TRISC14 ; UART1 RX
    NOP

    CLR     PORTD
    NOP
    CLR     LATD
    NOP
    CLR     TRISD           ; RST-RD8,
    NOP
    BCLR    TRISD, #TRISD9  ; PWRMON
    NOP

    RETURN




;******************************************************************************
;DESCRICION:	Esta rutina se encarga de inicializar el modem GSM
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
;     .equ   RST,    RD8
;     .equ   PWRMON, RD9
;******************************************************************************

INI_GSM:
    
    BSET    PORTD,  #RST    ; RESET = 0
    CALL    RETARDO_300MS
    ESPERA_MODEM:           ; POOL PWRMON
        BTSS    PORTD , #PWRMON
        GOTO    ESPERA_MODEM

    MOV     #tbloffset(INIT_COM), W1    ; ESTABLECER COMUNICACION
    CALL    ENVIAR_CDM_GSM

    MOV     #tbloffset(NO_ECO),   W1    ; DESHABILITAR ECO EN REPUESTA
    CALL    ENVIAR_CDM_GSM

    MOV     #tbloffset(TXT_MOD),   W1   ; ACTIVAR MODO TEXTO
    CALL    ENVIAR_CDM_GSM

    RETURN



;******************************************************************************
;DESCRICION:	Esta rutina se encarga de enviar los comandos AT al modem GSM a
;               través de la interfaz de comunicación UART.
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************

ENVIAR_CDM_GSM:
    ;CONT_LF = 2
    ;W2 = &CAD_RESP_GSM
    MOV     #0x0D,   W3  ;FIN DE CADENA
    ENVIAR_LETRA:
        BCLR    IFS1,   #U2TXIF
        NOP
        MOV     [W1++], W0
        MOV     W0,     U2TXREG

        POOL_U2TX:
            BTSS    IFS1,   #U2TXIF
            GOTO    POOL_U2TX
        CPSEQ       W0,     W2
        GOTO        ENVIAR_LETRA
        CALL        RESPUESTA_GSM
     RETURN


;******************************************************************************
;DESCRICION:	Esta rutina sirve para indicar al DSPIC30F3013 el momento en
;               que se ha recibido completamente la respuesta del modem GSM
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************

RESPUESTA_GSM:
    POOL_CONT_LF:
    ;CICLO, CONT_LF = 0 ?
    GOTO    POOL_CONT_LF
    MOV     #0,     [W2]
    RETURN



;******************************************************************************
;DESCRICION:	Esta rutina se encarga de establecer el número telefónico al
;               que será enviado el SMS además del contenido del mismo.
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************

ENVIAR_MSJ:
    MOV     #tbloffset(TELEFONO),   W1    ; ESTABLECER TELEFONO
    CALL    ENVIAR_CDM_GSM
    MOV     W0,                     W1    ; DIRECCION DEL MSJ A ENVIAR
    CALL    ENVIAR_CDM_GSM

    RETURN



;******************************************************************************
;DESCRICION:	Establece la dirección del mensaje a leer de la memoria activa
;               de la tarjeta SIM, posteriormente espera a que exista un mensaje
;               nuevo en dicha dirección, el cual será procesado por el DSPIC
;               y además será eliminado.
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************

RECIBIR_MSJ:
    MOV     #tbloffset(DIR_LEER),   W1        ; ESTABLECER DIRECCION A LEER
    CALL    ENVIAR_CDM_GSM

    ;CONDICION

    MOV     #tbloffset(DEL_MSJ_RECV),   W1    ; SE BORRA MSJ RECIBIDO
    CALL    ENVIAR_CDM_GSM

    RETURN


;******************************************************************************
;DESCRICION:	Configuración de UART1 y UART2
;|UART1 -> PC|  ,  |UART2 -> GSM|
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
CONFIG_UART:
    MOV     #0x0420, W0
    MOV     W0, U1MODE
    NOP
    MOV     #0x8000, W0
    MOV     W0, U1STA
    NOP
    MOV     #11, W0
    MOV     W0, U1BRG
    NOP

    MOV     #0x0420, W0
    MOV     W0, U2MODE
    NOP
    MOV     #0x8000, W0
    MOV     W0, U2STA
    NOP
    MOV     #11, W0
    MOV     W0, U2BRG
    NOP
RETURN


;******************************************************************************
;DESCRICION:	Configuración de TIMERS
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
CONFIG_TIMER:
    ;TIMER1 4HZ  -- Valores de Preescalador Calulados:  460800       57600        7200        1800
    CLR     TMR1
    NOP
    MOV     #57600, W0
    MOV     W0, PR1
    NOP
    MOV     #0x0010, W0
    MOV     W0, T1CON
    NOP
RETURN


;******************************************************************************
;DESCRICION:	Configuración de interrupciones del programa
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
CONFIG_INTERRUPCIONES:
    BCLR    IFS0, #T1IF
    BSET    IEC0, #T1IE
    ;BCLR    IFS0, #T1IF
    ;BSET    IEC0, #T1IE
    ; UART2: Se habilita su ISR para la recepción de las respuestas del modem GSM
    BCLR    IFS1, #U2RXIF
    BSET    IEC1, #U2RXIE
RETURN


;******************************************************************************
;DESCRICION:	Activación de perifericos
;PARAMETROS: 	NINGUNO
;RETORNO: 		NINGUNO
;******************************************************************************
ACTIVAR_PERIFERICOS:
    BSET    U1MODE, #UARTEN
    BSET    U1STA,  #UTXEN

    BSET    U2MODE, #UARTEN
    BSET    U2STA,  #UTXEN

    BSET    T1CON,  #TON
    ;BSET    T3CON,  #TON
RETURN






