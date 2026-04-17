/**
 * NQL.g4 — Gramática ANTLR4 para NQL (NoSQL Query Language)
 *
 * Lenguaje CRUD con palabras clave en español para bases de datos
 * no relacionales en memoria.
 *
 * Operaciones:
 *   CREATE  → nuevo   <col> { k:v, ... }
 *   READ    → buscar  <col> [donde <cond>]
 *   UPDATE  → actualizar <col> asignar k=v [donde <cond>]
 *   DELETE  → eliminar   <col> [donde <cond>]
 */
grammar NQL;

/* ═══════════════════════════════════════════════════════════════════
   REGLAS DE PARSER
   ═══════════════════════════════════════════════════════════════════ */

/** Punto de entrada */
programa
    : sentencia* EOF
    ;

sentencia
    : createOp
    | readOp
    | updateOp
    | deleteOp
    ;

/* ── CREATE ───────────────────────────────────────────────────────── */
createOp
    : NUEVO id LBRACE pares RBRACE
    ;

/* ── READ ─────────────────────────────────────────────────────────── */
readOp
    : BUSCAR id condicionOpt
    ;

/* ── UPDATE ───────────────────────────────────────────────────────── */
updateOp
    : ACTUALIZAR id ASIGNAR asignacion condicionOpt
    ;

/* ── DELETE ───────────────────────────────────────────────────────── */
deleteOp
    : ELIMINAR id condicionOpt
    ;

/* ── Condición WHERE opcional ─────────────────────────────────────── */
condicionOpt
    : DONDE condicion   # conCondicion
    |                   # sinCondicion
    ;

condicion
    : id operador valor
    ;

/* ── Asignación SET ───────────────────────────────────────────────── */
asignacion
    : id EQ valor
    ;

/* ── Lista de pares clave-valor ───────────────────────────────────── */
pares
    : par (COMMA par)*
    ;

par
    : id COLON valor
    ;

/* ── Valor ────────────────────────────────────────────────────────── */
valor
    : NUMBER        # valorNumero
    | STRING_LIT    # valorCadena
    | BOOLEAN       # valorBooleano
    | NUL           # valorNulo
    ;

/* ── Operador de comparación ──────────────────────────────────────── */
operador
    : EQ    # opIgual
    | NEQ   # opDistinto
    | GT    # opMayor
    | LT    # opMenor
    | GTE   # opMayorIgual
    | LTE   # opMenorIgual
    ;

/* ── Identificador ────────────────────────────────────────────────── */
id
    : IDENT
    ;

/* ═══════════════════════════════════════════════════════════════════
   REGLAS DE LÉXICO (TOKENS)
   ═══════════════════════════════════════════════════════════════════ */

/* Palabras reservadas */
NUEVO       : 'nuevo'      ;
BUSCAR      : 'buscar'     ;
ACTUALIZAR  : 'actualizar' ;
ELIMINAR    : 'eliminar'   ;
DONDE       : 'donde'      ;
ASIGNAR     : 'asignar'    ;

/* Literales booleanos y nulo */
BOOLEAN     : 'true' | 'false' ;
NUL         : 'null'           ;

/* Operadores de comparación */
NEQ         : '!=' ;
GTE         : '>=' ;
LTE         : '<=' ;
GT          : '>'  ;
LT          : '<'  ;
EQ          : '='  ;

/* Puntuación */
LBRACE      : '{' ;
RBRACE      : '}' ;
COLON       : ':' ;
COMMA       : ',' ;

/* Números (enteros y decimales) */
NUMBER
    : [0-9]+ ('.' [0-9]+)?
    ;

/* Cadenas con comillas dobles */
STRING_LIT
    : '"' (~["\r\n])* '"'
    ;

/* Identificadores */
IDENT
    : [a-zA-Z] [a-zA-Z0-9_]*
    ;

/* Comentarios de línea → se descartan */
COMMENT
    : '#' ~[\r\n]* -> skip
    ;

/* Espacios en blanco → se descartan */
WS
    : [ \t\r\n]+ -> skip
    ;
