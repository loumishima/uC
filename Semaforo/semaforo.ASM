;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*              MODIFICAÇÕES PARA USO COM 12F675                   *
;*                FEITAS PELO PROF. MARDSON                        *
;*                    FEVEREIRO DE 2016                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*					ATIVIDADE 1 - PARTE 3						   *
;*					LUIZ HENRIQUE RODRIGUES						   *
;*					SEMAFORO USANDO TMR0						   *
;*			OBJETIVO: CONTROLAR 2 SEMAFOROS	COM 5 PORTAS		   *
;*		     DELAY DE 2 S PARA SINAL VERDE E .5 PARA AMARELO       *
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

X;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
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
		AUX			;CONTADOR AUXILIAR

	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

PRE			EQU		B'00000111' 
PRE_T		EQU		B'00000001'	;TESTE PARA VISUALIZAÇÃO

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SAÍDAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO SAÍDA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;FAROIS DO SEMAFOROS

#DEFINE			SEM_G1		GPIO,0	;FAROL VERDE_1 & VERMELHO_2  (1 - ON / 0 - OFF)
#DEFINE			SEM_Y1		GPIO,1	;FAROL AMARELO 1(1- ON/ 0 - OFF)


#DEFINE			SEM_G2		GPIO,4	;FAROL VERDE_2 & VERMELHO_1  (1 - ON / 0 - OFF)
#DEFINE			SEM_Y2		GPIO,5	;FAROL AMARELO 2 (1- ON/ 0 - OFF)  

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

LIMPA_T0FLAG				;RESPONSAVEL POR REINICIAR A CONTAGEM APOS O ESTOURO
	
	
	BCF		INTCON,T0IF		;LIMPA A FLAG
	BCF		INTCON,T0IE		;DESABILITA AS INTERRUPÇÕES (PREUCAÇÃO)

	RETURN

SET_PRESCALER				;DEFINE O PADRÃO DE TEMPO DO TMR0
	
	BANK1					;MUDA O BANCO

	MOVLW	PRE				;DEFINE O PRESCALER
	MOVWF	OPTION_REG

	BANK0					;SEMPRE VOLTAR AO BANCO ANTERIOR
	
	RETURN
SET_LIGTHS					;DEFINE O ESTADO DO SEMÁFORO
	BSF SEM_G1				;LIGA O VERDE DO PRIMEIRO SEMAFORO
	
	BCF SEM_Y1				;DESLIGA O RESTO
	
	BCF SEM_G2

	BCF SEM_Y2
	
	RETURN
WAIT2SEC					;ESPERA 2 SEGUNDOS (SINAL VERDE)
	BTFSS	INTCON,T0IF		;VERIFICA SE CONTADOR ESTOUROU,SENAO,CONTINUA NO LOOP
	GOTO	WAIT2SEC		
	CALL 	LIMPA_T0FLAG

	MOVLW	.61				;REATRIBUI O VALOR NO TMR0
	MOVWF	TMR0	

	DECFSZ	AUX,F			;DECREMENTA AUX, SE ZERO PULA O LOOP
	GOTO	WAIT2SEC

	RETURN

WAITHALFS					;ESPERA .5 SEGUNDOS (SINAL AMARELO)
	BTFSS	INTCON,T0IF 	;VERIFICA SE CONTADOR ESTOUROU,SENAO,CONTINUA NO LOOP
	GOTO	WAITHALFS

	MOVLW	.61				;REATRIBUI O VALOR NO TMR0
	MOVWF	TMR0

	CALL	LIMPA_T0FLAG
	DECFSZ	AUX,F			;DECREMENTA AUX, SE ZERO PULA O LOOP
	GOTO	WAITHALFS
	
	RETURN

CHANGE_LIGHTS				;ALTERA O ESTADO DO SEMAFORO (DE SET_LIGHTS PARA CHANGE_LIGHTS E VICE - VERSA)
	BSF SEM_G2				;LIGA O VERDE DO SEGUNDO SEMAFORO
	
	BCF SEM_Y2				;DESLIGA O RESTO
	
	BCF SEM_G1

	BCF SEM_Y1
	
	RETURN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	B'00000000' ;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISIO		;COMO SAÍDAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O
	MOVLW	B'00000100'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO
	
	CLRF	GPIO		;LIMPANDO AS PORTAS!
	CALL	SET_LIGTHS	;SITUAÇÃO INICIAL DOS FARÓIS!
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN

	;CORPO DA ROTINA PRINCIPAL

	CALL 	LIMPA_T0FLAG	;LIMPA A FLAG DE ESTOURO (PREUCAÇÃO INICIAL)
	CALL 	SET_PRESCALER	;DEFINE O PRESCALER
	
	MOVLW 	.40				;CONTADOR PARA ATINGIR OS 2 SEG. (4 VEZES O DE 0.5S)[1]
	MOVWF	AUX
	
	MOVLW	.61				;CONTAGEM DE 61 A 255  NO TIMER[2]
	MOVWF	TMR0

	CALL 	WAIT2SEC
		

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            FIM CONTAGEM --> 2 SEC ---> SEMAFORO 1               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	BSF		SEM_Y1			;LIGA O SEMAFORO AMARELO[3]
	MOVLW	.10				
	MOVWF	AUX

	MOVLW	.61				;[2]
	MOVWF	TMR0
			
	CALL 	WAITHALFS


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            FIM CONTAGEM --> .5 SEC --> AMARELO 1                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	;FUNÇÃO DE TROCA DE COR DOS SEMAFOROS!
	CALL CHANGE_LIGHTS
	
	MOVLW 	.40				;[1]
	MOVWF	AUX
	
	MOVLW	.61				;[2]
	MOVWF	TMR0

	CALL 	WAIT2SEC

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            FIM CONTAGEM --> 2 SEC ---> SEMAFORO 2               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	BSF		SEM_Y2			;[3]
	MOVLW	.10				
	MOVWF	AUX

	MOVLW	.61				;[2]
	MOVWF	TMR0
			
	CALL 	WAITHALFS

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            FIM CONTAGEM --> .5 SEC --> AMARELO 2                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	CALL	SET_LIGTHS 		;VOLTA A FORMAÇÃO INICIAL DO PROJETO
	GOTO MAIN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
