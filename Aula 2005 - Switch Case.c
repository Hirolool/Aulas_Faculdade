#include <stdio.h>

int main() {
    int opcao;
    float num1, num2, resultado;

    printf("Digite o primeiro número: ");
    scanf("%f", &num1);

    printf("Digite o segundo número: ");
    scanf("%f", &num2);

    printf("\nEscolha operação:\n");
    printf("1 - Soma\n");
    printf("2 - Subtração\n");
    printf("3 - Multiplicação\n");
    printf("4 - Divisão\n");
    printf("Opção: ");
    scanf("%d", &opcao);

    switch (opcao) { //switch (3) fara com que sempre seja a mesma opção, no caso a multiplicação.
        case 1:
            resultado = num1 + num2;
            printf("Resultado da soma: %.2f\n", resultado);
            break;
        case 2:
            resultado = num1 - num2;
            printf("Resultado da subtração: %.2f\n", resultado);
            break;
        case 3:
            resultado = num1 * num2;
            printf("Resultado da multiplicação: %.2f\n", resultado);
            break;
        case 4:
            if (num2 != 0) {
                resultado = num1 / num2;
                printf("Resultado da divisão: %.2f\n", resultado);
            } else {
                printf("Erro: divisão por zero.\n");
            }
            break;
        default:
            printf("Opção inválida.\n");
            break;
    }

    return 0;
}