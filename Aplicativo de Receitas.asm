.MODEL SMALL
.STACK 100h

.DATA
    CR EQU 0Dh
    LF EQU 0Ah
    MAX_RECIPES EQU 10 ; Número máximo de receitas que podem ser salvas
    MAX_RECIPE_SIZE EQU 200
    MAX_TITLE_SIZE EQU 50   ; Tamanho máximo para os dados do título
    MAX_CONTENT_SIZE EQU 148 ; Tamanho máximo para os dados do conteúdo

    recipe_count DW 0 ; Contador de receitas salvas atualmente (inicializa com 0)
    RECIPE_BUFFER DB MAX_RECIPES * MAX_RECIPE_SIZE DUP(0) ; Buffer para armazenar as receitas

    input_buffer DB 255, ?, 255 DUP('$')
    number_buffer DB 10 DUP('$')

    MSG_MENU DB '--- Aplicativo de receitas! Administre suas receitas por aqui ---', CR, LF
             DB '1. Criar Receita', CR, LF
             DB '2. Visualizar Receita por ID', CR, LF
             DB '3. Editar Receita por ID', CR, LF
             DB '4. Apagar Receita por ID', CR, LF
             DB '5. Sair', CR, LF
             DB 'Escolha uma opcao: $'

    MSG_ENTER_TITLE     DB 'Digite o titulo da receita: $'
    MSG_ENTER_CONTENT   DB 'Digite o conteudo (ingredientes/passos): $'
    MSG_RECIPE_SAVED    DB 'Receita salva com sucesso!', CR, LF, '$'
    MSG_ASSIGNED_ID     DB 'ID atribuido: $'
    MSG_BUFFER_FULL     DB 'Nao ha espaco para mais receitas.', CR, LF, '$'
    MSG_NO_RECIPES      DB 'Nenhuma receita encontrada.', CR, LF, '$'
    MSG_SELECT_VIEW     DB 'Digite o ID da receita para visualizar: $'
    MSG_HEADER_RECIPE_ID DB '--- Receita ID $'
    MSG_HEADER_END      DB ' ---', CR, LF, '$'
    MSG_RECIPE_ID       DB 'ID: $'
    MSG_COLON_SPACE     DB ': $'
    MSG_TITLE           DB 'Titulo: $'
    MSG_CONTENT         DB 'Conteudo: $'
    MSG_SELECT_EDIT     DB 'Digite o ID da receita para editar: $'
    MSG_SELECT_DELETE   DB 'Digite o ID da receita para apagar: $'
    MSG_INVALID_ID      DB 'ID invalido.', CR, LF, '$'
    MSG_EDIT_TITLE      DB 'Digite o NOVO titulo da receita: $'
    MSG_EDIT_CONTENT    DB 'Digite o NOVO conteudo da receita: $'
    MSG_RECIPE_EDITED   DB 'Receita editada com sucesso!', CR, LF, '$'
    MSG_RECIPE_DELETED  DB 'Receita apagada com sucesso!', CR, LF, '$'
    MSG_INVALID         DB 'Opcao invalida.', CR, LF, '$'
    MSG_PRESS_ENTER     DB 'Pressione Enter para continuar...$', CR, LF

.CODE
start:
    MOV AX, @data
    MOV DS, AX

main_menu:
    ; Limpa a tela AGORA, no início de cada ciclo do menu
    MOV AH, 00h
    MOV AL, 03h
    INT 10h

    MOV DX, OFFSET MSG_MENU
    CALL print_string_proc

    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc ; ; Nova linha após ler a opção do menu

    MOV AL, [input_buffer + 2]
    SUB AL, '0'
    MOV AH, 0
    MOV BX, AX

    CALL newline_proc
    CALL newline_proc

    CMP BX, 1
    JE create_recipe_jmp
    CMP BX, 2
    JE view_recipes_jmp ; <<< Pula para a rotina de Visualizar (agora pede ID)
    CMP BX, 3
    JE edit_recipe_jmp
    CMP BX, 4
    JE delete_recipe_jmp
    CMP BX, 5
    JE exit_program_jmp

    ; Opção inválida
    MOV DX, OFFSET MSG_INVALID
    CALL print_string_proc
    CALL newline_proc
    MOV DX, OFFSET MSG_PRESS_ENTER
    CALL print_string_proc
    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc

    JMP main_menu ; Volta para o menu principal (que limpará a tela para a próxima exibição do menu)

