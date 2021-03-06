;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*              MODIFICA��ES PARA USO COM 12F675                   *
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
;*   VERS�O: 1.0                           DATA: 17/06/03          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRI��O DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   MODELO PARA O PIC 12F675                                      *
;*                                                                 *
;*                                                                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

X;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
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
		AUX			;CONTADOR AUXILIAR

	ENDC			;FIM DO BLOCO DE MEM�RIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

PRE			EQU		B'00000111' 
PRE_T		EQU		B'00000001'	;TESTE PARA VISUALIZA��O

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS PINOS QUE SER�O UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMB�M COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SA�DAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINI��O DE TODOS OS PINOS QUE SER�O UTILIZADOS COMO SA�DA
; RECOMENDAMOS TAMB�M COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;FAROIS DO SEMAFOROS

#DEFINE			SEM_G1		GPIO,0	;FAROL VERDE_1 & VERMELHO_2  (1 - ON / 0 - OFF)
#DEFINE			SEM_Y1		GPIO,1	;FAROL AMARELO 1(1- ON/ 0 - OFF)


#DEFINE			SEM_G2		GPIO,4	;FAROL VERDE_2 & VERMELHO_1  (1 - ON / 0 - OFF)
#DEFINE			SEM_Y2		GPIO,5	;FAROL AMARELO 2 (1- ON/ 0 - OFF)  

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
;*	            	 ROTINAS E SUBROTINAS                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRI��O DE FUNCIONAMENTO
; E UM NOME COERENTE �S SUAS FUN��ES.

LIMPA_T0FLAG				;RESPONSAVEL POR REINICIAR A CONTAGEM APOS O ESTOURO
	
	
	BCF		INTCON,T0IF		;LIMPA A FLAG
	BCF		INTCON,T0IE		;DESABILITA AS INTERRUP��ES (PREUCA��O)

	RETURN

SET_PRESCALER				;DEFINE O PADR�O DE TEMPO DO TMR0
	
	BANK1					;MUDA O BANCO

	MOVLW	PRE				;DEFINE O PRESCALER
	MOVWF	OPTION_REG

	BANK0					;SEMPRE VOLTAR AO BANCO ANTERIOR
	
	RETURN
SET_LIGTHS					;DEFINE O ESTADO DO SEM�FORO
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
	MOVWF	TRISIO		;COMO SA�DAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O
	MOVLW	B'00000100'
	MOVWF	OPTION_REG	;DEFINE OP��ES DE OPERA��O
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OP��ES DE INTERRUP��ES
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERA��O DO COMPARADOR ANAL�GICO
	
	CLRF	GPIO		;LIMPANDO AS PORTAS!
	CALL	SET_LIGTHS	;SITUA��O INICIAL DOS FAR�IS!
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZA��O DAS VARI�VEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN

	;CORPO DA ROTINA PRINCIPAL

	CALL 	LIMPA_T0FLAG	;LIMPA A FLAG DE ESTOURO (PREUCA��O INICIAL)
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
	;FUN��O DE TROCA DE COR DOS SEMAFOROS!
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
	CALL	SET_LIGTHS 		;VOLTA A FORMA��O INICIAL DO PROJETO
	GOTO MAIN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
