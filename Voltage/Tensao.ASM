;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*              MODIFICA��ES PARA USO COM 12F675                   *
;*                FEITAS PELO PROF. MARDSON                        *
;*                    FEVEREIRO DE 2016                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       NOME DO PROJETO                           *
;*                           CLIENTE                               *
;*         DESENVOLVIDO PELA MOSAICO ENGENHARIA E CONSULTORIA      *
;*   VERS�O: 1.0                           DATA: 17/06/03          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRI��O DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   MODELO PARA O PIC 12F675                                      *
;*                                                                 *
;*                                                                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINI��ES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <P12F675.INC>	;ARQUIVO PADR�O MICROCHIP PARA 12F675

	__CONFIG _BODEN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _MCLRE_ON & _INTRC_OSC_NOCLKOUT

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    PAGINA��O DE MEM�RIA                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;DEFINI��O DE COMANDOS DE USU�RIO PARA ALTERA��O DA P�GINA DE MEM�RIA
#DEFINE	BANK0	BCF STATUS,RP0	;SETA BANK 0 DE MEM�RIA
#DEFINE	BANK1	BSF STATUS,RP0	;SETA BANK 1 DE MAM�RIA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARI�VEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DOS NOMES E ENDERE�OS DE TODAS AS VARI�VEIS UTILIZADAS 
; PELO SISTEMA

	CBLOCK	0x20	;ENDERE�O INICIAL DA MEM�RIA DE
					;USU�RIO
		W_TEMP		;REGISTRADORES TEMPOR�RIOS PARA USO
		STATUS_TEMP	;JUNTO �S INTERRUP��ES

		WRD			;USADO PARA O PRINT		
		COUNT		;USADO PARA A DIVIS�O EM 4 BIT
		;EXCLUSIVOS PARA O LCD
		
		TEMP_ADH
		TEMP_ADL

		;PARA A SOMA DAS LEITURAS

		AVG_ADH
		AVG_ADL
			
		;PARA A MEDIA DOS VALORES
		
		AVG_COUNT	

	ENDC			;FIM DO BLOCO DE MEM�RIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA
	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS PINOS QUE SER�O UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMB�M COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

#DEFINE		SR_CLK		GPIO,0
#DEFINE		SR_DAT		GPIO,4
#DEFINE		LCD_EN		GPIO,5	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SA�DAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS PINOS QUE SER�O UTILIZADOS COMO SA�DA
; RECOMENDAMOS TAMB�M COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x00			;ENDERE�O INICIAL DE PROCESSAMENTO
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    IN�CIO DA INTERRUP��O                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDERE�O DE DESVIO DAS INTERRUP��ES. A PRIMEIRA TAREFA � SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERA��O FUTURA

	ORG	0x04			;ENDERE�O INICIAL DA INTERRUP��O
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUP��O                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SER� ESCRITA AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUP��ES

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SA�DA DA INTERRUP��O                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUP��O

SAI_INT
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	RETFIE

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRI��O DE FUNCIONAMENTO
; E UM NOME COERENTE �S SUAS FUN��ES.

LIMPA_T0FLAG

	BCF		INTCON,T0IF		;LIMPA A FLAG
	BCF		INTCON,T0IE		;DESABILITA AS INTERRUP��ES

	RETURN

COUNT_RESET					
	MOVLW 	.4
	MOVWF	COUNT

	RETURN
SETUP
	CALL 	COUNT_RESET			;QUANTIDADE DE ROTA��ES 

	CALL 	W_15MS				;ESPERA > 15 MS 

	MOVLW	b'00110000'			;MANDA 0X30 PARA O LCD
	MOVWF	WRD
	
	CALL 	SEND_LCD0			;MANDA OP BIT A BIT PARA SR