create_recipe_jmp: JMP create_recipe_proc
view_recipes_jmp: JMP view_recipes_proc
edit_recipe_jmp: JMP edit_recipe_proc
delete_recipe_jmp: JMP delete_recipe_proc
exit_program_jmp: JMP exit_program_proc


print_string_proc PROC NEAR
    PUSH DX
    PUSH AX
    MOV AH, 09h
    INT 21h
    POP AX
    POP DX
    RET
print_string_proc ENDP

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

read_string_proc PROC NEAR
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH AX

    MOV AH, 0Ah
    INT 21h

    MOV SI, DX
    MOV BL, [SI + 1]
    MOV BH, 0

    MOV SI, DX
    ADD SI, BX
    ADD SI, 2
    MOV BYTE PTR [SI], '$'

    POP AX
    POP DI
    POP SI
    POP CX
    POP BX
    RET
read_string_proc ENDP

; Esta rotina lê e converte o número real digitado pelo usuário (para editar/apagar/visualizar por ID).
read_number_proc PROC NEAR

    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH DX

    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc

    MOV SI, OFFSET input_buffer + 2
    MOV BL, [input_buffer + 1]
    MOV BH, 0

    MOV AX, 0 ; Resultado numérico (16-bit), inicializa com 0

read_num_loop:
    CMP BX, 0
    JE read_num_done

    MOV CL, [SI]
    CMP CL, '$'
    JE read_num_done
    CMP CL, CR
    JE read_num_done
    CMP CL, LF
    JE read_num_done

    ; Verifica se é um dígito válido ('0'-'9')
    CMP CL, '0'
    JL invalid_digit_num
    CMP CL, '9'
    JG invalid_digit_num

    SUB CL, '0'     ; Converte caractere de dígito para valor numérico
    MOV CH, 0

    Push CX
    Mov CX, 10
    Mul CX
    Pop CX

    Add AX, CX

    INC SI
    DEC BX
    JMP read_num_loop

invalid_digit_num:
    ; Em caso de dígito inválido, zera o resultado e sai do loop.
    MOV AX, 0 ; Indica erro ou entrada inválida
    JMP read_num_done

read_num_done:

    POP DX
    POP DI
    POP SI
    POP CX
    POP BX
    RET
read_number_proc ENDP

print_number_proc PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH BP

    MOV CX, 0
    MOV BP, OFFSET number_buffer + 9
    MOV BYTE PTR [BP + 1], '$'

    CMP AX, 0
    JE print_zero_num

print_num_loop:
    MOV DX, 0
    MOV BX, 10
    DIV BX

    PUSH DX
    INC CX

    CMP AX, 0
    JNE print_num_loop

print_num_print_loop:
    POP DX
    ADD DL, '0'

    MOV BYTE PTR [BP], DL ; Armazena o dígito no buffer (crescendo para trás)
    DEC BP                ; Move para a posição anterior no buffer

    LOOP print_num_print_loop

    ; Imprime o buffer a partir de BP+1 (onde o primeiro dígito foi colocado)
    MOV DX, BP + 1
    CALL print_string_proc

    JMP print_num_done_print

print_zero_num: # Label separado para imprimir 0
    MOV BYTE PTR [BP], '0'
    MOV DX, BP
    CALL print_string_proc

print_num_done_print:
    POP BP
    POP SI
    POP DX
    POP CX
    POP BX
    RET
print_number_proc ENDP


; --- ROTINAS DE RECEITA ---

; create_recipe_proc: Cria uma nova receita
create_recipe_proc PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV AX, recipe_count
    CMP AX, MAX_RECIPES
    JGE buffer_full_msg

    MOV AX, recipe_count
    MOV BX, MAX_RECIPE_SIZE
    MUL BX
    MOV DI, AX
    ADD DI, OFFSET RECIPE_BUFFER

    ; --- Lê Título ---
    MOV DX, OFFSET MSG_ENTER_TITLE
    CALL print_string_proc
    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc ; ; Nova linha após ler o título

    MOV BL, [input_buffer + 1]
    MOV BH, 0
    MOV SI, OFFSET input_buffer + 2

    MOV CX, MAX_TITLE_SIZE
    CMP BX, CX
    JLE title_length_ok
    MOV BL, CL
