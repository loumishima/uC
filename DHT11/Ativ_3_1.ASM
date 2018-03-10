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

		CONTADOR	;CONTADOR DOS 40 BITS DO DHT11
		CONT_ASCII
		
		UM_INT		;PARTE INTEIRA DA UMIDADE
		UM_DEC		;PARTE DECIMAL DA UMIDADE
		TEMPER_INT	;PARTE INTEIRA DA TEMPERATURA
		TEMPER_DEC	;PARTE DECIMAL DA TEMPERATURA
		CHECKSUM	;
		
		
		;NOVAS VARIÁVEIS

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
;*	            	 ROTINAS E SUBROTINAS                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.

SUBROTINA1

	;CORPO DA ROTINA

	RETURN
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


DHT11
	;CARRY ESTÁ EM 1 OU ZERO E ESSE VALOR SERÁ REPASSADO AOS DEMAIS REGISTRADORES
	RLF	CHECKSUM	;CHECKSUM
	RLF	TEMPER_DEC	;PARTE DECIMAL DA TEMPERATURA
	RLF	TEMPER_INT	;PARTE INTEIRA DA TEMPERATURA
	RLF	UM_DEC		;PARTE DECIMAL DA UMIDADE
	RLF UM_INT		;PARTE INTEIRA DA UMIDADE


	RETURN
TRANSFORM_ASCII

;--------------------- PARTE NOME ----------------------------------
	MOVLW	'H'
	CALL 	PRINT_RESULT
	
	MOVLW	'E'
	CALL 	PRINT_RESULT
	
	MOVLW	'N'
	CALL 	PRINT_RESULT
	
	MOVLW	'R'
	CALL 	PRINT_RESULT
	
	MOVLW	'I'
	CALL 	PRINT_RESULT
	
	MOVLW	'Q'
	CALL 	PRINT_RESULT
	
	MOVLW	'U'
	CALL 	PRINT_RESULT
	
	MOVLW	'E'
	CALL 	PRINT_RESULT
	
	MOVLW	'H' ;QUEBRA DE LINHA
	CALL 	PRINT_RESULT
	
	MOVLW	'T'
	CALL 	PRINT_RESULT
	
	MOVLW	'E'
	CALL 	PRINT_RESULT
	
	MOVLW	'M'
	CALL 	PRINT_RESULT
	
	MOVLW	'P'
	CALL 	PRINT_RESULT
	
	MOVLW	'='
	CALL 	PRINT_RESULT
	
	CLRF 	CONT_ASCII	

;--------------------- PARTE TEMPERATURA ----------------------------
SUBTRACT_T	
	MOVLW 	.10
	SUBWF 	TEMPER_INT
	BTFSC	STATUS,C ;SE O CARRY FOR 1 ENTÃO O NUMERO DE CONTAGENS ATINGIU O LIMITE
	GOTO 	SUBTRACT_PT; SENÃO CONTINUA SUBTRAINDO ATÉ UM RESULTADO NEGATIVO
	
	MOVLW	.48
	ADDWF	CONT_ASCII ;GERA O VALOR EM ASCII

	MOVFW	CONT_ASCII
	CALL 	PRINT_RESULT	;ENVIA PARA O LCD
	
	MOVLW	.10
	ADDWF	UM_INT	;PARA GERAR O SEGUNDO DÍGITO
	MOVLW	.48
	ADDWF	UM_INT	;VALOR EM ASCII

	MOVFW	UM_INT
	CALL	PRINT_RESULT ;ENVIA PARA O LCD
;--------------------------------------------------------------------
	
	MOVLW 'C'
	CALL	PRINT_RESULT

	MOVLW ' '
	CALL	PRINT_RESULT

	MOVLW 'U'
	CALL	PRINT_RESULT

	MOVLW 'R'
	CALL	PRINT_RESULT
	
	MOVLW '='
	CALL	PRINT_RESULT
	
	CLRF 	CONT_ASCII

; -------------------- PARTE UMIDADE -------------------------------

