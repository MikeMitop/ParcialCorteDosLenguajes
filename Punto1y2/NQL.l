%{
/*
 * NQL.l — Analizador Léxico para NQL (NoSQL Query Language)
 * Herramienta: Flex
 *
 * Tokens del lenguaje en español:
 *   nuevo, buscar, actualizar, eliminar, donde, asignar
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "nql_types.h"   /* tipos compartidos (antes del tab.h) */
#include "NQL.tab.h"     /* generado por Bison */

int line_num = 1;
%}

/* Opciones */
%option noyywrap
%option yylineno

/* Definiciones de patrones */
LETTER      [a-zA-Z]
DIGIT       [0-9]
ID          {LETTER}({LETTER}|{DIGIT}|"_")*
INTEGER     {DIGIT}+
FLOAT       {DIGIT}+"."{DIGIT}+
STRING      \"([^\"\n])*\"
WHITESPACE  [ \t\r]+

%%

    /* ── Palabras reservadas ── */
"nuevo"       { return NUEVO;     }
"buscar"      { return BUSCAR;    }
"actualizar"  { return ACTUALIZAR;}
"eliminar"    { return ELIMINAR;  }
"donde"       { return DONDE;     }
"asignar"     { return ASIGNAR;   }

    /* ── Literales booleanos y nulos ── */
"true"        { yylval.bval = 1; return BOOLEAN; }
"false"       { yylval.bval = 0; return BOOLEAN; }
"null"        { return NUL;       }

    /* ── Números ── */
{FLOAT}       { yylval.dval = atof(yytext); return NUMBER; }
{INTEGER}     { yylval.dval = atof(yytext); return NUMBER; }

    /* ── Cadenas ── */
{STRING}      {
                  /* Copia el texto sin las comillas */
                  int len = strlen(yytext) - 2;
                  yylval.sval = (char *)malloc(len + 1);
                  strncpy(yylval.sval, yytext + 1, len);
                  yylval.sval[len] = '\0';
                  return STRING_LIT;
              }

    /* ── Operadores de comparación ── */
"!="          { return NEQ; }
">="          { return GTE; }
"<="          { return LTE; }
">"           { return GT;  }
"<"           { return LT;  }
"="           { return EQ;  }

    /* ── Puntuación ── */
"{"           { return LBRACE; }
"}"           { return RBRACE; }
":"           { return COLON;  }
","           { return COMMA;  }

    /* ── Comentarios de línea (#) ── */
"#"[^\n]*     { /* ignorar comentarios */ }

    /* ── Saltos de línea ── */
"\n"          { line_num++; }

    /* ── Espacios en blanco ── */
{WHITESPACE}  { /* ignorar */ }

    /* ── Identificadores (después de palabras reservadas) ── */
{ID}          { yylval.sval = strdup(yytext); return IDENT; }

    /* ── Token desconocido ── */
.             {
                  fprintf(stderr, "[Léxico] Carácter desconocido '%s' en línea %d\n",
                          yytext, line_num);
              }

%%
