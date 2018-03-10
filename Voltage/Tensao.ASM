;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*              MODIFICAÇÕES PARA USO COM 12F675                   *
;*                FEITAS PELO PROF. MARDSON                        *
;*                    FEVEREIRO DE 2016                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       NOME DO PROJETO                           *
;*                           CLIENTE                               *
;*         DESENVOLVIDO PELA MOSAICO ENGENHARIA E CONSULTORIA      *
;*   VERSÃO: 1.0                           DATA: 17/06/03          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   MODELO PARA O PIC 12F675                                      *
;*                                                                 *
;*                                                                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINIÇÕES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <P12F675.INC>	;ARQUIVO PADRÃO MICROCHIP PARA 12F675

	__CONFIG _BODEN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _MCLRE_ON & _INTRC_OSC_NOCLKOUT

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    PAGINAÇÃO DE MEMÓRIA                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;DEFINIÇÃO DE COMANDOS DE USUÁRIO PARA ALTERAÇÃO DA PÁGINA DE MEMÓRIA
#DEFINE	BANK0	BCF STATUS,RP0	;SETA BANK 0 DE MEMÓRIA
#DEFINE	BANK1	BSF STATUS,RP0	;SETA BANK 1 DE MAMÓRIA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARIÁVEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DOS NOMES E ENDEREÇOS DE TODAS AS VARIÁVEIS UTILIZADAS 
; PELO SISTEMA

	CBLOCK	0x20	;ENDEREÇO INICIAL DA MEMÓRIA DE
					;USUÁRIO
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES

		WRD			;USADO PARA O PRINT		
		COUNT		;USADO PARA A DIVISÃO EM 4 BIT
		;EXCLUSIVOS PARA O LCD
		
		TEMP_ADH
		TEMP_ADL

		;PARA A SOMA DAS LEITURAS

		AVG_ADH
		AVG_ADL
			
		;PARA A MEDIA DOS VALORES
		
		AVG_COUNT	

	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA
	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

#DEFINE		SR_CLK		GPIO,0
#DEFINE		SR_DAT		GPIO,4
#DEFINE		LCD_EN		GPIO,5	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SAÍDAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO SAÍDA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x00			;ENDEREÇO INICIAL DE PROCESSAMENTO
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    INÍCIO DA INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDEREÇO DE DESVIO DAS INTERRUPÇÕES. A PRIMEIRA TAREFA É SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERAÇÃO FUTURA

	ORG	0x04			;ENDEREÇO INICIAL DA INTERRUPÇÃO
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SERÁ ESCRITA AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUPÇÕES

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SAÍDA DA INTERRUPÇÃO                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUPÇÃO

SAI_INT
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	RETFIE

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.

LIMPA_T0FLAG

	BCF		INTCON,T0IF		;LIMPA A FLAG
	BCF		INTCON,T0IE		;DESABILITA AS INTERRUPÇÕES

	RETURN

COUNT_RESET					
	MOVLW 	.4
	MOVWF	COUNT

	RETURN
SETUP
	CALL 	COUNT_RESET			;QUANTIDADE DE ROTAÇÕES 

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
	
	CALL 	SEND_LCD0				;ESTABELECA COMUNICAÇÃO EM 4 VIAS(00010)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET
	
	CALL 	W_40US					;ESPERA > 40 US
	
	MOVLW	B'00100000'					
	MOVWF	WRD
	
	CALL 	SEND_LCD0				;MANDA CONDIÇÕES DE OPERAÇÃO (00010)
;******************** PALAVRA ENVIADA *********************
	CALL COUNT_RESET
	
	MOVLW	B'1000000'					
	MOVWF	WRD
	
	CALL 	SEND_LCD0				;MANDA CONDIÇÕES DE OPERAÇÃO (01000)
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
;SEM ELE O DADO NÃO É ENVIADO
SR_CLOCK

	BSF	SR_CLK
	BCF	SR_CLK

	RETURN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 		MANDAR P/ SR (RS = 0)		     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PARA COMANDOS OPERACIONAIS, O BIT RS DO LCD DEVE SER ZERO

