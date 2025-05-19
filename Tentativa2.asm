.MODEL SMALL
.STACK 100h

.DATA
    ; --- Constantes ---
    CR EQU 0Dh       ; Carriage Return
    LF EQU 0Ah       ; Line Feed
    MAX_TAREFAS EQU 20 ; N�mero m�ximo de tarefas (limitando as letras de A a T)
    TAREFA_SIZE EQU 50 ; Tamanho m�ximo de cada string de tarefa
    ; Nota: Cada tarefa ser� uma string de at� 50 bytes, incluindo o terminador nulo.

    ; --- Vari�veis ---
    total_tarefas dw 0 ; Contador de tarefas salvas atualmente (inicializa com 0)
    tarefas DB MAX_TAREFAS * TAREFA_SIZE DUP(0) ; Buffer para armazenar as tarefas (20 tarefas * 50 bytes)

    input_buffer DB 255, ?, 255 DUP('$') ; Buffer de entrada para INT 21h AH=0Ah (max_len, actual_len, data...)
    number_buffer DB 10 DUP('$') ; Buffer tempor�rio para convers�o de n�mero bin�rio para string
    ; Note: number_buffer e print_number_proc s�o mantidos como helpers gerais, mas n�o ser�o usados para IDs de tarefas.

    ; --- Mensagens ---
    MSG_MENU DB '--- Gerenciador de Tarefas ---', CR, LF
             DB '1. Adicionar nova tarefa', CR, LF
             DB '2. Listar tarefas', CR, LF
             DB '3. Editar tarefa por letra', CR, LF
             DB '4. Deletar tarefa por letra', CR, LF
             DB '5. Sair', CR, LF
             DB 'Escolha uma opcao: $'

    MSG_ENTER_TAREFA         DB "Digite a nova tarefa (max 49 caracteres): $" ; Max 49 + null terminator = 50
    MSG_TAREFA_SAVED         DB "Tarefa salva com sucesso!", CR, LF, "$"
    MSG_BUFFER_FULL          DB "Limite de tarefas atingido.", CR, LF, "$"
    MSG_NO_TAREFAS           DB "Nenhuma tarefa cadastrada.", CR, LF, "$"

    MSG_TAREFA_LABEL        DB "Tarefa " ; <<< Mensagem para listar (sem o '#')
    MSG_COLON_SPACE      DB ": $"

    MSG_SELECT_EDIT          DB "Digite a letra da tarefa para editar: $" ; <<< Mensagem para Editar (pede letra)
    MSG_INVALID_INPUT       DB "Entrada invalida.", CR, LF, "$" ; <<< Mensagem geral para entrada inv�lida
    MSG_EDIT_TAREFA          DB "Digite o NOVO texto da tarefa (max 49 caracteres): $" ; <<< Mensagem para Editar
    MSG_TAREFA_EDITADA       DB "Tarefa editada com sucesso!", CR, LF, "$" ; <<< Mensagem para Editar

    MSG_SELECT_DELETE        DB "Digite a letra da tarefa a remover: $" ; Mensagem para remover (pede letra)
    MSG_TAREFA_DELETADA      DB "Tarefa removida com sucesso!", CR, LF, "$"

    MSG_INVALID_OPTION   DB "Opcao invalida!", CR, LF, "$" ; Mensagem para op��o inv�lida do menu
    MSG_SAIR             DB "Encerrando o programa...", CR, LF, "$"
    MSG_PRESS_ENTER      DB "Pressione Enter para continuar...$", CR, LF

    ; Mensagens de receita removidas ou adaptadas.

.CODE
start:
    MOV AX, @data
    MOV DS, AX

