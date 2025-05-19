.model small
.stack 100h

.data
    msg1 db 'Etapa 1 - Digite um numero (0-255): $'
    msg2 db 13, 10, 'Binario: $'
    newline db 13, 10, '$'
    number_to_convert db ? ; Variável para armazenar o número lido

    msg6 db 13, 10, 13, 10, 'Etapa 2 - Digite um numero binario (ate 8 bits): $'
    msg7 db 13, 10, 'Equivalente: $'

    input_bin db 10 dup(?)
    resultado db 5 dup('$')


.code
main proc
    mov ax, @data
    mov ds, ax

    lea dx, msg1
    mov ah, 09h
    int 21h

    call read_number

    mov [number_to_convert], al

    lea dx, msg2
    mov ah, 09h
    int 21h

    ; Carrega o número a ser convertido em BL
    mov bl, [number_to_convert]

    ; Configura para imprimir 8 bits (Lógica de conversão decimal para binário)
    mov cl, 8            ; Contador de bits (8 bits)
    mov ch, 80h

print_loop:
    mov al, bl
    and al, ch

    jz print_zero

print_one:
    mov dl, '1'
    jmp do_print
print_zero:
    mov dl, '0'
do_print:
    mov ah, 02h
    int 21h

    shr ch, 1
    dec cl
    jnz print_loop       ; Se CL não for zero, continua o loop

    ; Imprime uma nova linha
    lea dx, newline
    mov ah, 09h
    int 21h


    mov ah, 09h
    lea dx, msg6
    int 21h

    lea dx, input_bin
    mov ah, 0Ah
    mov byte ptr [input_bin], 9 ; Define o número máximo de caracteres a ler
    int 21h

    mov ah, 09h
    lea dx, newline
    int 21h

    ; Etapa 3 - Equivalente decimal
    mov ah, 09h
    lea dx, msg7
    int 21h

    ; Converte string binária para decimal
    call ConverterStringBinariaParaDecimal

    ; Exibir decimal convertido
    call PrintDecimal

    ; Termina o programa
    mov ah, 4ch
    int 21h
main endp


read_number proc
    push bx
    push cx
    push dx
    push si

    xor bx, bx
.next_digit_loop:
    mov ah, 01h
    int 21h     ; Caractere lido vai para AL

    cmp al, 13  ; Verifica se é a tecla Enter (carriage return)
    je .done_reading_number ; Se sim, termina a leitura

    ; Valida se o caractere é um dígito ('0' a '9')
    cmp al, '0'
    jl .next_digit_loop
    cmp al, '9'
    jg .next_digit_loop

    sub al, '0' ; Converte o caractere do dígito para seu valor numérico
    mov ah, 0   ; Limpa AH para que AX contenha apenas o valor do dígito (0-9)
    mov si, ax  ; Guarda o valor do dígito em SI

    ; Acumula o número: BX = (BX * 10) + novo_digito
    mov ax, bx
    shl bx, 1
    shl ax, 3
    add bx, ax
    add bx, si

    jmp .next_digit_loop

.done_reading_number:
    mov al, bl ; Coloca o valor acumulado (parte baixa, até 255) em AL para retorno

    pop si
    pop dx
    pop cx
    pop bx
    ret
read_number endp

ConverterStringBinariaParaDecimal proc
    push bx
    push cx
    push dx
    push si

    mov bl, 0 ; Acumulador decimal
    lea si, input_bin + 2 ; Início da string binária

    ; Pega o número real de caracteres lidos para a contagem do loop e cálculo do peso
    mov cl, byte ptr [input_bin + 1]
    mov ch, 0

    ; Calcula o peso inicial (2^(tamanho_real-1))
    mov dl, 1
    push cx
    dec cl
    test cl, cl
    js after_weight_shift_conv
    cmp cl, 255
    je after_weight_shift_conv

shift_weight_loop_conv:
    shl dl, 1
    loop shift_weight_loop_conv

after_weight_shift_conv:
    pop cx
    mov ch, 0

    test cl, cl
    jz end_converte_binaria_proc


converte_binario_loop_proc:
    mov al, [si]
    cmp al, '1'
    jne pula_soma_loop_proc

    add bl, dl

pula_soma_loop_proc:
    inc si
    shr dl, 1
    loop converte_binario_loop_proc

end_converte_binaria_proc:
    mov ah, 0
    mov al, bl

    pop si
    pop dx
    pop cx
    pop bx
    ret
ConverterStringBinariaParaDecimal endp


PrintDecimal proc
    push bx
    push cx
    push dx

    mov cx, 0
    mov bx, 10

print_loop_decimal:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz print_loop_decimal

print_final_decimal:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_final_decimal

    pop dx
    pop cx
    pop bx
    ret
PrintDecimal endp

end main ; Fim do programa, ponto de entrada é 'main'