;******************** PALAVRA ENVIADA *********************
	CALL 	COUNT_RESET

	CALL 	W_4MS				;ESPERA > 4 MS
	
	MOVLW	b'00110000'			;MANDA 0X30 PARA O LCD
	MOVWF	WRD
	
	CALL 	SEND_LCD0		
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET

	CALL 	W_100US					;ESPERA > 100 US 
	
	MOVLW	b'00110000'				;MANDA 0X30 PARA O LCD
	MOVWF	WRD
	
	CALL 	SEND_LCD0				;MANDA 0X30
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET
	
	CALL	W_40US					;ESPERA > 40 US
	
	MOVLW	B'00100000'					
	MOVWF	WRD
	
	CALL 	SEND_LCD0				;ESTABELECA COMUNICA��O EM 4 VIAS(00010)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET
	
	CALL 	W_40US					;ESPERA > 40 US
	
	MOVLW	B'00100000'					
	MOVWF	WRD
	
	CALL 	SEND_LCD0				;MANDA CONDI��ES DE OPERA��O (00010)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET
	
	MOVLW	B'1000000'					
	MOVWF	WRD
	
	CALL 	SEND_LCD0				;MANDA CONDI��ES DE OPERA��O (01000)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET
	
	CALL 	W_40US
									;ESPERA > 40 US
	MOVLW	B'00000000'					
	MOVWF	WRD						

	CALL 	SEND_LCD0				;LIMPA DISPLAY (00000)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET

	MOVLW	B'00010000'					
	MOVWF	WRD						

	CALL 	SEND_LCD0				;POSICIONA CURSOR (00001)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET

	CALL	W_1800US				;ESPERA > 1.8 MS

	MOVLW	B'00000000'					
	MOVWF	WRD						

	CALL 	SEND_LCD0				;LIMPA DISPLAY (00000)							
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET

	MOVLW	B'1100000'				
	MOVWF	WRD						

	CALL 	SEND_LCD0				;LIGA SEM CURSOR (01100)			
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET
	
	CALL 	W_40US					;ESPERA > 40 US
								;DESLOCAMENTO AUTOMATICO PARA A DIREITA
	MOVLW	B'00000000'					
	MOVWF	WRD						

	CALL 	SEND_LCD0				;LIMPA DISPLAY (00000)							;(00000) & (00110)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET

	MOVLW	B'01100000'
	MOVWF	WRD						

	CALL 	SEND_LCD0				;MODO OPERACIONAL 
;******************** PALAVRA ENVIADA *********************
	CALL 	W_40US					;ESPERA 40 US
	
	RETURN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 		CLOCK SHIFT REGISTER		     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;RESPONSAVEL POR MANDAR O DADO PARA O SHIFT REGISTER
;SEM ELE O DADO N�O � ENVIADO
SR_CLOCK

	BSF	SR_CLK
	BCF	SR_CLK

	RETURN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 		MANDAR P/ SR (RS = 0)		     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PARA COMANDOS OPERACIONAIS, O BIT RS DO LCD DEVE SER ZERO