SEND_LCD0						;MANDA INSTRUÇÕES (RS = 0


	RLF		WRD					;BIT NO SR VIA CARRY
								;(FALTA VER SE É BIG ENDIAN OU LITTLE ENDIAN)

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

	GOTO 	CHECK_FINAL0			;VOLTA AO INÍCIO

FINAL_LCD0
	BCF		SR_DAT		; ENVIA RS = 0 (OPERAÇÃO)
	CALL	SR_CLOCK	
	
	BSF		SR_DAT		; ENVIA BACKLIGHT = 1 (LUZ DE FUNDO)
	CALL	SR_CLOCK
	
	BCF		SR_DAT		;TESTE
	CALL	SR_CLOCK	; PREENCHE COM QUALQUER COISA (DON'T CARE)
	CALL	SR_CLOCK

	BSF		LCD_EN
	NOP					; PULSO DE LCD (CASO NÃO PEGUE, TENTAR INVERTER ESSES VALORES)
	BCF		LCD_EN

	RETURN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 		MANDAR P/ SR (RS = 1)		     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;PARA ENVIO DE DADOS (CARACTERES), O BIT RS DO LCD DEVE SER UM

SEND_LCD1						;MANDA INSTRUÇÕES (RS = 0

	
	RLF		WRD					;BIT NO SR VIA CARRY
								;(FALTA VER SE É BIG ENDIAN OU LITTLE ENDIAN)

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

	GOTO 	CHECK_FINAL1			;VOLTA AO INÍCIO

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
	
	CALL 	COUNT_RESET			;NECESSÁRIO MANDAR A MSG 2 VEZES AO LCD
	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
	CALL 	COUNT_RESET	
	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA

	RETURN	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 			DELAYS	                     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;TEMPOS MINIMOS DE DELAY, COMO É PRECISO OBEDECER APENAS AO TEMPO MÍNIMO
;AS FUNÇÕES APRESENTAM VALORES MAIORES DO QUE OS NOMES DE SUAS SUBROTINAS
;FACILITA NA REUTILIZAÇÃO DE SUBROTINAS
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
	MOVWF	TRISIO		;GP2 = ENTRADA PARA GERAR ALTA IMPEDÂNCIA (AD)
	
	MOVLW	B'00010100'
	MOVWF	ANSEL 		;DEFINE GP2 COMO CONVERSOR AD E FREQUENCIA DE CAPTURA = FOSC/8

	MOVLW	B'00000101'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO

	MOVLW	B'00001001'
	MOVWF	ADCON0		; CONVERSOR AD

	CLRF	GPIO
	CALL 	SETUP
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
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
	
	;INICIALIZAÇÃO

AD	
	BSF ADCON0, 1			;INICIA CONVERSÃO AD


FINAL_AD
	BTFSC	ADCON0,1		;VERIFICA SE A CONVERSÃO ACABOU
	GOTO	FINAL_AD

	MOVFW	ADRESH			;CAPTURA O VALOR DE ADRESH
	ADDWF	TEMP_ADL		;SOMA NO MENOS SIGNIFICATIVO

	BTFSC	STATUS, C		;SE CARRY FOR ZERO ENTAO NAO HOUVE ESTOURO 
	INCF	TEMP_ADH		;SENAO, ENTAO INCREMENTA O TEMP_ADH				

	DECFSZ	AVG_COUNT		;CONTAGEM DE VALORES (32 MAX)
	GOTO	AD				;VOLTA PRO ESTAGIO DE CAPTURA
							
;----------------- TESTE 1 - SOMATORIO (OK!) -------------------------------
	
	MOVLW 	.5							;VALOR TENSÃO MÁXIMA
	MOVWF	AVG_COUNT

MEDIA						
	RRF		TEMP_ADH					;FIM DAS 32 CONTAGENS, HORA DE FAZER A MEDIA
	RRF		TEMP_ADL						
	
	BCF		STATUS,C					;GARANTIR Q O BIT MENOS SIGNIFICATIVO NAO INTERFIRA

	DECFSZ	AVG_COUNT					
	GOTO 	MEDIA
;-------------------- TESTE 2 - MEDIA(OK!) --------------------	
										;ACABOU A DIVISAO (MEDIA)
										;REGRA DE 3 PARA A TENSÃO (MULTIPLICA POR 5)
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


	;AQUI O AVG_ADH É O PRIMEIRO VALOR Q QUEREMOS ENTÃO:
	;MANDA O VALOR EM AVG_ADH PARA O CONVERSOR ASCII E PRINTA NO LCD
	;PRINTA O . ANTES DE ACHAR O PROXIMO VALOR

	MOVFW	AVG_ADH
	CALL	DEC2ASCII
	
;PRINT "."
	MOVLW	'.'
	MOVWF	WRD
	
	CLRF	AVG_ADH
	
	CALL 	COUNT_RESET			;NECESSÁRIO MANDAR A MSG 2 VEZES AO LCD
	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
	CALL 	COUNT_RESET	
	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA

;INICIALIZAÇÃO PARA REGRA DE 3
	MOVFW	AVG_ADL
	MOVWF	TEMP_ADL
	
	MOVLW	.3
	MOVWF	AVG_COUNT

ROTATION_10	;(MULTIPLICAÇÃO POR 8)
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
	
	CALL 	COUNT_RESET			;NECESSÁRIO MANDAR A MSG 2 VEZES AO LCD
	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
	CALL 	COUNT_RESET	
	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA


;RESPONSÁVEL POR MANDAR AS LETRAS A SEREM EXPOSTAS

;	MOVLW 	'H'					;GUARDA AS LETRAS NO REGISTRADOR
;	MOVWF	WRD	
	
;	CALL 	COUNT_RESET			;NECESSÁRIO MANDAR A MSG 2 VEZES AO LCD
;	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
;	CALL	W_1800US
;	CALL 	COUNT_RESET	
;	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA
;	CALL	W_1800US


	;SE ROTACIONAR MAIS UMA VEZ VOLTA AO NUMERO INICIAL (DESNCESSÁRIO [$])
;-------------------- ALGORITMO ---------------------

;1 - INICIALIZAR O LCD ( OK ) SUBFUNCAO - SETUP
;2 - INICIAR A CONVERSAO AD NA PORTA GP2
;3 - CADA CAPTURA DEVE SE SOMAR A UM REGISTRADOR
;	3.1 - A SOMA UTILIZA DOIS REGISTRADORES
;			SOMA ESSE VALOR AO REGISTRADOR
;			SE CARRY ATIVAR, SOMA-SE 1 AO OUTRO REGISTRADOR
;4 - TIRA-SE A MEDIA DOS VALORES SE DIVIDINDO POR 32
;	4.1 - 5 ROTAÇÕES PARA A DIREITA
;	4.2 - NECESSARIO REALIZAR REGRA DE 3 PARA TRANSFORMAR NOVAMENTE EM VOLTS
;			256 --------- 5 (DUAS ROTAÇÕES + UMA SOMA)
;			BIT  -------- ?
;			TAMBEM UTILIZA-SE DE DOIS REGISTRADORES
;			PARTE MAIS SIGNIFICATIVA INDICA O NUMERO ANTES DO PONTO (EX.: "2".0 V)
;	4.3 - NECESSARIO O VALOR COM UMA CASA DECIMAL DE PRECISAO
;			REALIZA-SE OUTRA REGRA DE 3
;			256 --------- 10 (TRES ROTAÇÕES + DUAS SOMAS COM SI MESMO)
;			BIT --------- ?
;			ASSIM O REGISTRADOR MAIS SIGNIFICATIVO INDICA O PROXIMO VALOR (EX.: 2."0" v)
;5 - REALIZA-SE A CONVERSÃO BINÁRIO ASCII
;6 - PRINT LCD




;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
