%{
/*
 * Desempeño del analizador sintáctico:
 *   Bison genera un parser LALR(1) — mira 1 token adelante.
 *   Complejidad: O(n) en el número de tokens de entrada.
 *   La tabla de análisis se construye en tiempo de compilación,
 *   por lo que el análisis en tiempo de ejecución es lineal.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

extern int  yylex(void);
extern int  yylineno;
extern char line_buf[2048];
void        yyerror(const char *msg);

/* Contador de operaciones para medir desempeño */
static long operaciones = 0;

static void imprimir_resultado(int v) {
    /* line_buf ya tiene el salto de línea al final */
    printf("%s", line_buf);
    printf("%s\n\n", v ? "true" : "false");
    line_buf[0] = '\0';
}
%}

/* ─── Tipos semánticos ─────────────────────────────────────── */
%union {
    double dval;   /* números y resultados aritméticos */
    int    ival;   /* resultados booleanos (0 o 1)     */
}

/* ─── Tokens ────────────────────────────────────────────────── */
%token <ival> BOOL_LIT
%token <dval> NUMBER
%token AND OR NOT
%token EQ NEQ GT LT GTE LTE
%token PLUS MINUS TIMES DIV
%token LPAREN RPAREN
%token NL

/* ─── Tipos de los no terminales ────────────────────────────── */
%type <ival> expr_bool
%type <dval> expr_num

/* ─── Precedencia (de menor a mayor) ───────────────────────── */
%left  OR
%left  AND
%right NOT
%left  EQ NEQ
%left  LT GT LTE GTE
%left  PLUS MINUS
%left  TIMES DIV
%right UMINUS   /* menos unario */

%%

/* 
   GRAMÁTICA
*/

programa
    : /* vacío */
    | programa linea
    ;

linea
    : NL                        { line_buf[0] = '\0'; }
    | expr_bool NL              { imprimir_resultado($1); }
    | expr_num  NL              { printf("%s", line_buf); printf("%s\n\n", ($1 != 0) ? "true" : "false"); line_buf[0] = '\0'; }
    | error NL                  { printf("Error procesando: %s\n", line_buf); line_buf[0] = '\0'; yyerrok; }
    ;

/* ── Expresiones booleanas ─────────────────────────────────── */
expr_bool
    : BOOL_LIT
        { $$ = $1; operaciones++; }

    | expr_bool AND expr_bool
        { $$ = $1 && $3; operaciones++; }

    | expr_bool OR expr_bool
        { $$ = $1 || $3; operaciones++; }

    | NOT expr_bool
        { $$ = !$2; operaciones++; }

    /* ── Comparaciones (retornan booleano) ── */
    | expr_num EQ  expr_num     { $$ = (fabs($1 - $3) < 1e-9); operaciones++; }
    | expr_num NEQ expr_num     { $$ = (fabs($1 - $3) >= 1e-9); operaciones++; }
    | expr_num GT  expr_num     { $$ = ($1 >  $3); operaciones++; }
    | expr_num LT  expr_num     { $$ = ($1 <  $3); operaciones++; }
    | expr_num GTE expr_num     { $$ = ($1 >= $3); operaciones++; }
    | expr_num LTE expr_num     { $$ = ($1 <= $3); operaciones++; }

    | LPAREN expr_bool RPAREN   { $$ = $2; }
    ;

/* ── Expresiones aritméticas (retornan número) ─────────────── */
expr_num
    : NUMBER
        { $$ = $1; operaciones++; }

    | expr_num PLUS  expr_num   { $$ = $1 + $3; operaciones++; }
    | expr_num MINUS expr_num   { $$ = $1 - $3; operaciones++; }
    | expr_num TIMES expr_num   { $$ = $1 * $3; operaciones++; }
    | expr_num DIV   expr_num
        {
            if ($3 == 0) {
                $$ = 0;
            } else {
                $$ = $1 / $3;
            }
            operaciones++;
        }

    | MINUS expr_num %prec UMINUS   { $$ = -$2; operaciones++; }
    | LPAREN expr_num RPAREN        { $$ = $2; }
    ;

%%

/* 
   FUNCIÓN DE ERROR
*/
void yyerror(const char *msg) {
    fprintf(stderr, "[Error Sintáctico] línea %d: %s\n", yylineno, msg);
}


/* 
   FUNCIÓN PRINCIPAL
*/
int main(void) {
    FILE *archivo = fopen("pruebas.txt", "r");
    if (!archivo) {
        fprintf(stderr, "Error: No se pudo abrir el archivo 'pruebas.txt'\n");
        return 1;
    }

    extern FILE *yyin;
    yyin = archivo;
    extern void yyrestart(FILE *);
    yyrestart(archivo);

    /* Lanzamos el análisis sintáctico que procesará el archivo completo */
    yyparse();

    fclose(archivo);
    return 0;
}