SEND_LCD0						;MANDA INSTRU��ES (RS = 0


	RLF		WRD					;BIT NO SR VIA CARRY
								;(FALTA VER SE � BIG ENDIAN OU LITTLE ENDIAN)

	BTFSC	STATUS,C			;VERIFICA Q VALOR VAI SER MANDADO (0 OU 1)
								;PULA SE CARRY = 0
	GOTO	SR_SET				;MANDA 1 AO SR
	
	BCF		SR_DAT				;MANDA 0 AO SR
	CALL 	SR_CLOCK
	
CHECK_FINAL0
	DECFSZ	COUNT,1
	GOTO	SEND_LCD0
	
	GOTO 	FINAL_LCD0

SR_SET
	BSF		SR_DAT				;MANDA 1 AO SR
	CALL	SR_CLOCK

	GOTO 	CHECK_FINAL0			;VOLTA AO IN�CIO

FINAL_LCD0
	BCF		SR_DAT		; ENVIA RS = 0 (OPERA��O)
	CALL	SR_CLOCK	
	
	BSF		SR_DAT		; ENVIA BACKLIGHT = 1 (LUZ DE FUNDO)
	CALL	SR_CLOCK
	
	BCF		SR_DAT		;TESTE
	CALL	SR_CLOCK	; PREENCHE COM QUALQUER COISA (DON'T CARE)
	CALL	SR_CLOCK

	BSF		LCD_EN
	NOP					; PULSO DE LCD (CASO N�O PEGUE, TENTAR INVERTER ESSES VALORES)
	BCF		LCD_EN

	RETURN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 		MANDAR P/ SR (RS = 1)		     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PARA ENVIO DE DADOS (CARACTERES), O BIT RS DO LCD DEVE SER UM

SEND_LCD1						;MANDA INSTRU��ES (RS = 0

	
	RLF		WRD					;BIT NO SR VIA CARRY
								;(FALTA VER SE � BIG ENDIAN OU LITTLE ENDIAN)

	BTFSC	STATUS,C			;VERIFICA Q VALOR VAI SER MANDADO (0 OU 1)
								;PULA SE CARRY = 0
	GOTO	SR_SET1				;MANDA 1 AO SR
	
	BCF		SR_DAT				;MANDA 0 AO SR
	CALL 	SR_CLOCK

CHECK_FINAL1	
	DECFSZ	COUNT,1				;DECREMENTA
	
	GOTO	SEND_LCD1
	GOTO	FINAL_LCD1	

SR_SET1
	BSF		SR_DAT				;MANDA 0 AO SR
	CALL	SR_CLOCK

	GOTO 	CHECK_FINAL1			;VOLTA AO IN�CIO

FINAL_LCD1

	BSF		SR_DAT		; ENVIA RS = 1 (CARACTERE)
	CALL	SR_CLOCK	
	
	BSF		SR_DAT		; ENVIA BACKLIGHT = 1 (LUZ DE FUNDO)
	CALL	SR_CLOCK

	CALL	SR_CLOCK	; PREENCHE COM QUALQUER COISA (DON'T CARE)
	CALL	SR_CLOCK

	BSF		LCD_EN
	NOP					; PULSO DE LEITURA DO LCD
	BCF		LCD_EN			

	RETURN

DEC2ASCII
	MOVFW	AVG_ADH
	ADDLW	.48
	
	MOVWF	WRD					;VALOR ASCII EM DECIMAL	
	
	CALL 	COUNT_RESET			;NECESS�RIO MANDAR A MSG 2 VEZES AO LCD
	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
	CALL 	COUNT_RESET	
	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA

	RETURN	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 			DELAYS	                     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;TEMPOS MINIMOS DE DELAY, COMO � PRECISO OBEDECER APENAS AO TEMPO M�NIMO
;AS FUN��ES APRESENTAM VALORES MAIORES DO QUE OS NOMES DE SUAS SUBROTINAS
;FACILITA NA REUTILIZA��O DE SUBROTINAS
;EX.: DELAY 100 MS = 2 * 40 MS  (TEMPO REAL =  80 uS)
 
W_40US						;TEMPO REAL =  80 uS

	MOVLW	.254			;ATRIBUI O VALOR NO TMR0
	MOVWF	TMR0

W_40CHECK

	BTFSS	INTCON,T0IF		;VERIFICA SE CONTADOR ESTOUROU,SENAO,CONTINUA NO LOOP
	GOTO	W_40CHECK		
	CALL 	LIMPA_T0FLAG

	RETURN

W_100US						;TEMPO REAL = 165 uS
	
	CALL W_40US				
	CALL W_40US			
							

	RETURN

W_1800US					;TEMPO REAL = 1.875 mS
	MOVLW	.226			;ATRIBUI O VALOR NO TMR0
	MOVWF	TMR0

W_1800USCHECK				

	BTFSS	INTCON,T0IF		;VERIFICA SE CONTADOR ESTOUROU,SENAO,CONTINUA NO LOOP
	GOTO	W_1800USCHECK		
	CALL 	LIMPA_T0FLAG

	RETURN

W_4MS						;TEMPO REAL = 4.112 mS
	MOVLW	.191			;ATRIBUI O VALOR NO TMR0
	MOVWF	TMR0

W_4MSCHECK				

	BTFSS	INTCON,T0IF		;VERIFICA SE CONTADOR ESTOUROU,SENAO,CONTINUA NO LOOP
	GOTO	W_4MSCHECK		
	CALL 	LIMPA_T0FLAG
	RETURN

W_15MS						;TEMPO REAL = 16.452 mS
	CALL W_4MS
	CALL W_4MS
	CALL W_4MS
	CALL W_4MS
	
	RETURN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	B'00000100' ;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISIO		;GP2 = ENTRADA PARA GERAR ALTA IMPED�NCIA (AD)
	
	MOVLW	B'00010100'
	MOVWF	ANSEL 		;DEFINE GP2 COMO CONVERSOR AD E FREQUENCIA DE CAPTURA = FOSC/8

	MOVLW	B'00000101'
	MOVWF	OPTION_REG	;DEFINE OP��ES DE OPERA��O
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OP��ES DE INTERRUP��ES
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERA��O DO COMPARADOR ANAL�GICO

	MOVLW	B'00001001'
	MOVWF	ADCON0		; CONVERSOR AD

	CLRF	GPIO
	CALL 	SETUP
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZA��O DAS VARI�VEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN

	;LIMPEZA DOS REGISTRADORES

	CLRF TEMP_ADH
	CLRF TEMP_ADL

	CLRF AVG_ADH
	CLRF AVG_ADL

	MOVLW 	.32			;VALOR REAL (32)
	MOVWF	AVG_COUNT
	
	;INICIALIZA��O

AD	
	BSF ADCON0, 1			;INICIA CONVERS�O AD


FINAL_AD
	BTFSC	ADCON0,1		;VERIFICA SE A CONVERS�O ACABOU
	GOTO	FINAL_AD

	MOVFW	ADRESH			;CAPTURA O VALOR DE ADRESH
	ADDWF	TEMP_ADL		;SOMA NO MENOS SIGNIFICATIVO

	BTFSC	STATUS, C		;SE CARRY FOR ZERO ENTAO NAO HOUVE ESTOURO 
	INCF	TEMP_ADH		;SENAO, ENTAO INCREMENTA O TEMP_ADH				

	DECFSZ	AVG_COUNT		;CONTAGEM DE VALORES (32 MAX)
	GOTO	AD				;VOLTA PRO ESTAGIO DE CAPTURA
							
;----------------- TESTE 1 - SOMATORIO (OK!) -------------------------------
	
	MOVLW 	.5							;VALOR TENS�O M�XIMA
	MOVWF	AVG_COUNT

MEDIA						
	RRF		TEMP_ADH					;FIM DAS 32 CONTAGENS, HORA DE FAZER A MEDIA
	RRF		TEMP_ADL						
	
	BCF		STATUS,C					;GARANTIR Q O BIT MENOS SIGNIFICATIVO NAO INTERFIRA

	DECFSZ	AVG_COUNT					
	GOTO 	MEDIA
;-------------------- TESTE 2 - MEDIA(OK!) --------------------	
										;ACABOU A DIVISAO (MEDIA)
										;REGRA DE 3 PARA A TENS�O (MULTIPLICA POR 5)
	MOVFW	TEMP_ADL
	MOVWF	AVG_ADL						;MOVE O DADO PARA OUTRO REGISTRADOR

	MOVLW	.2
	MOVWF	AVG_COUNT

ROTATION_5
	RLF		AVG_ADL						;MULTIPLICA POR 2
	RLF		AVG_ADH		

	BCF		STATUS,C

	DECFSZ	AVG_COUNT
	GOTO	ROTATION_5

	MOVFW	TEMP_ADL
	ADDWF	AVG_ADL						;SOMA FINAL
	
	BTFSC	STATUS,C					;VERIFICA O CARRY
	INCF	AVG_ADH						;SE 1, SOMA AO MAIS SIGNIFICATIVO

;-------------------------- TESTE 3 - PRIMEIRO DIGITO SIGNIFICATIVO(OK! --------------


	;AQUI O AVG_ADH � O PRIMEIRO VALOR Q QUEREMOS ENT�O:
	;MANDA O VALOR EM AVG_ADH PARA O CONVERSOR ASCII E PRINTA NO LCD
	;PRINTA O . ANTES DE ACHAR O PROXIMO VALOR

	MOVFW	AVG_ADH
	CALL	DEC2ASCII
	
;PRINT "."
	MOVLW	'.'
	MOVWF	WRD
	
	CLRF	AVG_ADH
	
	CALL 	COUNT_RESET			;NECESS�RIO MANDAR A MSG 2 VEZES AO LCD
	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
	CALL 	COUNT_RESET	
	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA

;INICIALIZA��O PARA REGRA DE 3
	MOVFW	AVG_ADL
	MOVWF	TEMP_ADL
	
	MOVLW	.3
	MOVWF	AVG_COUNT

ROTATION_10	;(MULTIPLICA��O POR 8)
	RLF		AVG_ADL						;MULTIPLICA POR 2
	RLF		AVG_ADH		

	BCF		STATUS,C

	DECFSZ	AVG_COUNT
	GOTO	ROTATION_10

;PRIMEIRA SOMA

	MOVFW	TEMP_ADL
	ADDWF	AVG_ADL

	BTFSC	STATUS,C
	INCF	AVG_ADH

;SEGUNDA SOMA
	
	MOVFW	TEMP_ADL
	ADDWF	AVG_ADL

	BTFSC	STATUS,C
	INCF	AVG_ADH
	

;REGISTRADOR MAIS SIGNIFICATIVO VAI SER O SEGUNDO ELEMENTO (OK!)
	MOVFW	AVG_ADH
	CALL 	DEC2ASCII
;SE QUISER, PODE ADICIONAR MAIS UM DIGITO SIGNIFICATIVO (INTERESSANTE!)

;PRINT V ( VOLTS )
	
	MOVLW	'V'
	MOVWF	WRD
	
	CLRF	AVG_ADH
	
	CALL 	COUNT_RESET			;NECESS�RIO MANDAR A MSG 2 VEZES AO LCD
	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
	CALL 	COUNT_RESET	
	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA


;RESPONS�VEL POR MANDAR AS LETRAS A SEREM EXPOSTAS

;	MOVLW 	'H'					;GUARDA AS LETRAS NO REGISTRADOR
;	MOVWF	WRD	
	
;	CALL 	COUNT_RESET			;NECESS�RIO MANDAR A MSG 2 VEZES AO LCD
;	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
;	CALL	W_1800US
;	CALL 	COUNT_RESET	
;	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA
;	CALL	W_1800US


	;SE ROTACIONAR MAIS UMA VEZ VOLTA AO NUMERO INICIAL (DESNCESS�RIO [$])
;-------------------- ALGORITMO ---------------------

;1 - INICIALIZAR O LCD ( OK ) SUBFUNCAO - SETUP
;2 - INICIAR A CONVERSAO AD NA PORTA GP2
;3 - CADA CAPTURA DEVE SE SOMAR A UM REGISTRADOR
;	3.1 - A SOMA UTILIZA DOIS REGISTRADORES
;			SOMA ESSE VALOR AO REGISTRADOR
;			SE CARRY ATIVAR, SOMA-SE 1 AO OUTRO REGISTRADOR
;4 - TIRA-SE A MEDIA DOS VALORES SE DIVIDINDO POR 32
;	4.1 - 5 ROTA��ES PARA A DIREITA
;	4.2 - NECESSARIO REALIZAR REGRA DE 3 PARA TRANSFORMAR NOVAMENTE EM VOLTS
;			256 --------- 5 (DUAS ROTA��ES + UMA SOMA)
;			BIT  -------- ?
;			TAMBEM UTILIZA-SE DE DOIS REGISTRADORES
;			PARTE MAIS SIGNIFICATIVA INDICA O NUMERO ANTES DO PONTO (EX.: "2".0 V)
;	4.3 - NECESSARIO O VALOR COM UMA CASA DECIMAL DE PRECISAO
;			REALIZA-SE OUTRA REGRA DE 3
;			256 --------- 10 (TRES ROTA��ES + DUAS SOMAS COM SI MESMO)
;			BIT --------- ?
;			ASSIM O REGISTRADOR MAIS SIGNIFICATIVO INDICA O PROXIMO VALOR (EX.: 2."0" v)
;5 - REALIZA-SE A CONVERS�O BIN�RIO ASCII
;6 - PRINT LCD




;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
