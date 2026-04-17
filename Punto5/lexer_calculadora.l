%{
/*
 * lexer_calculadora.l — Analizador Léxico para Calculadora Booleana
 * Herramienta: Flex
 *
 * Reconoce:
 *   - Literales booleanos: true, false
 *   - Operadores booleanos: &&, ||, !
 *   - Operadores de comparación: ==, !=, <, >, <=, >=
 *   - Operadores aritméticos: +, -, *, /
 *   - Números enteros y decimales
 *   - Paréntesis
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "calculadora_de_escritorio.tab.h"

char line_buf[2048] = "";

#define YY_USER_ACTION strcat(line_buf, yytext);
%}

%option noyywrap
%option yylineno

DIGIT   [0-9]
INT     {DIGIT}+
FLOAT   {DIGIT}+\.{DIGIT}+
WS      [ \t\r]+

%%

    /* ── Palabras reservadas booleanas ── */
"true"      { yylval.ival = 1; return BOOL_LIT; }
"false"     { yylval.ival = 0; return BOOL_LIT; }

    /* ── Operadores booleanos ── */
"&&"        { return AND; }
"||"        { return OR;  }
"!"         { return NOT; }

    /* ── Operadores de comparación ── */
"=="        { return EQ;  }
"!="        { return NEQ; }
">="        { return GTE; }
"<="        { return LTE; }
">"         { return GT;  }
"<"         { return LT;  }

    /* ── Operadores aritméticos ── */
"+"         { return PLUS;  }
"-"         { return MINUS; }
"*"         { return TIMES; }
"/"         { return DIV;   }

    /* ── Puntuación ── */
"("         { return LPAREN; }
")"         { return RPAREN; }
"\n"        { return NL;     }
";"         { return NL;     }

    /* ── Números ── */
{FLOAT}     { yylval.dval = atof(yytext); return NUMBER; }
{INT}       { yylval.dval = atof(yytext); return NUMBER; }

    /* ── Espacios en blanco ── */
{WS}        { /* ignorar, YY_USER_ACTION se encarga de registrarlos */ }

    /* ── Token desconocido ── */
.           {
                fprintf(stderr, "[Léxico] Token desconocido: '%s' (línea %d)\n",
                        yytext, yylineno);
            }

%%

