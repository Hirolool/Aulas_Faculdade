.model small
.stack 100h

.data
    msg1 db 'Digite um numero (0-255): $'
    msg2 db 13, 10, 'Binario: $'
    newline db 13, 10, '$'
    number_to_convert db ? ; Variável para armazenar o número lido

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Mostra a mensagem de entrada
    lea dx, msg1
    mov ah, 09h
    int 21h

    ; Lê número decimal (retorna em AL)
    call read_number

    ; Salva o número lido para uso posterior
    mov [number_to_convert], al

    ; Mostra a mensagem "Binario: "
    lea dx, msg2
    mov ah, 09h
    int 21h

    ; Carrega o número a ser convertido em BL
    mov bl, [number_to_convert]
    
    ; Configura para imprimir 8 bits
    mov cl, 8           ; Contador de bits (8 bits)
    mov ch, 80h         ; Máscara inicial (10000000b - bit mais significativo)

print_loop:
    mov al, bl          ; Copia o número para AL para a operação AND (preserva BL)
    and al, ch          ; Testa o bit atual: (número) AND (máscara)
                        ; Se o resultado for 0, o bit é 0. Senão, o bit é 1.

    jz print_zero       ; Se o resultado da AND for zero (ZF=1), pula para imprimir '0'

print_one:
    mov dl, '1'         ; Prepara '1' para impressão
    jmp do_print        ; Pula para a rotina de impressão
print_zero:
    mov dl, '0'         ; Prepara '0' para impressão
do_print:
    mov ah, 02h         ; Função do DOS para imprimir caractere em DL
    int 21h

    shr ch, 1           ; Desloca a máscara um bit para a direita (ex: 10000000b -> 01000000b)
    dec cl              ; Decrementa o contador de bits
    jnz print_loop      ; Se CL não for zero, continua o loop

    ; Imprime uma nova linha
    lea dx, newline
    mov ah, 09h
    int 21h

    ; Termina o programa
    mov ah, 4ch
    int 21h
main endp

;-------------------------------------------------------
; Função: Lê número decimal digitado pelo usuário (0-255)
; Entrada: Usuário digita até 3 dígitos e pressiona Enter.
; Saída: AL contém o valor decimal do número lido.
; Registradores usados/modificados: AX, BX, CX, DX, SI
;-------------------------------------------------------
read_number proc
    push bx             ; Preserva os registradores que serão modificados
    push cx
    push dx
    push si

    xor bx, bx          ; Zera BX (acumulador do número)
.next_digit_loop:
    mov ah, 01h         ; Função do DOS: ler caractere do teclado com eco
    int 21h             ; Caractere lido vai para AL

    cmp al, 13          ; Verifica se é a tecla Enter (carriage return)
    je .done_reading_number ; Se sim, termina a leitura

    ; Valida se o caractere é um dígito ('0' a '9')
    cmp al, '0'
    jl .next_digit_loop ; Se for menor que '0', ignora e lê o próximo
    cmp al, '9'
    jg .next_digit_loop ; Se for maior que '9', ignora e lê o próximo

    sub al, '0'         ; Converte o caractere do dígito para seu valor numérico
                        ; (ex: '5' (ASCII 35h) - '0' (ASCII 30h) = 5)
    mov ah, 0           ; Limpa AH para que AX contenha apenas o valor do dígito (0-9)
    mov si, ax          ; Guarda o valor do dígito em SI (AX é 16 bits, mas só AL importa aqui)

    ; Acumula o número: BX = (BX * 10) + novo_digito
    ; Calcula BX * 10 de forma segura para 16 bits:
    mov ax, bx          ; Copia o valor atual de BX para AX (para calcular BX_atual * 8)
    shl bx, 1           ; BX = BX_atual * 2
    shl ax, 3           ; AX = BX_atual * 8
    add bx, ax          ; BX = (BX_atual * 2) + (BX_atual * 8) = BX_atual * 10

    ; Adiciona o novo dígito (que está em SI) a BX
    add bx, si          ; BX = (BX * 10) + novo_digito

    ; Opcional: verificar se BX ultrapassa 255 e tratar (ex: mostrar erro ou limitar)
    ; Para este exercício, a limitação para 0-255 é feita ao final, pegando apenas BL.
    ; cmp bx, 255
    ; ja .handle_overflow

    jmp .next_digit_loop ; Volta para ler o próximo dígito

.done_reading_number:
    ; O resultado final deve caber em AL (0-255).
    ; mov al, bl pega os 8 bits inferiores de BX, efetivamente truncando se BX > 255.
    mov al, bl          ; Coloca o valor acumulado (parte baixa, até 255) em AL para retorno

    pop si              ; Restaura os registradores salvos
    pop dx
    pop cx
    pop bx
    ret                 ; Retorna para o chamador
read_number endp

end main