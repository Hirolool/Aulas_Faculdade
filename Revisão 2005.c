int a = 2;
float b = 3;
float c = 4;
float resultado;
resultado = b*c/a;
printf("resultado: %2f\n", resultado); // 6
resultado = (b*c)/a;
printf("resultado: %2f\n", resultado); // 6
resultado = b+b/a;
printf("resultado: %2f\n", resultado); //4,5

for(int i = 1; i < 4; i++){
    for(int j = 1; j < 4; j++){
        printf(" (%02d, %02d)", i,j);
    }
    printf("\n");
}
// (1,1) - (1,2) - (1,3)
// (2,1) - (2,2) - (2,3)
// (3,1) - (3,2) - (3,3)

//Se i>j = (1,2) - (1,3) - (1,4) - (2,3) - (2,4) - (3,4) e o resto dos números é *.

int x = 0;
do{
    printf("valor de X: %d", x);
    x = x + 2;
    printf("\n");
}while(x < 6);
// 0, 2, 4.

float nota = 6;
float presenca = 60;
if (nota >=6 || presenca >=75){
    printf("ALUNO APROVADO");
}else{
    printf("ALUNO REPROVADO");
}
// "||" significa OU, ou seja o Aluno é aprovado já que uma é Verdadeira e a outra Falsa.