title_length_ok:
    MOV BYTE PTR [DI], BL

    PUSH BX ; Salva novo tamanho do título (truncado)
    PUSH SI
    PUSH DI
    MOV AX, DI
    INC AX
    MOV DI, AX
    MOV CX, MAX_TITLE_SIZE
    MOV AL, 0
    PUSH DS
    POP ES
    CLD
    REP STOSB
    POP DI
    POP SI
    POP BX

    INC DI
    MOV CX, BX
    CLD
    REP MOVSB


    ; --- Lê Conteúdo ---
    MOV AX, recipe_count
    MOV BX, MAX_RECIPE_SIZE
    MUL BX
    MOV DI, AX
    ADD DI, OFFSET RECIPE_BUFFER
    ADD DI, 1 + MAX_TITLE_SIZE


    MOV DX, OFFSET MSG_ENTER_CONTENT
    CALL print_string_proc
    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc

    MOV BL, [input_buffer + 1]
    MOV BH, 0
    MOV SI, OFFSET input_buffer + 2

    MOV CX, MAX_CONTENT_SIZE
    CMP BX, CX
    JLE content_length_ok
    MOV BL, CL
content_length_ok:
    MOV BYTE PTR [DI], BL

    INC DI
    MOV CX, BX
    CLD
    REP MOVSB

    ; --- Exibe ID atribuído (MOSTRANDO ID REAL) ---

    ; Incrementa o contador de receitas
    INC recipe_count ; Este é o ID REAL (1-based) da receita recém-criada

    ; *** Imprime mensagem de sucesso ***
    MOV DX, OFFSET MSG_RECIPE_SAVED
    CALL print_string_proc

    MOV DX, OFFSET MSG_ASSIGNED_ID
    CALL print_string_proc

    MOV AX, recipe_count
    CALL print_number_proc
    CALL newline_proc

    JMP create_recipe_done

create_recipe_done: # << Label para onde o JMP vai

    MOV DX, OFFSET MSG_PRESS_ENTER
    CALL print_string_proc

    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc


    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    JMP main_menu_ret # Retorna para o menu principal

buffer_full_msg: # << Label para buffer cheio
    MOV DX, OFFSET MSG_BUFFER_FULL
    CALL print_string_proc
    JMP create_recipe_done # Vai para a mensagem "Pressione Enter"

create_recipe_proc ENDP


view_recipes_proc PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Verifica se há receitas
    MOV AX, recipe_count
    CMP AX, 0

    MOV DX, OFFSET MSG_SELECT_VIEW ; Pede o ID para visualizar
    CALL print_string_proc

    CALL read_number_proc
    CALL newline_proc

    MOV BX, AX

    CMP BX, 1
    JL invalid_id_msg_view ; Se ID < 1, inválido
    MOV AX, recipe_count
    CMP BX, AX
    JG invalid_id_msg_view

    ; Se ID é válido, calcula o endereço da receita
    ; ID (1-based) -> Índice (0-based) -> Offset
    DEC BX
    MOV AX, BX
    MOV CX, MAX_RECIPE_SIZE
    MUL CX
    MOV SI, AX
    ADD SI, OFFSET RECIPE_BUFFER

    ; Salva o ID digitado (BX + 1 antes de DEC) ou pega AX antes de DEC.
    ; O ID digitado original está em AX vindo de read_number_proc antes de ser movido para BX e decrementado.
    MOV AX, BX
    INC AX
    PUSH AX


    MOV DX, OFFSET MSG_HEADER_RECIPE_ID
    CALL print_string_proc
    POP AX ; Pega o ID real salvo para imprimir
    CALL print_number_proc ; Imprime o número do ID
    MOV DX, OFFSET MSG_HEADER_END
    CALL print_string_proc


    CALL newline_proc
    MOV DX, OFFSET MSG_RECIPE_ID
    CALL print_string_proc
    CALL print_number_proc ; Imprime o número do ID
    MOV DX, OFFSET MSG_COLON_SPACE
    CALL print_string_proc
    CALL newline_proc


    MOV BL, [SI]
    MOV BH, 0
    MOV CX, BX
    PUSH SI
    ADD SI, 1 
    MOV DX, OFFSET MSG_TITLE 
    CALL print_string_proc
print_single_title_loop:
    CMP CX, 0
    JE print_single_title_done
    MOV DL, [SI]
    MOV AH, 02h
    INT 21h
    INC SI
    DEC CX
    JMP print_single_title_loop
