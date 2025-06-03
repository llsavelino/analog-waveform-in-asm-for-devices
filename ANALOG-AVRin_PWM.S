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

; Vetor de interrupção ADC (não utilizado aqui) <- feito por IA
.ORG 0x002A
    RETI

.SECTION .TEXT
.GLOBAL Main

; --- Início do programa ---
Main:
    ; --- Inicialização da pilha ---
    ; A pilha é usada em chamadas de função, interrupções, etc.
    ; Começamos ela no topo da RAM (RAMEND)
    LDI r16, hi8(RAMEND)
    OUT _SFR_IO_ADDR(SPH), r16    ; SPH = Stack Pointer High
    LDI r16, lo8(RAMEND)
    OUT _SFR_IO_ADDR(SPL), r16    ; SPL = Stack Pointer Low

    ; --- Configura o pino OC1A como saída (PB1 / D9) ---
    SBI _SFR_IO_ADDR(DDRB), LED_PIN
    ; --- Limpa o pino (PB1 / D9) ---
    IN r17, _SFR_IO_ADDR(PINB)
    SBRS r17, 0x01
    CBI _SFR_IO_ADDR(PORTB), LED_PIN

    ; --- Configuração do ADC ---
    ; Referência = AVcc com capacitor no AREF, entrada = ADC0 (PC0)
    LDI r16, (1 << REFS0)
    STS _SFR_MEM_ADDR(ADMUX), r16

    ; Habilita ADC e prescaler 128 (16 MHz / 128 = 125 kHz → dentro da faixa permitida)
    LDI r16, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
    STS _SFR_MEM_ADDR(ADCSRA), r16

    ; --- Configuração do Timer1 em Fast PWM 10 bits ---
    ; Modo: WGM13:0 = 0b1111 → Fast PWM, 10 bits
    ; TCCR1A: WGM11=1, WGM10=1 → bits 1:0 = 11
    ;         COM1A1=1 para saída não invertida no OC1A
    LDI r16, (1 << WGM11) | (1 << WGM10) | (1 << COM1A1)
    STS _SFR_MEM_ADDR(TCCR1A), r16

    ; TCCR1B: WGM13=1, WGM12=1 → bits 4:3 = 11
    ;         CS10=1 → prescaler = 1 (frequência alta de PWM)
    LDI r16, (1 << WGM13) | (1 << WGM12) | (1 << CS10)
    STS _SFR_MEM_ADDR(TCCR1B), r16

    ; Inicia com PWM = 0%
    CLR r16
    STS _SFR_MEM_ADDR(OCR1AL), r16
    STS _SFR_MEM_ADDR(OCR1AH), r16

; --- Loop principal ---
main_loop:
    ; Inicia conversão ADC
    LDS r16, _SFR_MEM_ADDR(ADCSRA)
    ORI r16, (1 << ADSC)
    STS _SFR_MEM_ADDR(ADCSRA), r16

    ; Espera a conversão terminar (ADSC volta a 0)
wait_adc:
    LDS r16, _SFR_MEM_ADDR(ADCSRA)
    SBRC r16, ADSC
    RJMP wait_adc

    ; Lê valor de 10 bits do ADC
    LDS r16, _SFR_MEM_ADDR(ADCL)   ; Parte baixa (bits 0–7)
    LDS r17, _SFR_MEM_ADDR(ADCH)   ; Parte alta  (bits 8–9)

    ; Escreve valor diretamente no registrador de comparação OCR1A
    ; Isso define o duty cycle do PWM no pino OC1A (D9)
    STS _SFR_MEM_ADDR(OCR1AL), r16
    STS _SFR_MEM_ADDR(OCR1AH), r17

    ; Pequeno atraso para estabilidade (opcional)
    LDS r18, microTime
delay_loop:
    DEC r18
    BRNE delay_loop

    RJMP main_loop   ; Repete indefinidamente
