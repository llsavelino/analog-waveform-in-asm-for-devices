; Feito grande parte com auxilo da IA, Créditos totais ao DeepSeek 🐋🐳

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
    ; Salva registradores (obrigatório em ISRs)
    PUSH r16
    PUSH r17
    IN r16, _SFR_IO_ADDR(SREG)
    PUSH r16

    ; Lê valor do ADC (10 bits)
    LDS r16, _SFR_MEM_ADDR(ADCL)
    LDS r17, _SFR_MEM_ADDR(ADCH)

    ; Atualiza PWM
    STS _SFR_MEM_ADDR(OCR1AL), r16
    STS _SFR_MEM_ADDR(OCR1AH), r17

    ; Restaura registradores
    POP r16
    OUT _SFR_IO_ADDR(SREG), r16
    POP r17
    POP r16

    RETI   ; Retorna da interrupção

; --- Início do programa ---
Main:
    ; --- Inicialização da pilha ---
    LDI r16, hi8(RAMEND)
    OUT _SFR_IO_ADDR(SPH), r16
    LDI r16, lo8(RAMEND)
    OUT _SFR_IO_ADDR(SPL), r16

    ; --- Configura o pino OC1A como saída (PB1 / D9) ---
    SBI _SFR_IO_ADDR(DDRB), LED_PIN
    CBI _SFR_IO_ADDR(PORTB), LED_PIN  ; Garante início em LOW

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