print_single_title_done:
    POP SI
    CALL newline_proc

    MOV DI, SI
    ADD DI, 1 + MAX_TITLE_SIZE
    MOV BL, [DI]
    MOV BH, 0
    MOV CX, BX
    INC DI
    MOV SI, DI
    MOV DX, OFFSET MSG_CONTENT
    CALL print_string_proc
print_single_content_loop:
    CMP CX, 0
    JE print_single_content_done
    MOV DL, [SI]
    MOV AH, 02h
    INT 21h
    INC SI
    DEC CX
    JMP print_single_content_loop
print_single_content_done:
    CALL newline_proc
    CALL newline_proc

    JMP view_recipes_done_proc

invalid_id_msg_view:
    MOV DX, OFFSET MSG_INVALID_ID ; "ID invalido."
    CALL print_string_proc

view_recipes_done_proc: # Label final da rotina de visualização
    MOV DX, OFFSET MSG_PRESS_ENTER
    CALL print_string_proc
    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    JMP main_menu_ret ; Return to menu

view_recipes_proc ENDP


; edit_recipe_proc: Edita uma receita existente
edit_recipe_proc PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES ; Usado por STOSB para preencher memória (ES:DI)

    ; Verifica se há receitas
    MOV AX, recipe_count
    CMP AX, 0
    JE no_recipes_msg_edit

    MOV DX, OFFSET MSG_SELECT_EDIT ; Mensagem original (pede ID real)
    CALL print_string_proc
    CALL read_number_proc
    CALL newline_proc

    MOV BX, AX ; BX = ID REAL digitado pelo usuário

    ; Valida o ID REAL (1 <= ID <= recipe_count)
    CMP BX, 1
    JL invalid_id_msg_edit
    MOV AX, recipe_count
    CMP BX, AX ; Compara o ID digitado com o recipe_count total
    JG invalid_id_msg_edit

    ; Calcula o endereço da receita a ser editada usando o ID REAL (BX)
    DEC BX
    MOV AX, BX
    MOV CX, MAX_RECIPE_SIZE
    MUL CX
    MOV DI, AX
    ADD DI, OFFSET RECIPE_BUFFER
                
                
    ; --- Edita Título ---
    MOV DX, OFFSET MSG_EDIT_TITLE
    CALL print_string_proc
    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc ; ; Nova linha após ler o NOVO título

    ; Obtém novo tamanho do título e endereço de origem dos dados
    MOV BL, [input_buffer + 1]
    MOV BH, 0
    MOV SI, OFFSET input_buffer + 2 

    ; Armazena novo tamanho do título (truncado se necessário)
    MOV CX, MAX_TITLE_SIZE
    MOV AX, BX
    MOV BX, 0
    MOV BL, [input_buffer + 1]
    MOV CX, MAX_TITLE_SIZE
    CMP BX, CX
    JLE new_title_length_ok
    MOV BL, CL 
new_title_length_ok:
    MOV BYTE PTR [DI], BL ; Armazena novo tamanho do título no offset 0 do slot
    MOV BX, AX

    ; Limpa o espaço antigo do título (dentro do tamanho fixo permitido) antes de copiar
    PUSH BX ; Salva índice da receita
    PUSH SI
    PUSH DI
    MOV AX, DI
    INC AX
    MOV DI, AX
    MOV CX, MAX_TITLE_SIZE
    MOV AL, 0
    PUSH DS
    POP ES
    CLD
    REP STOSB
    POP DI
    POP SI
    POP BX

    MOV CX, 0
    MOV CL, BYTE PTR [DI]
    INC DI
    CLD
    REP MOVSB


    ; --- Edita Conteúdo ---
    MOV AX, BX 
    MOV CX, MAX_RECIPE_SIZE
    MUL CX
    MOV DI, AX
    ADD DI, OFFSET RECIPE_BUFFER
    ADD DI, 1 + MAX_TITLE_SIZE

    MOV DX, OFFSET MSG_EDIT_CONTENT
    CALL print_string_proc
    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc ; ; Nova linha após ler o NOVO conteúdo

    MOV BL, [input_buffer + 1]
    MOV BH, 0
    MOV SI, OFFSET input_buffer + 2

    ; Armazena novo tamanho do conteúdo (truncado se necessário)
    MOV CX, MAX_CONTENT_SIZE
    MOV AX, BX
    MOV BX, 0
    MOV BL, [input_buffer + 1]
    MOV CX, MAX_CONTENT_SIZE
    CMP BX, CX
    JLE new_content_length_ok_2
    MOV BL, CL
