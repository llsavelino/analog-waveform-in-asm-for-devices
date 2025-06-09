; Configuração de timers feito por IA, Créditos totais ao DeepSeek 🐋🐳

; Controle de potência usando PWM com valor de potenciômetro
; PWM de 10 bits no modo Fast PWM
; PWM no pino OC1A (PB1 / D9), entrada analógica no pino ADC0 (PC0 / A0)
; Microcontrolador: ATmega328P (Arduino UNO)

#include <avr/io.h>  
; Inclui definições como DDRB, PORTB, RAMEND, etc.

; Definições para facilitar leitura
.EQU LED_PIN, PB1     ; OC1A = PB1 = pino digital 9
.EQU POT_PIN, PC0     ; ADC0 = PC0 = pino analógico 0

.DATA
    microTime: .BYTE 0x0A

; --- Vetor de Reset ---
.ORG 0x0000
    RJMP main          ; Salta para o início do programa

; --- Vetor de Interrupção ADC (0x002A) ---
; (Comentado para manter o modo Polling como padrão)
.ORG 0x002A
    ; RJMP adc_isr     ; Descomente para usar interrupção
    RETI               ; Mantém como RETI se não usar interrupção

.SECTION .TEXT
.GLOBAL Main

; =============================================
; ** Rotina de Interrupção do ADC (opcional) **
; =============================================
adc_isr:

    NOP
    ; Salva registradores (obrigatório em ISRs)
    RCALL push_context


    ; Lê valor do ADC (10 bits)

    LDS r16, _SFR_MEM_ADDR(ADCL)
    LDS r17, _SFR_MEM_ADDR(ADCH)

    ; Atualiza PWM

    STS _SFR_MEM_ADDR(OCR1AL), r16
    STS _SFR_MEM_ADDR(OCR1AH), r17


    ; Restaura registradores
    RCALL pop_context
    NOP

    RETI   ; Retorna da interrupção

; --- Início do programa ---
Main:
    ; --- Inicialização da pilha ---
    RCALL stack_init

    ; --- Configura o pino OC1A como saída (PB1 / D9) ---
    RCALL hardware_init

    ; --- Configuração do ADC ---
    ; Referência = AVcc, entrada = ADC0 (PC0)
    LDI r16, (1 << REFS0)
    STS _SFR_MEM_ADDR(ADMUX), r16

    ; Habilita ADC com prescaler 128 (modo Polling)
    LDI r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    STS _SFR_MEM_ADDR(ADCSRA), r16

    ; --- Opção para habilitar interrupção (comentada) ---
    ; LDI r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0) | (1 << ADIE)
    ; STS _SFR_MEM_ADDR(ADCSRA), r16
    ; SEI  ; Habilita interrupções globais

    ; --- Configuração do Timer1 em Fast PWM 10 bits ---
    ; Modo Fast PWM, não-invertido em OC1A
    LDI r16, (1 << WGM11) | (1 << WGM10) | (1 << COM1A1)
    STS _SFR_MEM_ADDR(TCCR1A), r16
    LDI r16, (1 << WGM13) | (1 << WGM12) | (1 << CS10)
    STS _SFR_MEM_ADDR(TCCR1B), r16

    ; Inicia PWM em 0%
    CLR r16
    STS _SFR_MEM_ADDR(OCR1AL), r16
    STS _SFR_MEM_ADDR(OCR1AH), r16

; --- Loop principal (modo Polling) ---
main_loop:
    ; Inicia conversão ADC
    LDS r16, _SFR_MEM_ADDR(ADCSRA)
    ORI r16, (1 << ADSC)
    STS _SFR_MEM_ADDR(ADCSRA), r16

    ; Espera a conversão terminar (Polling)
    
    wait_adc:
        LDS r16, _SFR_MEM_ADDR(ADCSRA)
        SBRC r16, ADSC
        RJMP wait_adc

        ; Lê valor do ADC (10 bits)
        LDS r16, _SFR_MEM_ADDR(ADCL)
        LDS r17, _SFR_MEM_ADDR(ADCH)

        ; Atualiza PWM
        STS _SFR_MEM_ADDR(OCR1AL), r16
        STS _SFR_MEM_ADDR(OCR1AH), r17

        ; Pequeno atraso (opcional)
        LDS r18, microTime
    
    delay_loop:
        DEC r18
        BRNE delay_loop

        RJMP main_loop   ; Repete indefinidamente

stack_init:

    LDI r16, hi8(RAMEND)
    OUT _SFR_IO_ADDR(SPH), r16
    LDI r16, lo8(RAMEND)
    OUT _SFR_IO_ADDR(SPL), r16

    RET

hardware_init:

    SBI _SFR_IO_ADDR(DDRB), LED_PIN
    CBI _SFR_IO_ADDR(PORTB), LED_PIN  ; Garante início em LOW

    RET

; Label para salvar o contexto
push_context:
    PUSH    r0
    PUSH    r1
    PUSH    r2
    PUSH    r3
    PUSH    r4
    PUSH    r5
    PUSH    r6
    PUSH    r7
    PUSH    r8
    PUSH    r9
    PUSH    r10
    PUSH    r11
    PUSH    r12
    PUSH    r13
    PUSH    r14
    PUSH    r15
    PUSH    r16
    PUSH    r17
    PUSH    r18
    PUSH    r19
    PUSH    r20
    PUSH    r21
    PUSH    r22
    PUSH    r23
    PUSH    r24
    PUSH    r25
    PUSH    r26
    PUSH    r27
    PUSH    r28
    PUSH    r29
    PUSH    r30
    PUSH    r31
    IN      r16, _SFR_IO_ADDR(SREG)           ; Salva SREG
    PUSH    r16

    RET

; Label para restaurar o contexto
pop_context:
    POP     r16
    OUT     _SFR_IO_ADDR(SREG), r16           ; Restaura SREG
    POP     r31
    POP     r30
    POP     r29
    POP     r28
    POP     r27
    POP     r26
    POP     r25
    POP     r24
    POP     r23
    POP     r22
    POP     r21
    POP     r20
    POP     r19
    POP     r18
    POP     r17
    POP     r16
    POP     r15
    POP     r14
    POP     r13
    POP     r12
    POP     r11
    POP     r10
    POP     r9
    POP     r8
    POP     r7
    POP     r6
    POP     r5
    POP     r4
    POP     r3
    POP     r2
    POP     r1
    POP     r0

    RET
