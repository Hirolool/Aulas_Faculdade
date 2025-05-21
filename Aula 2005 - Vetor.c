
#include <stdio.h>
#include <stdlib.h>


void mostrarVetorOrdenado(int vetor[], int tamanho) {
    printf("\nVetor ordenado em ordem crescente:\n");
    for (int i = 0; i < tamanho; i++) {
        printf("vetor[%d] = %d\n", i, vetor[i]);
    }
}

int main()
{
    // Declarar e preencher vetor com 5 inteiros
    int vetor[5] = {12, 5, 20, 8, 15};

    printf("Valores do vetor:\n");
    // Acessar valores do vetor com índice
    for (int i = 0; i < 5; i++) {
        printf("vetor[%d] = %d\n", i, vetor[i]);
    }

    // Encontrar o maior valor do vetor
    // 0 = 12;
    // 1 = 5;
    // 2 = 20;
    // 3 = 8;
    // 4 = 15.
    int maior = vetor[0];
    for (int i = 1; i < 5; i++) {
        if (vetor[i] > maior) {
            maior = vetor[i];
        }
    }
    printf("\nMaior valor do vetor: %d\n", maior);

    printf("\n");

    // Inserir os valores com scanf
    printf("Digite 5 números inteiros:\n");
    for (int i = 0; i < 5; i++) {
        printf("Valor %d: ", i + 1);
        scanf("%d", &vetor[i]);
    }

    // Ordenar o vetor (Bubble Sort)
    for (int i = 0; i < 5 - 1; i++) {
        for (int j = 0; j < 5 - 1 - i; j++) {
            if (vetor[j] > vetor[j + 1]) {
                // Troca os valores
                int temp = vetor[j];
                vetor[j] = vetor[j + 1];
                vetor[j + 1] = temp;
            }
        }
    }

    // Mostrar vetor ordenado
    mostrarVetorOrdenado(vetor, 5);

    return 0;
}
