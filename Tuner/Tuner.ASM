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

		;NOVAS VARI�VEIS

		CONTADOR 	;VARIAVEL Q RECEBE AS FREQUENCIAS (ATRIBUI��O NO TMR0)

	ENDC			;FIM DO BLOCO DE MEM�RIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

; VALORES PARA OS CONTADORES PARA O TMR0
FREQ1			EQU			.16			;CONTAR A 239
FREQ2			EQU			.76			;CONTAR A 179
FREQ3			EQU			.113		;CONTAR A 142
FREQ4			EQU			.135		;CONTAR A 120

; VALOR DO OPTION_REG COM O PRESCALER 1:16
_PRE			EQU			B'00000011'

; VALOR DO INTCON PARA AS INTERRUP�OES DO GPIO
_INTERRUPCAO	EQU			B'10101000'

; VALOR PARA OS IOC NA GPIO
_INTPORTAS		EQU			B'00000111'

; VALOR PARA O TRISIO
_INOUT			EQU			B'00001111'


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS PINOS QUE SER�O UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMB�M COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

; BOT�ES QUE DEFINIR�O O COMPORTAMENTO DA SAIDA
#DEFINE			BOTAO_0		GPIO,0		;0 --> OFF | 1 --> ON (DEPENDE DOS OUTROS BOTOES)
#DEFINE			BOTAO_1		GPIO,1		;0 --> FREQ 1 OR FREQ 2 | 1 --> FREQ3 OR FREQ 4  
#DEFINE			BOTAO_2		GPIO,2		;0 --> FREQ 1 OR FREQ 3 | 1 --> FREQ2 OR FREQ 4  

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SA�DAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS PINOS QUE SER�O UTILIZADOS COMO SA�DA
; RECOMENDAMOS TAMB�M COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

#DEFINE			SAIDA		GPIO,4		;0 --> SINAL BAIXO |1 --> SINAL ALTO

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

	BTFSC 	INTCON,T0IF			;TIMER ESTOUROU? SE N�O, FOI UM BOT�O!
	GOTO	RESET_TIMER			;MUDA O FORMATO DE ONDA E REINICIA TMR0

	BCF		INTCON,GPIF			;LIMPA A FLAG DE APERTO DE BOT�O

	BTFSS	BOTAO_0				;SE O BOTAO 0 ESTIVER DESATIVADO, N�O IMPORTA GP1 NEM GP2
	GOTO	POWER_OFF
; AT� AQUI O COMANDO DO SINAL EST� 1 - ? - ?

	BTFSS	BOTAO_1				;VERIFICA SE O BOT�O 1 EST� ATIVADO ( 1 - 1 )
	GOTO	B1_DESATIVADO		;SE PORTA_1 FOR ZERO, ENT�O H� AS OP�OES:
								;FREQUENCIA 1 OU FREQUENCIA 2

; AT� AQUI O COMANDO DO SINAL EST� 1 - 1 - ?

	BTFSS	BOTAO_2				
	GOTO	ON_FREQ3				; COMANDO --> 1 - 1 - 0 ---> FREQUENCIA 4
	
	GOTO 	ON_FREQ4				; COMANDO --> 1 - 1 - 1 -->  FREQUENCIA 3
	
POWER_OFF
	
	BCF		SAIDA
	BCF		INTCON,T0IF		; LIMPA FLAG DE ESTOURO
	GOTO 	SAI_INT
 
B1_DESATIVADO

	BTFSS	BOTAO_2
	GOTO	ON_FREQ1		; COMANDO 1 - 0 - 0

	GOTO	ON_FREQ2		; COMANDO 1 - 0 - 1


;AS ROTINAS DE ATRIBUI��O DE FREQUENCIA N�O PODEM TER RETURN,
;SEN�O AO ATRIBUIR UMA FREQUENCIA, ASSIM QUE OCORRER A VOLTA AO CODIGO PODE OCORRER
;DE ATRIBUIR OUTRA FREQUENCIA EM SEGUIDA
 
ON_FREQ1					;PRIMEIRA ATRIBUI��O AO TIMER0

	MOVLW	FREQ1			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	

ON_FREQ2					;PRIMEIRA ATRIBUI��O AO TIMER0

	MOVLW	FREQ2			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	

ON_FREQ3					;PRIMEIRA ATRIBUI��O AO TIMER0

	MOVLW	FREQ3			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	

ON_FREQ4					;PRIMEIRA ATRIBUI��O AO TIMER0

	MOVLW	FREQ4			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	


RESET_TIMER

	BTFSS	BOTAO_0
	GOTO	POWER_OFF

	MOVFW	CONTADOR		;POR PREUCA��O, AO INVES DE MANDAR DO WORK DIRETO P/ O TMR0
	MOVWF	TMR0			;CONTADOR SEMPRE VAI GUARDAR O VALOR DA ULTIMA FREQUENCIA
	
	BCF		INTCON,T0IF		;CASO TIMER TENHA ESTOURADO
	
	;INVERTE VALOR DA SAIDA ATUALMENTE
	BTFSC	SAIDA
	GOTO	S_OFF

	BSF		SAIDA

	GOTO	SAI_INT

S_OFF
	BCF		SAIDA

	GOTO	SAI_INT	
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
;*	            	 ROTINAS E SUBROTINAS                     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRI��O DE FUNCIONAMENTO
; E UM NOME COERENTE �S SUAS FUN��ES.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	_INOUT		;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)(4 ENTRADAS & 2 SAIDAS)
	MOVWF	TRISIO		;COMO SA�DAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O

	MOVLW	_PRE
	MOVWF	OPTION_REG	;DEFINE OP��ES DE OPERA��O
	
	MOVLW	_INTERRUPCAO
	MOVWF	INTCON		;DEFINE OP��ES DE INTERRUP��ES

	MOVLW	_INTPORTAS	;DEFINE QUAIS PORTAS GERAM INTERRUP��ES
	MOVWF	IOC

	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERA��O DO COMPARADOR ANAL�GICO

	MOVLW	B'00000000'
	MOVWF	GPIO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZA��O DAS VARI�VEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN

	;CORPO DA ROTINA PRINCIPAL

	GOTO MAIN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
