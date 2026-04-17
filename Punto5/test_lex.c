#include <stdio.h>
extern int yylex();
extern FILE *yyin;
extern void yyrestart(FILE *);
int main() {
    yyin = fopen("pruebas.txt", "r");
    yyrestart(yyin);
    int t;
    while ((t = yylex()) != 0) {
        printf("Token: %d\n", t);
    }
    return 0;
}
