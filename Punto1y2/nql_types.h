/*
 * nql_types.h — Tipos compartidos entre NQL.l y NQL.y
 *
 * Este header define las estructuras de datos que necesitan
 * tanto el lexer (Flex) como el parser (Bison).
 */

#ifndef NQL_TYPES_H
#define NQL_TYPES_H

#include <string.h>
#include <stdlib.h>

/* ── Límites ────────────────────────────────────────────────────── */
#define MAX_COLLECTIONS  10
#define MAX_KEY_LEN     128
#define MAX_STR_LEN     512

/* ── Tipos de valor ─────────────────────────────────────────────── */
typedef enum {
    VAL_NUMBER = 0,
    VAL_STRING,
    VAL_BOOL,
    VAL_NULL
} ValType;

/* ── Valor genérico ─────────────────────────────────────────────── */
typedef struct {
    ValType type;
    double  num;
    char    str[MAX_STR_LEN];
    int     bval;
} Value;

/* ── Par clave-valor dentro de un documento ─────────────────────── */
typedef struct KVNode {
    char          key[MAX_KEY_LEN];
    Value         val;
    struct KVNode *next;
} KVNode;

/* ── Documento (registro) ───────────────────────────────────────── */
typedef struct DocNode {
    KVNode         *fields;
    struct DocNode *next;
} DocNode;

/* ── Colección ──────────────────────────────────────────────────── */
typedef struct {
    char     name[MAX_KEY_LEN];
    DocNode *head;
    int      count;
} Collection;

/* ── Operadores de comparación ──────────────────────────────────── */
typedef enum {
    OP_EQ,
    OP_NEQ,
    OP_GT,
    OP_LT,
    OP_GTE,
    OP_LTE
} Operator;

/* ── Condición de filtro WHERE ──────────────────────────────────── */
typedef struct {
    int      active;
    char     key[MAX_KEY_LEN];
    Operator op;
    Value    val;
} Condition;

/* ── Asignación SET ─────────────────────────────────────────────── */
typedef struct {
    char  key[MAX_KEY_LEN];
    Value val;
} Assignment;

/* ── Lista de pares para CREATE ─────────────────────────────────── */
typedef struct PairList {
    char            key[MAX_KEY_LEN];
    Value           val;
    struct PairList *next;
} PairList;

#endif /* NQL_TYPES_H */