new_content_length_ok_2:
    MOV BYTE PTR [DI], BL
    MOV BX, AX

    PUSH BX
    PUSH SI
    PUSH DI
    MOV AX, DI
    INC AX
    MOV DI, AX
    MOV CX, MAX_CONTENT_SIZE
    MOV AL, 0
    PUSH DS
    POP ES
    CLD
    REP STOSB
    POP DI
    POP SI
    POP BX


    MOV CX, 0
    MOV CL, BYTE PTR [DI]
    INC DI
    CLD
    REP MOVSB


    MOV DX, OFFSET MSG_RECIPE_EDITED
    CALL print_string_proc
    JMP edit_recipe_done

no_recipes_msg_edit:
    MOV DX, OFFSET MSG_NO_RECIPES
    CALL print_string_proc
    JMP edit_recipe_done

invalid_id_msg_edit:
    MOV DX, OFFSET MSG_INVALID_ID
    CALL print_string_proc
    JMP edit_recipe_done

edit_recipe_done:
    ; Pausa após editar receita
    MOV DX, OFFSET MSG_PRESS_ENTER ; Mensagem "Pressione Enter..."
    CALL print_string_proc

    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc

    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    JMP main_menu_ret # Retorna para o menu principal

edit_recipe_proc ENDP


; delete_recipe_proc: Apaga uma receita existente
delete_recipe_proc PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES ; Usado por MOVSB e STOSB

    ; Verifica se há receitas
    MOV AX, recipe_count
    CMP AX, 0
    JE no_recipes_msg_delete

    MOV DX, OFFSET MSG_SELECT_DELETE ; Mensagem original (pede ID real)
    CALL print_string_proc
    CALL read_number_proc
    CALL newline_proc ; Nova linha após ler o ID

    MOV BX, AX

    ; Valida o ID REAL (1 <= ID <= recipe_count)
    CMP BX, 1
    JL invalid_id_msg_delete
    MOV AX, recipe_count
    CMP BX, AX
    JG invalid_id_msg_delete

    DEC BX

    MOV AX, BX
    INC AX
    MOV CX, MAX_RECIPE_SIZE 
    MUL CX                      
    MOV SI, AX             
    ADD SI, OFFSET RECIPE_BUFFER

    MOV AX, BX             
    MOV CX, MAX_RECIPE_SIZE 
    MUL CX                
    MOV DI, AX   
    ADD DI, OFFSET RECIPE_BUFFER

    MOV AX, recipe_count
    DEC AX        
    SUB AX, BX 
    MOV CX, MAX_RECIPE_SIZE 
    MUL CX                
    MOV CX, AX  

    PUSH DS
    POP ES

    CLD
    REP MOVSB

    ; Decrementa o contador de receitas
    DEC recipe_count

    MOV AX, recipe_count
    MOV BX, MAX_RECIPE_SIZE
    MUL BX              
    MOV DI, AX           
    ADD DI, OFFSET RECIPE_BUFFER 

    MOV CX, MAX_RECIPE_SIZE
    MOV AL, 0 
    PUSH DS
    POP ES
    CLD 
    REP STOSB 

    MOV DX, OFFSET MSG_RECIPE_DELETED
    CALL print_string_proc
    JMP delete_recipe_done

no_recipes_msg_delete:
    MOV DX, OFFSET MSG_NO_RECIPES
    CALL print_string_proc
    JMP delete_recipe_done

invalid_id_msg_delete:
    MOV DX, OFFSET MSG_INVALID_ID
    CALL print_string_proc
    JMP delete_recipe_done

delete_recipe_done:
    MOV DX, OFFSET MSG_PRESS_ENTER ; Mensagem "Pressione Enter..."
    CALL print_string_proc

    MOV DX, OFFSET input_buffer
    CALL read_string_proc
    CALL newline_proc

    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    JMP main_menu_ret # Retorna para o menu principal

exit_program_proc PROC NEAR
    MOV AH, 4Ch ; Função de terminação do programa
    MOV AL, 0   ; Código de retorno 0 (sucesso)
    INT 21h
exit_program_proc ENDP

; Label para retornar ao menu principal após a execução de uma rotina
main_menu_ret:
    JMP main_menu

END start