.model small
.stack 100h
.data
    msg1 db 'Digite um numero (1-8): $'
    msg2 db 13, 10, 'Fatorial = $'
    input db ?
    result dw 1

.code
start:
    mov ax, @data
    mov ds, ax

    ; Mostra a mensagem para entrada
    lea dx, msg1
    mov ah, 09h
    int 21h

    ; Lê um caractere do teclado
    mov ah, 01h
    int 21h
    sub al, '0'          ; converte ASCII para número
    mov cl, al           ; armazena em CL (contador)
    mov bl, al           ; BL usaremos para multiplicação
    cmp cl, 1
    jb invalid_input
    cmp cl, 8
    ja invalid_input

    ; Mostra "Fatorial ="
    lea dx, msg2
    mov ah, 09h
    int 21h

    ; Calcula fatorial
    mov ax, 1            ; acumulador
factorial_loop:
    mul bl               ; AX = AX * BL
    dec bl
    cmp bl, 1
    ja factorial_loop

    ; Agora AX contém o fatorial
    ; Vamos exibir o número em AX
    call print_number

    ; Finaliza
    mov ah, 4ch
    int 21h

; --------------------------
; Exibe número inteiro em AX
; --------------------------
print_number proc
    mov cx, 0            ; contador de dígitos
    mov bx, 10

next_digit:
    xor dx, dx
    div bx               ; AX ÷ 10, resto em DX
    push dx              ; guarda dígito
    inc cx
    cmp ax, 0
    jne next_digit

print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop
    ret
print_number endp

invalid_input:
    mov ah, 09h
    lea dx, invalid_msg
    int 21h
    jmp $

invalid_msg db 13, 10, 'Entrada invalida. Reinicie o programa.$'

end start
