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

		;NOVAS VARIÁVEIS

		CONTADOR 	;VARIAVEL Q RECEBE AS FREQUENCIAS (ATRIBUIÇÃO NO TMR0)

	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

; VALORES PARA OS CONTADORES PARA O TMR0
FREQ1			EQU			.16			;CONTAR A 239
FREQ2			EQU			.76			;CONTAR A 179
FREQ3			EQU			.113		;CONTAR A 142
FREQ4			EQU			.135		;CONTAR A 120

; VALOR DO OPTION_REG COM O PRESCALER 1:16
_PRE			EQU			B'00000011'

; VALOR DO INTCON PARA AS INTERRUPÇOES DO GPIO
_INTERRUPCAO	EQU			B'10101000'

; VALOR PARA OS IOC NA GPIO
_INTPORTAS		EQU			B'00000111'

; VALOR PARA O TRISIO
_INOUT			EQU			B'00001111'


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

; BOTÕES QUE DEFINIRÃO O COMPORTAMENTO DA SAIDA
#DEFINE			BOTAO_0		GPIO,0		;0 --> OFF | 1 --> ON (DEPENDE DOS OUTROS BOTOES)
#DEFINE			BOTAO_1		GPIO,1		;0 --> FREQ 1 OR FREQ 2 | 1 --> FREQ3 OR FREQ 4  
#DEFINE			BOTAO_2		GPIO,2		;0 --> FREQ 1 OR FREQ 3 | 1 --> FREQ2 OR FREQ 4  

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SAÍDAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO SAÍDA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

#DEFINE			SAIDA		GPIO,4		;0 --> SINAL BAIXO |1 --> SINAL ALTO

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

	BTFSC 	INTCON,T0IF			;TIMER ESTOUROU? SE NÃO, FOI UM BOTÃO!
	GOTO	RESET_TIMER			;MUDA O FORMATO DE ONDA E REINICIA TMR0

	BCF		INTCON,GPIF			;LIMPA A FLAG DE APERTO DE BOTÃO

	BTFSS	BOTAO_0				;SE O BOTAO 0 ESTIVER DESATIVADO, NÃO IMPORTA GP1 NEM GP2
	GOTO	POWER_OFF
; ATÉ AQUI O COMANDO DO SINAL ESTÁ 1 - ? - ?

	BTFSS	BOTAO_1				;VERIFICA SE O BOTÃO 1 ESTÁ ATIVADO ( 1 - 1 )
	GOTO	B1_DESATIVADO		;SE PORTA_1 FOR ZERO, ENTÃO HÁ AS OPÇOES:
								;FREQUENCIA 1 OU FREQUENCIA 2

; ATÉ AQUI O COMANDO DO SINAL ESTÁ 1 - 1 - ?

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


;AS ROTINAS DE ATRIBUIÇÃO DE FREQUENCIA NÃO PODEM TER RETURN,
;SENÃO AO ATRIBUIR UMA FREQUENCIA, ASSIM QUE OCORRER A VOLTA AO CODIGO PODE OCORRER
;DE ATRIBUIR OUTRA FREQUENCIA EM SEGUIDA
 
ON_FREQ1					;PRIMEIRA ATRIBUIÇÃO AO TIMER0

	MOVLW	FREQ1			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	

ON_FREQ2					;PRIMEIRA ATRIBUIÇÃO AO TIMER0

	MOVLW	FREQ2			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	

ON_FREQ3					;PRIMEIRA ATRIBUIÇÃO AO TIMER0

	MOVLW	FREQ3			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	

ON_FREQ4					;PRIMEIRA ATRIBUIÇÃO AO TIMER0

	MOVLW	FREQ4			
	MOVWF	CONTADOR		;VALOR QUE VAI PARA O TMR0
	
	GOTO 	RESET_TIMER
	


RESET_TIMER

	BTFSS	BOTAO_0
	GOTO	POWER_OFF

	MOVFW	CONTADOR		;POR PREUCAÇÃO, AO INVES DE MANDAR DO WORK DIRETO P/ O TMR0
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
;*	            	 ROTINAS E SUBROTINAS                     	   *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	_INOUT		;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)(4 ENTRADAS & 2 SAIDAS)
	MOVWF	TRISIO		;COMO SAÍDAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O

	MOVLW	_PRE
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	
	MOVLW	_INTERRUPCAO
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES

	MOVLW	_INTPORTAS	;DEFINE QUAIS PORTAS GERAM INTERRUPÇÕES
	MOVWF	IOC

	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO

	MOVLW	B'00000000'
	MOVWF	GPIO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
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
