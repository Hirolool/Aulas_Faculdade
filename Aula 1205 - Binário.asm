.model small
.stack 100h

.data
    msg1 db 'Digite um numero (0-255): $'
    msg2 db 13, 10, 'Binario: $'
    newline db 13, 10, '$'
    number_to_convert db ? ; Vari�vel para armazenar o n�mero lido

.code
main proc
    mov ax, @data
    mov ds, ax

    ; Mostra a mensagem de entrada
    lea dx, msg1
    mov ah, 09h
    int 21h

    ; L� n�mero decimal (retorna em AL)
    call read_number

    ; Salva o n�mero lido para uso posterior
    mov [number_to_convert], al

    ; Mostra a mensagem "Binario: "
    lea dx, msg2
    mov ah, 09h
    int 21h

    ; Carrega o n�mero a ser convertido em BL
    mov bl, [number_to_convert]
    
    ; Configura para imprimir 8 bits
    mov cl, 8           ; Contador de bits (8 bits)
    mov ch, 80h         ; M�scara inicial (10000000b - bit mais significativo)

print_loop:
    mov al, bl          ; Copia o n�mero para AL para a opera��o AND (preserva BL)
    and al, ch          ; Testa o bit atual: (n�mero) AND (m�scara)
                        ; Se o resultado for 0, o bit � 0. Sen�o, o bit � 1.

    jz print_zero       ; Se o resultado da AND for zero (ZF=1), pula para imprimir '0'

print_one:
    mov dl, '1'         ; Prepara '1' para impress�o
    jmp do_print        ; Pula para a rotina de impress�o
print_zero:
    mov dl, '0'         ; Prepara '0' para impress�o
do_print:
    mov ah, 02h         ; Fun��o do DOS para imprimir caractere em DL
    int 21h

    shr ch, 1           ; Desloca a m�scara um bit para a direita (ex: 10000000b -> 01000000b)
    dec cl              ; Decrementa o contador de bits
    jnz print_loop      ; Se CL n�o for zero, continua o loop

    ; Imprime uma nova linha
    lea dx, newline
    mov ah, 09h
    int 21h

    ; Termina o programa
    mov ah, 4ch
    int 21h
main endp

;-------------------------------------------------------
; Fun��o: L� n�mero decimal digitado pelo usu�rio (0-255)
; Entrada: Usu�rio digita at� 3 d�gitos e pressiona Enter.
; Sa�da: AL cont�m o valor decimal do n�mero lido.
; Registradores usados/modificados: AX, BX, CX, DX, SI
;-------------------------------------------------------
read_number proc
    push bx             ; Preserva os registradores que ser�o modificados
    push cx
    push dx
    push si

    xor bx, bx          ; Zera BX (acumulador do n�mero)
.next_digit_loop:
    mov ah, 01h         ; Fun��o do DOS: ler caractere do teclado com eco
    int 21h             ; Caractere lido vai para AL

    cmp al, 13          ; Verifica se � a tecla Enter (carriage return)
    je .done_reading_number ; Se sim, termina a leitura

    ; Valida se o caractere � um d�gito ('0' a '9')
    cmp al, '0'
    jl .next_digit_loop ; Se for menor que '0', ignora e l� o pr�ximo
    cmp al, '9'
    jg .next_digit_loop ; Se for maior que '9', ignora e l� o pr�ximo

    sub al, '0'         ; Converte o caractere do d�gito para seu valor num�rico
                        ; (ex: '5' (ASCII 35h) - '0' (ASCII 30h) = 5)
    mov ah, 0           ; Limpa AH para que AX contenha apenas o valor do d�gito (0-9)
    mov si, ax          ; Guarda o valor do d�gito em SI (AX � 16 bits, mas s� AL importa aqui)

    ; Acumula o n�mero: BX = (BX * 10) + novo_digito
    ; Calcula BX * 10 de forma segura para 16 bits:
    mov ax, bx          ; Copia o valor atual de BX para AX (para calcular BX_atual * 8)
    shl bx, 1           ; BX = BX_atual * 2
    shl ax, 3           ; AX = BX_atual * 8
    add bx, ax          ; BX = (BX_atual * 2) + (BX_atual * 8) = BX_atual * 10

    ; Adiciona o novo d�gito (que est� em SI) a BX
    add bx, si          ; BX = (BX * 10) + novo_digito

    ; Opcional: verificar se BX ultrapassa 255 e tratar (ex: mostrar erro ou limitar)
    ; Para este exerc�cio, a limita��o para 0-255 � feita ao final, pegando apenas BL.
    ; cmp bx, 255
    ; ja .handle_overflow

    jmp .next_digit_loop ; Volta para ler o pr�ximo d�gito

.done_reading_number:
    ; O resultado final deve caber em AL (0-255).
    ; mov al, bl pega os 8 bits inferiores de BX, efetivamente truncando se BX > 255.
    mov al, bl          ; Coloca o valor acumulado (parte baixa, at� 255) em AL para retorno

    pop si              ; Restaura os registradores salvos
    pop dx
    pop cx
    pop bx
    ret                 ; Retorna para o chamador
read_number endp

end main