main_menu:
    ; Limpa a tela AGORA, no in�cio de cada ciclo do menu
    ; Usando INT 10h AH=06h para limpar a tela
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV ah, 06h
    mov al, 0
    mov bh, 07h ; Attribute (white on black)
    mov cx, 0   ; Upper left corner (row 0, col 0)
    mov dx, 184Fh ; Lower right corner (row 24, col 79) in 0-based index
    int 10h
    ; Move cursor to top-left
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h
    POP DX
    POP CX
    POP BX
    POP AX


    MOV DX, OFFSET MSG_MENU
    CALL print_string_proc

    ; --- LIMPEZA EXPL�CITA DO input_buffer REMOVIDA DAQUI ---
    ; PUSH ES ... REP STOSB ... POP ES


    ; Usar leitura robusta para a op��o do menu
    MOV input_buffer, 2 ; Tamanho m�ximo de 2 para garantir 1 ou 2 d�gitos para op��o
    MOV DX, OFFSET input_buffer
    CALL read_string_proc ; Reads menu option
    CALL newline_proc ; Nova linha ap�s ler a op��o do menu

    ; Pega o primeiro caractere digitado
    MOV AL, [input_buffer + 2] ; O caractere da op��o est� no offset 2
    ; Validar se � um d�gito entre '1' e '5'
    SUB AL, '0' ; Converte ASCII para n�mero
    MOV AH, 0 ; Limpa AH
    MOV BX, AX; BX = op��o escolhida (n�mero)

    ; Valida��o de range da op��o num�rica
    CMP BX, 1
    JL invalid_option_handler
    CMP BX, 5
    JG invalid_option_handler


    ; Adiciona novas linhas ANTES de pular para a rotina da op��o (manter para espa�amento visual)
    CALL newline_proc
    CALL newline_proc ; Adiciona uma linha extra para espa�amento


    ; Redireciona para a rotina apropriada
    CMP BX, 1
    JE adicionar_tarefa_jmp
    CMP BX, 2
    JE listar_tarefas_jmp    ; <<< Pula para listar todas as tarefas
    CMP BX, 3
    JE editar_tarefa_jmp     ; <<< Pula para editar por letra
    CMP BX, 4
    JE remover_tarefa_jmp    ; <<< Pula para deletar por letra
    CMP BX, 5
    JE sair_jmp              ; <<< Pula para sair

    ; invalid_option_handler � tratado ap�s a verifica��o


adicionar_tarefa_jmp: JMP adicionar_tarefa
listar_tarefas_jmp: JMP listar_tarefas
editar_tarefa_jmp: JMP editar_tarefa
remover_tarefa_jmp: JMP remover_tarefa
sair_jmp: JMP sair


; --- PROCEDIMENTOS HELPERS (Adaptados do c�digo anterior de tarefas) ---

; print_string_proc: Imprime string terminada em '$' (endere�o em DX)
print_string_proc PROC NEAR
    PUSH DX
    PUSH AX
    MOV AH, 09h
    INT 21h
    POP AX
    POP DX
    RET
print_string_proc ENDP

; newline_proc: Imprime CR e LF
newline_proc PROC NEAR
    PUSH AX
    PUSH DX
    MOV AH, 02h
    MOV DL, CR
    INT 21h
    MOV DL, LF
    INT 21h
    POP DX
    POP AX
    RET
newline_proc ENDP

; read_string_proc: L� string para buffer (endere�o em DX) - Corrigido erro de pilha
; Usa INT 21h AH=0Ah. Substitui o CR final por '$'.
; L� para o input_buffer global. O tamanho m�ximo deve ser definido em input_buffer[0] antes da chamada.
read_string_proc PROC NEAR
    ; Assume que input_buffer[0] tem o tamanho m�ximo desejado
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH AX

    MOV AH, 0Ah
    ; DX j� deve ter o OFFSET input_buffer ao chamar
    INT 21h

    ; Substitui o CR final por '$' para compatibilidade com print_string_proc
    MOV SI, DX
    MOV BL, [SI + 1] ; Tamanho real lido (no offset 1)
    MOV BH, 0        ; BX = tamanho real
    MOV SI, DX
    ADD SI, BX
    ADD SI, 2        ; Posi��o do CR
    MOV BYTE PTR [SI], '$' ; Coloca '$'

    ; Garante que o input_buffer + 2 + tamanho real lido + 1 � nulo para print_null_terminated_string
    MOV SI, DX
    ADD SI, BX
    ADD SI, 2 + 1 ; Posi��o ap�s '$'
    MOV BYTE PTR [SI], 0 ; Coloca terminador nulo ap�s '$'

    POP AX ; <<< Corrigido: Apenas um POP AX para balancear o PUSH AX
    POP DI
    POP SI
    POP CX
    POP BX

    RET
read_string_proc ENDP