SUBTRACT_U	
	MOVLW 	.10
	SUBWF 	UM_INT
	BTFSC	STATUS,C ;SE O CARRY FOR 1 ENTÃO O NUMERO DE CONTAGENS ATINGIU O LIMITE
	GOTO	SUBTRACT_PU; SENÃO CONTINUA SUBTRAINDO ATÉ UM RESULTADO NEGATIVO
	
	MOVLW	.48
	ADDWF	CONT_ASCII ;GERA O VALOR EM ASCII

	MOVFW	CONT_ASCII
	CALL 	PRINT_RESULT	;ENVIA PARA O LCD
	
	MOVLW	.10
	ADDWF	UM_INT	;PARA GERAR O SEGUNDO DÍGITO
	MOVLW	.48
	ADDWF	UM_INT	;VALOR EM ASCII

	MOVFW	UM_INT
	CALL	PRINT_RESULT ;ENVIA PARA O LCD
;--------------------------------------------------------------------

	MOVLW 	'%'
	CALL	PRINT_RESULT

	RETURN

SUBTRACT_PU
	INCF	CONT_ASCII
	GOTO	SUBTRACT_U
SUBTRACT_PT
	INCF	CONT_ASCII
	GOTO	SUBTRACT_T

PRINT_RESULT
	MOVWF	WRD
	CALL 	COUNT_RESET			;NECESSÁRIO MANDAR A MSG 2 VEZES AO LCD
	CALL	SEND_LCD1			;1 - PARTE MAIS SIGNIFICATIVA
	CALL	W_1800US
	CALL 	COUNT_RESET
	CALL 	SEND_LCD1			;2 - PARTE MENOS SIGNIFICATIVA
	CALL	W_1800US

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
	MOVLW	B'00000000' ;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISIO		;COMO SAÍDAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O
	MOVLW	B'00000101'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO (TMR0 COM PSA DE 1:2)
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES (SEM INTERRUPÇAO NA GP2)

	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO
	BSF		GPIO,GP2
	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN

	MOVLW	.40
	MOVWF	CONTADOR	;CONTADOR DE BITS

	BANK1				
	MOVLW	B'00000000' ;MODO INICIAL DE ENVIO AO DHT11
	MOVWF	TRISIO		
	BANK0

	BCF 	GPIO,GP2		;GERA A DESCIDA 

	CALL W_15MS				;ESPERA 19MS
	CALL W_4MS
	
	BSF		GPIO,GP2		;ATIVA PARA ESPERAR A RESPOSTA DO DHT11
	
	BANK1
	MOVLW 	B'00000100' 	;MUDA PARA ESPERAR A RESPOSTA DO DHT11
	MOVWF	TRISIO
	BANK0  

;ESPERA 18 MILLISEGUNDOS
;RESPOSTA EM ATE 40 MICROSSEGUNDOS
;80 MICROSSEGUNDOS EM BAIXO E ALTO (2 VEZES)

TEST_RESPONSE
	BTFSC	GPIO,GP2
	GOTO	TEST_RESPONSE 
	
	CALL W_40US
	CALL W_40US			;ESPERA OS 80 uS EM BAIXO

	CALL W_40US
	CALL W_40US			;ESPERA OS 80 uS EM ALTO

	CALL W_40US			;ESPERA OS 50uS EM BAIXO



	;AGORA VEM A PARTE DE VERIFICIAR OS TEMPOS!
CONTAGEM_BITS

;-------------------- PSA MODIFICADO ------------------
	BANK1
	MOVLW 	B'00000000' ;PSA (1:2)
	MOVWF	OPTION_REG
	BANK0

	MOVLW 	B'00000000' ;CONTAGEM COMEÇANDO EM ZERO
	MOVWF	TMR0

;-------------------------------------------------------

WAIT_TMR0
	BTFSC	GPIO,GP2	;ENQUANTO O SINAL NAO DESCER, ESPERE 
	GOTO WAIT_TMR0

	;APÓS A DESCIDA
	MOVLW	.20
	SUBWF	TMR0		;ALTERA O CARRY PARA ZERO OU 1
	CALL	DHT11	;SE 1, ENTÃO O TEMPO FOI MENOR DO QUE 40 US (MARGEM DE ERRO), LOGO 0

;------------------- PSA ORIGINAL --------------------------
	BANK1
	MOVLW	B'00000101'
	MOVWF	OPTION_REG	;MUDA PARA O VALOR INICIAL
	BANK0

	CALL W_40US
;-----------------------------------------------------------
	DECFSZ	CONTADOR
	GOTO 	CONTAGEM_BITS	;REPETE 40 VEZES PARA CADA BIT
	
	CALL	TRANSFORM_ASCII


	GOTO MAIN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