; read_number_proc: Mantido como helper geral, mas n�o usado para IDs de tarefa neste c�digo.
; L� string num�rica do input_buffer e converte para bin�rio em AX
; Retorna 0 em AX se entrada inv�lida (n�o num�rica ou vazia). Imprime mensagem de inv�lido.
read_number_proc PROC NEAR
    ; Assume que input_buffer[0] tem o tamanho m�ximo desejado (ex: 5 para um ID de 5 d�gitos)
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH DX

    MOV DX, OFFSET input_buffer ; L� para input_buffer
    CALL read_string_proc
    CALL newline_proc ; Nova linha ap�s ler a string do n�mero

    MOV SI, OFFSET input_buffer + 2 ; In�cio dos dados da string (ap�s max_len e actual_len)
    MOV BL, [input_buffer + 1]     ; Tamanho real da string
    MOV BH, 0                      ; BX = tamanho real (length)

    MOV AX, 0 ; Resultado num�rico (16-bit), inicializa com 0

    CMP BX, 0 ; Se string vazia, � inv�lido
    JE invalid_number_input_rnp

read_num_loop_rnp:
    CMP BX, 0 ; Se tamanho real for 0, acabou
    JE read_num_done_rnp

    MOV CL, [SI]    ; Pega o caractere do d�gito
    CMP CL, '$'     ; Para na termina��o '$' (colocada por read_string_proc)
    JE read_num_done_rnp

    ; Verifica se � um d�gito v�lido ('0'-'9')
    CMP CL, '0'
    JL invalid_number_input_rnp
    CMP CL, '9'
    JG invalid_number_input_rnp

    SUB CL, '0'     ; Converte caractere de d�gito para valor num�rico
    MOV CH, 0       ; CX = valor do d�gito (16-bit)

    ; Multiplica o resultado atual (AX) por 10 e adiciona o d�gito
    ; Verifica overflow impl�cito (se AX * 10 > 65535) - Simplificado para este programa
    Push CX         ; Salva valor do d�gito
    Mov CX, 10      ; Multiplicador
    Mul CX          ; AX = AX * CX. Resultado em DX:AX. Se DX != 0, houve overflow.
    Pop CX          ; Restaura valor do d�gito
    CMP DX, 0
    JNE invalid_number_input_rnp ; Se houve overflow, entrada inv�lida

    Add AX, CX      ; AX = (resultado * 10) + d�gito

    INC SI          ; Pr�ximo caractere
    DEC BX          ; Decrementa contador do loop
    JMP read_num_loop_rnp

invalid_number_input_rnp:
    MOV AX, 0 ; Indica erro ou entrada inv�lida
    ; N�o imprime mensagem aqui, a rotina chamadora decide o que fazer com AX=0.

read_num_done_rnp:
    ; O resultado est� em AX (0 se inv�lido)

    POP DX
    POP DI
    POP SI
    POP CX
    POP BX
    RET
read_number_proc ENDP


; print_number_proc: Mantido como helper geral, mas n�o usado para IDs de tarefa neste c�digo.
; Imprime n�mero bin�rio em AX como string ASCII
print_number_proc PROC NEAR
    ; Imprime n�mero em AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH BP

    MOV CX, 0   ; Contador para d�gitos
    MOV BP, OFFSET number_buffer + 9 ; Come�a a escrever do final do buffer
    MOV BYTE PTR [BP + 1], '$' ; Terminador de string

    CMP AX, 0
    JE print_zero_num_pnp ; PNP - Print Number Proc

print_num_loop_pnp:
    MOV DX, 0     ; Limpa DX para a divis�o (DX:AX / BX)
    MOV BX, 10    ; Divisor
    DIV BX        ; AX = quociente, DX = resto (o d�gito)

    PUSH DX       ; Empilha o resto (o d�gito)
    INC CX        ; Incrementa contador de d�gitos

    CMP AX, 0     ; Se o quociente for 0, acabamos
    JNE print_num_loop_pnp

print_num_print_loop_pnp:
    POP DX        ; Desempilha o resto (o d�gito)
    ADD DL, '0'   ; Converte para caractere ASCII

    MOV BYTE PTR [BP], DL ; Armazena o d�gito no buffer (crescendo para tr�s)
    DEC BP                ; Move para a posi��o anterior no buffer

    LOOP print_num_print_loop_pnp ; Repete CX vezes

    ; Imprime o buffer a partir de BP+1 (where the first digit was placed)
    MOV DX, BP + 1
    CALL print_string_proc

    JMP print_num_done_pnp

print_zero_num_pnp: ; Label separado para imprimir 0
    MOV BYTE PTR [BP], '0' ; Apenas imprime '0'
    MOV DX, BP
    CALL print_string_proc

print_num_done_pnp:
    POP BP
    POP SI
    POP DX
    POP CX
    POP BX
    RET
print_number_proc ENDP

; print_null_terminated_string: Imprime string terminada em zero (endere�o em SI)
print_null_terminated_string PROC NEAR
    PUSH AX
    PUSH DX
    PUSH SI

    mov ah, 02h
print_null_loop:
    mov al, [si]
    cmp al, 0
    je fim_print_null
    mov dl, al
    int 21h
    inc si
    jmp print_null_loop
fim_print_null:
    POP SI
    POP DX
    POP AX
    ret
print_null_terminated_string ENDP


; esperar_tecla_proc: Espera o usu�rio pressionar Enter - Simplificado para INT 21h, AH=08h
esperar_tecla_proc PROC NEAR
    PUSH AX
    PUSH DX
    MOV DX, OFFSET MSG_PRESS_ENTER
    CALL print_string_proc ; Prints "Pressione Enter..."

    ; Use simple wait for single character (like original esperar_tecla)
    MOV AH, 08h ; Wait for character input without echoing
    INT 21h

    CALL newline_proc ; Prints a newline after the key press

    POP DX
    POP AX
    RET ; Returns
esperar_tecla_proc ENDP

; read_letter_proc: L� uma letra (A-Z) e converte para �ndice (0-based) em AX
; Retorna o �ndice em AX (0..MAX_TAREFAS-1) se v�lido.
; Se inv�lido (n�o letra, fora do range de tarefas), salta para invalid_letter_handler.
read_letter_proc PROC NEAR
    PUSH BX
    PUSH DX
    PUSH AX ; Salva AX

    ; L� um �nico caractere com eco
    MOV AH, 01h
    INT 21h
    ; AL cont�m o caractere lido

    CALL newline_proc ; Nova linha ap�s ler o caractere

    ; Verifica se � uma letra mai�scula
    CMP AL, 'A'
    JL invalid_letter_input
    CMP AL, 'Z'
    JG invalid_letter_input

    ; Converte letra para �ndice 0-based
    SUB AL, 'A' ; 'A'->0, 'B'->1, etc.
    MOV AH, 0   ; Limpa AH, AX agora cont�m o �ndice 0-based

    ; Valida se o �ndice est� dentro do n�mero de tarefas salvas
    MOV BX, AX ; Move �ndice para BX para compara��o
    MOV CX, total_tarefas ; Total de tarefas para compara��o
    CMP BX, CX ; Compara �ndice com total_tarefas
    JGE invalid_letter_input ; Se �ndice >= total_tarefas, � inv�lido

    ; Entrada v�lida
    POP AX ; Restaura AX antes do RET
    RET ; �ndice v�lido em AX

invalid_letter_input:
    ; Entrada inv�lida (n�o letra A-Z ou fora do range de tarefas)
    ; Salta para o handler de entrada inv�lida de letra
    POP AX ; Restaura AX
    POP DX
    POP BX ; Popa na ordem inversa do push para manter pilha limpa antes do JMP
    JMP invalid_letter_handler ; Salta para o handler

read_letter_proc ENDP


; --- ROTINAS DE TAREFAS (Adaptadas das rotinas de receita e tarefas anteriores) ---

; adicionar_tarefa: Cria uma nova tarefa (adaptada da create_recipe_proc)
adicionar_tarefa PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Verifica se o buffer est� cheio
    MOV AX, total_tarefas
    CMP AX, MAX_TAREFAS
    JGE limite_tarefas_handler

    ; Calcula o endere�o no buffer onde a nova tarefa ser� armazenada
    MOV AX, total_tarefas ; �ndice da nova tarefa (0-based)
    MOV BX, TAREFA_SIZE
    MUL BX ; DX:AX = total_tarefas * TAREFA_SIZE
    MOV DI, AX ; DI = offset no buffer tarefas
    ADD DI, OFFSET tarefas ; DI aponta para o in�cio do slot da nova tarefa

    ; --- L� Descri��o da Tarefa ---
    MOV DX, OFFSET MSG_ENTER_TAREFA
    CALL print_string_proc
    MOV input_buffer, 49 ; Define tamanho m�ximo (49 + 1 para nulo)
    MOV DX, OFFSET input_buffer
    CALL read_string_proc ; L� a string para input_buffer

    ; Obt�m o tamanho real lido e endere�o de origem dos dados
    MOV BL, [input_buffer + 1] ; Tamanho real da string lida
    MOV BH, 0                ; BX = tamanho real
    MOV SI, OFFSET input_buffer + 2 ; Endere�o de in�cio dos dados

    ; Calcula bytes a copiar (tamanho real + terminador nulo)
    MOV CX, BX ; CX = tamanho real
    INC CX     ; Inclui espa�o para o terminador nulo

    ; Garante que n�o copia mais que TAREFA_SIZE
    CMP CX, TAREFA_SIZE
    JLE copy_size_task_ok
    MOV CX, TAREFA_SIZE
copy_size_task_ok:

    ; Limpa o slot antigo da tarefa (opcional, mas boa pr�tica)
    PUSH DI ; Salva DI
    PUSH CX ; Salva CX (bytes a copiar)
    MOV CX, TAREFA_SIZE ; Bytes a limpar
    MOV AL, 0
    PUSH DS
    POP ES
    CLD
    REP STOSB ; Limpa o slot
    POP CX ; Restaura CX (bytes a copiar)
    POP DI ; Restaura DI

    ; Copia os dados da tarefa (string + nulo)
    PUSH DS ; ES = DS
    POP ES
    CLD ; Dire��o para frente
    REP MOVSB ; Copia CX bytes de DS:SI para ES:DI


    ; Incrementa o contador de tarefas
    INC total_tarefas

    ; Exibe mensagem de sucesso
    MOV DX, OFFSET MSG_TAREFA_SAVED
    CALL print_string_proc

    ; *** Mensagem para o usu�rio pressionar Enter para continuar ***
    CALL esperar_tecla_proc

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    JMP main_menu ; Retorna para o menu principal

adicionar_tarefa ENDP


; listar_tarefas: Lista todas as tarefas (adaptada da rotina anterior de tarefas)
listar_tarefas PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    mov ax, total_tarefas
    cmp ax, 0
    je sem_tarefa_handler ; <<< Usa handler

    CALL newline_proc ; Espa�o antes da lista

    mov cx, 0 ; Contador do loop (�ndice 0-based)

listar_loop_start: ; Loop principal para listar
    cmp cx, total_tarefas
    jae fim_listagem

    ; Endere�o da tarefa atual no buffer 'tarefas'
    mov ax, cx
    mov di, TAREFA_SIZE ; Usar DI temporariamente para o tamanho
    mul di ; DX:AX = �ndice * TAREFA_SIZE
    mov si, ax ; SI aponta para o offset no buffer 'tarefas'
    add si, offset tarefas ; SI aponta para o in�cio do slot da string de tarefa

    ; Imprimir "Tarefa " (sem o '#')
    mov dx, offset MSG_TAREFA_LABEL ; <<< Usando OFFSET
    CALL print_string_proc

    ; Imprimir a letra da tarefa ('A' + �ndice)
    mov al, 'A'
    add al, cl      ; AL = 'A' + �ndice (CX)
    mov ah, 02h     ; Fun��o para imprimir um caractere
    mov dl, al      ; Caractere a imprimir
    int 21h

    mov dx, offset MSG_COLON_SPACE ; <<< Usando OFFSET
    CALL print_string_proc

    ; Imprimir a string da tarefa (terminada em nulo)
    ; SI j� aponta para o in�cio da string
    CALL print_null_terminated_string

    CALL newline_proc ; Nova linha ap�s cada tarefa

    inc cx ; Pr�ximo �ndice
    jmp listar_loop_start ; Volta para o in�cio do loop

fim_listagem:
    CALL esperar_tecla_proc ; Espera Enter

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    jmp main_menu

listar_tarefas ENDP


; editar_tarefa: Edita uma tarefa existente por letra (adaptada da rotina de receita e tarefa anterior)
editar_tarefa PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES ; Usado por STOSB e MOVSB

    mov ax, total_tarefas
    cmp ax, 0
    je sem_tarefa_handler ; Se n�o h� tarefas, n�o pode editar

    mov dx, offset MSG_SELECT_EDIT ; Pede a LETRA para editar
    CALL print_string_proc

    ; L� a letra da tarefa e obt�m o �ndice em AX (ou salta para handler se inv�lido)
    CALL read_letter_proc ; Retorna �ndice em AX ou salta para invalid_letter_handler

    ; Se chegamos aqui, AX cont�m o �ndice 0-based v�lido.
    ; Calcula o endere�o da tarefa a ser editada usando o �ndice em AX
    mov bx, TAREFA_SIZE
    mul bx ; DX:AX = �ndice * TAREFA_SIZE
    mov di, ax ; DI = offset
    add di, offset tarefas ; DI aponta para o slot a editar

    mov dx, offset MSG_EDIT_TAREFA ; Pede o novo texto da tarefa
    CALL print_string_proc

    ; L� o novo texto da tarefa
    MOV input_buffer, 49 ; Define tamanho m�ximo (49 + 1 para nulo)
    MOV DX, OFFSET input_buffer
    CALL read_string_proc ; L� para input_buffer

    ; --- Limpar o slot antigo ANTES de copiar o novo texto ---
    PUSH DI ; Salva DI (start of task slot)
    MOV CX, TAREFA_SIZE ; Number of bytes to clear (full slot)
    MOV AL, 0 ; Fill byte is 0
    PUSH DS
    POP ES ; ES = DS
    CLD ; Forward direction
    REP STOSB ; Clear the slot starting at the original DI
    POP DI ; Restore DI (points to the start of the slot again)

    ; --- Recalcular CX (bytes a copiar) depois de STOSB ---
    mov si, offset input_buffer + 2 ; SI aponta para os dados lidos
    mov cl, [input_buffer + 1]     ; CL = tamanho real lido
    mov ch, 0                      ; CX = tamanho real
    inc cx                         ; Inclui terminador nulo na contagem

    ; Garantir que a contagem de c�pia n�o exceda TAREFA_SIZE
    cmp cx, TAREFA_SIZE
    jle final_copy_size_ok_edit
    mov cx, TAREFA_SIZE
final_copy_size_ok_edit:
    ; CX agora cont�m o n�mero correto de bytes a copiar (incluindo nulo)

    ; --- Realiza a c�pia ---
    ; DI j� est� apontando corretamente para o in�cio do slot da tarefa
    ; SI j� est� apontando corretamente para o in�cio dos novos dados em input_buffer
    ; CX cont�m o n�mero correto de bytes a copiar
    push ds ; ES = DS para a c�pia
    pop es
    cld ; Dire��o para frente
    rep movsb ; Copia CX bytes de DS:SI para ES:DI

    MOV DX, OFFSET MSG_TAREFA_EDITADA ; Imprime mensagem de sucesso
    CALL print_string_proc
    CALL esperar_tecla_proc ; Espera Enter

    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    jmp main_menu

editar_tarefa ENDP


; remover_tarefa: Apaga uma tarefa existente por letra (adaptada da rotina de receita e tarefa anterior)
remover_tarefa PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES ; Usado por MOVSB e STOSB

    mov ax, total_tarefas
    cmp ax, 0
    je sem_tarefa_handler ; <<< Usa handler

    mov dx, offset MSG_SELECT_DELETE ; Pede a LETRA para remover
    CALL print_string_proc

    ; L� a letra da tarefa e obt�m o �ndice em AX (ou salta para handler se inv�lido)
    CALL read_letter_proc ; Retorna �ndice em AX ou salta para invalid_letter_handler

    ; Se chegamos aqui, AX cont�m o �ndice 0-based v�lido.
    ; Calcula os endere�os para o deslocamento (shifting) usando o �ndice em AX
    mov bx, AX ; BX = �ndice a apagar (0-based)

    ; Endere�o de ORIGEM para tarefas: In�cio da tarefa *seguinte* � que ser� apagada
    mov ax, bx ; AX = �ndice a apagar
    inc ax ; AX = �ndice + 1 (�ndice da tarefa A SER MOVIDA)
    mov cx, TAREFA_SIZE ; Usa CX temporariamente para o tamanho do slot
    mul cx ; DX:AX = (�ndice + 1) * TAREFA_SIZE
    mov si, ax ; SI = offset no buffer 'tarefas'
    add si, offset tarefas ; SI aponta para o primeiro byte A SER MOVIDO

    ; Endere�o de DESTINO: In�cio da tarefa *a ser apagada*
    mov ax, bx ; AX = �ndice a apagar
    mov cx, TAREFA_SIZE ; Usa CX temporariamente para o tamanho do slot
    mul cx ; DX:AX = �ndice * TAREFA_SIZE
    mov di, ax ; DI = offset no buffer 'tarefas'
    add di, offset tarefas ; DI aponta para a localiza��o ONDE MOVER os dados

    ; N�mero de bytes a mover - CORRIGIDO C�LCULO AQUI
    mov ax, total_tarefas ; AX = total tasks (before decrement)
    push bx ; Salva o �ndice a apagar temporariamente (BX)
    dec ax ; AX = total tasks - 1 (max 0-based index)
    pop bx ; Restaura o �ndice a apagar (BX)
    sub ax, bx ; AX = (total - 1) - �ndice_a_apagar = n�mero de tarefas AP�S a apagada (count of tasks)

    ; Agora calcula total *bytes* a mover = (n�mero de tarefas ap�s) * TAREFA_SIZE
    mov bx, TAREFA_SIZE ; BX = tamanho de uma tarefa
    mul bx ; DX:AX = (n�mero de tarefas ap�s) * TAREFA_SIZE. Resultado em DX:AX.
    mov cx, ax ; CX = total bytes a mover. Para REP MOVSB.
    ; Assume que DX permanece 0 para um n�mero razo�vel de tarefas (20*50 = 1000, cabe em AX).


    ; Configura segmentos
    push ds
    pop es ; ES = DS

    ; Realiza o deslocamento para o buffer 'tarefas'
    ; SI e DI foram calculados para 'tarefas' antes
    cld ; Ensure forward direction
    rep movsb ; Copies CX bytes from DS:SI to ES:DI

    ; Decrementa o contador de tarefas
    dec total_tarefas

    ; Limpa o �ltimo slot em 'tarefas' (que agora cont�m dados duplicados)
    mov ax, total_tarefas ; Novo contador de tarefas
    mov bx, TAREFA_SIZE
    mul bx ; DX:AX = novo_total * TAREFA_SIZE
    mov di, ax ; DI = offset do novo "�ltimo" slot em 'tarefas'
    add di, offset tarefas ; DI aponta para o in�cio da �rea a ser limpa

    mov cx, TAREFA_SIZE ; Number of bytes to clear is one full slot size
    mov al, 0 ; Fill byte is 0
    push ds
    pop es
    cld ; Forward direction
    rep stosb ; Clear the slot in 'tarefas'

    MOV DX, OFFSET MSG_TAREFA_DELETADA
    CALL print_string_proc
    CALL esperar_tecla_proc ; Espera Enter

    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    jmp main_menu

remover_tarefa ENDP


; sair: Finaliza o programa
sair PROC NEAR
    MOV DX, OFFSET MSG_SAIR
    CALL print_string_proc
    mov ah, 4Ch
    mov al, 0
    int 21h
sair ENDP


; --- Handlers para erros e limites (Adaptados do c�digo anterior de tarefas) ---
; Estes s�o alvos de JMP, n�o procedimentos que retornam com RET.

sem_tarefa_handler: ; Handler para "Nenhuma tarefa cadastrada."
    MOV DX, OFFSET MSG_NO_TAREFAS
    CALL print_string_proc
    CALL esperar_tecla_proc
    JMP main_menu ; Volta para o menu

limite_tarefas_handler: ; Handler para "Limite de tarefas atingido."
    MOV DX, OFFSET MSG_BUFFER_FULL
    CALL print_string_proc
    CALL esperar_tecla_proc
    JMP main_menu ; Volta para o menu

invalid_option_handler: ; Handler para op��o inv�lida do menu
    MOV DX, OFFSET MSG_INVALID_OPTION
    CALL print_string_proc
    CALL esperar_tecla_proc
    JMP main_menu ; Volta para o menu

invalid_letter_handler: ; Handler para entrada de letra inv�lida
    MOV DX, OFFSET MSG_INVALID_INPUT ; Usa a mensagem gen�rica
    CALL print_string_proc
    CALL esperar_tecla_proc
    JMP main_menu ; Volta para o menu


END start