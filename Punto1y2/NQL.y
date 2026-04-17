%{
/*
 * NQL.y — Analizador Sintáctico + Intérprete para NQL (NoSQL Query Language)
 * Herramienta: Bison
 *
 * Base de datos en memoria:
 *   - Máx. 10 colecciones activas
 *   - Cada colección: lista dinámica de documentos (mapas clave-valor)
 *
 * Operaciones soportadas:
 *   nuevo <col> { k:v, ... }         → CREATE
 *   buscar <col> [donde <cond>]      → READ
 *   actualizar <col> asignar k=v [donde <cond>]  → UPDATE
 *   eliminar <col> [donde <cond>]    → DELETE
 */

#include <stdio.h>  
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "nql_types.h"   /* Value, Condition, Assignment, PairList, Operator... */

/* ─── Declaraciones del lexer ─────────────────────────────────────── */
extern int  yylex(void);
extern int  yylineno;
extern char *yytext;
void yyerror(const char *msg);

/* Base de datos global */
static Collection db[MAX_COLLECTIONS];
static int        db_size = 0;

/* ═══════════════════════════════════════════════════════════════════
   FUNCIONES AUXILIARES
   ═══════════════════════════════════════════════════════════════════ */

/* Imprime un valor */
static void print_value(const Value *v) {
    switch (v->type) {
        case VAL_NUMBER:
            if (v->num == (long long)v->num)
                printf("%.0f", v->num);
            else
                printf("%g", v->num);
            break;
        case VAL_STRING:  printf("\"%s\"", v->str); break;
        case VAL_BOOL:    printf("%s", v->bval ? "true" : "false"); break;
        case VAL_NULL:    printf("null"); break;
    }
}

/* Imprime un documento */
static void print_doc(DocNode *doc, int idx) {
    printf("  [%d] { ", idx);
    KVNode *kv = doc->fields;
    int first = 1;
    while (kv) {
        if (!first) printf(", ");
        printf("%s: ", kv->key);
        print_value(&kv->val);
        kv = kv->next;
        first = 0;
    }
    printf(" }\n");
}

/* Busca o crea una colección */
static Collection *get_or_create_collection(const char *name) {
    for (int i = 0; i < db_size; i++)
        if (strcmp(db[i].name, name) == 0)
            return &db[i];
    if (db_size >= MAX_COLLECTIONS) {
        fprintf(stderr, "[Error] Límite de %d colecciones alcanzado.\n", MAX_COLLECTIONS);
        return NULL;
    }
    strncpy(db[db_size].name, name, MAX_KEY_LEN - 1);
    db[db_size].head  = NULL;
    db[db_size].count = 0;
    return &db[db_size++];
}

/* Compara dos valores según operador */
static int compare_values(const Value *a, Operator op, const Value *b) {
    /* Comparación numérica */
    if (a->type == VAL_NUMBER && b->type == VAL_NUMBER) {
        switch (op) {
            case OP_EQ:  return fabs(a->num - b->num) < 1e-9;
            case OP_NEQ: return fabs(a->num - b->num) >= 1e-9;
            case OP_GT:  return a->num >  b->num;
            case OP_LT:  return a->num <  b->num;
            case OP_GTE: return a->num >= b->num;
            case OP_LTE: return a->num <= b->num;
        }
    }
    /* Comparación de cadenas */
    if (a->type == VAL_STRING && b->type == VAL_STRING) {
        int cmp = strcmp(a->str, b->str);
        switch (op) {
            case OP_EQ:  return cmp == 0;
            case OP_NEQ: return cmp != 0;
            case OP_GT:  return cmp >  0;
            case OP_LT:  return cmp <  0;
            case OP_GTE: return cmp >= 0;
            case OP_LTE: return cmp <= 0;
        }
    }
    /* Comparación booleana o null — solo igualdad/desigualdad */
    if (a->type == VAL_BOOL && b->type == VAL_BOOL) {
        int eq = (a->bval == b->bval);
        return (op == OP_EQ) ? eq : !eq;
    }
    if (a->type == VAL_NULL && b->type == VAL_NULL)
        return (op == OP_EQ || op == OP_GTE || op == OP_LTE);
    return 0;
}

/* Evalúa si un documento cumple una condición */
static int doc_matches(DocNode *doc, const Condition *cond) {
    if (!cond->active) return 1;
    KVNode *kv = doc->fields;
    while (kv) {
        if (strcmp(kv->key, cond->key) == 0)
            return compare_values(&kv->val, cond->op, &cond->val);
        kv = kv->next;
    }
    return 0; /* clave no encontrada → no cumple */
}

/* Libera lista de pares */
static void free_pair_list(PairList *p) {
    while (p) { PairList *tmp = p; p = p->next; free(tmp); }
}

/* Crea un KVNode nuevo */
static KVNode *new_kvnode(const char *key, const Value *val) {
    KVNode *n = (KVNode *)malloc(sizeof(KVNode));
    strncpy(n->key, key, MAX_KEY_LEN - 1);
    n->val  = *val;
    n->next = NULL;
    return n;
}

/* Crea un documento a partir de una PairList */
static DocNode *pairs_to_doc(PairList *pl) {
    DocNode *doc   = (DocNode *)malloc(sizeof(DocNode));
    doc->fields    = NULL;
    doc->next      = NULL;
    KVNode **tail  = &doc->fields;
    while (pl) {
        *tail  = new_kvnode(pl->key, &pl->val);
        tail   = &(*tail)->next;
        pl     = pl->next;
    }
    return doc;
}

/* ═══════════════════════════════════════════════════════════════════
   OPERACIONES CRUD
   ═══════════════════════════════════════════════════════════════════ */

/* CREATE */
static void op_create(const char *col_name, PairList *pairs) {
    Collection *col = get_or_create_collection(col_name);
    if (!col) return;

    DocNode *doc = pairs_to_doc(pairs);
    /* Inserta al final */
    DocNode **tail = &col->head;
    while (*tail) tail = &(*tail)->next;
    *tail = doc;
    col->count++;

    printf("[CREATE] Documento insertado en '%s'. Total: %d\n", col_name, col->count);
    free_pair_list(pairs);
}

/* READ */
static void op_read(const char *col_name, const Condition *cond) {
    Collection *col = NULL;
    for (int i = 0; i < db_size; i++)
        if (strcmp(db[i].name, col_name) == 0) { col = &db[i]; break; }

    if (!col) {
        printf("[READ] Colección '%s' no encontrada.\n", col_name);
        return;
    }

    printf("[READ] Colección '%s'", col_name);
    if (cond->active) printf(" (con filtro donde %s)", cond->key);
    printf(":\n");

    int found = 0, idx = 0;
    DocNode *doc = col->head;
    while (doc) {
        if (doc_matches(doc, cond)) {
            print_doc(doc, idx);
            found++;
        }
        idx++;
        doc = doc->next;
    }
    if (!found) printf("  (sin resultados)\n");
}

/* UPDATE */
static void op_update(const char *col_name, const Assignment *asgn, const Condition *cond) {
    Collection *col = NULL;
    for (int i = 0; i < db_size; i++)
        if (strcmp(db[i].name, col_name) == 0) { col = &db[i]; break; }

    if (!col) {
        printf("[UPDATE] Colección '%s' no encontrada.\n", col_name);
        return;
    }

    int updated = 0;
    DocNode *doc = col->head;
    while (doc) {
        if (doc_matches(doc, cond)) {
            /* Busca la clave o crea un nuevo campo */
            KVNode *kv = doc->fields;
            int found_key = 0;
            while (kv) {
                if (strcmp(kv->key, asgn->key) == 0) {
                    kv->val = asgn->val;
                    found_key = 1;
                    break;
                }
                kv = kv->next;
            }
            if (!found_key) {
                KVNode *nk  = new_kvnode(asgn->key, &asgn->val);
                nk->next    = doc->fields;
                doc->fields = nk;
            }
            updated++;
        }
        doc = doc->next;
    }
    printf("[UPDATE] %d documento(s) actualizado(s) en '%s'.\n", updated, col_name);
}

/* DELETE */
static void op_delete(const char *col_name, const Condition *cond) {
    Collection *col = NULL;
    for (int i = 0; i < db_size; i++)
        if (strcmp(db[i].name, col_name) == 0) { col = &db[i]; break; }

    if (!col) {
        printf("[DELETE] Colección '%s' no encontrada.\n", col_name);
        return;
    }

    int removed = 0;
    DocNode **ptr = &col->head;
    while (*ptr) {
        if (doc_matches(*ptr, cond)) {
            DocNode *tmp = *ptr;
            *ptr = tmp->next;
            /* Liberar campos */
            KVNode *kv = tmp->fields;
            while (kv) { KVNode *k = kv; kv = kv->next; free(k); }
            free(tmp);
            col->count--;
            removed++;
        } else {
            ptr = &(*ptr)->next;
        }
    }
    printf("[DELETE] %d documento(s) eliminado(s) de '%s'. Restantes: %d\n",
           removed, col_name, col->count);
}

%}

/* Incluir tipos en NQL.tab.h para que Flex los vea */
%code requires {
    #include "nql_types.h"
}

/* ─── Tipos semánticos ─────────────────────────────────────────────── */
%union {
    double      dval;
    char       *sval;
    int         bval;
    Value       vval;
    PairList   *plist;
    Condition   cond;
    Assignment  asgn;
    Operator    op;
}

/* ─── Tokens terminales ────────────────────────────────────────────── */
%token NUEVO BUSCAR ACTUALIZAR ELIMINAR DONDE ASIGNAR
%token LBRACE RBRACE COLON COMMA
%token NUL
%token <dval> NUMBER
%token <sval> STRING_LIT
%token <bval> BOOLEAN
%token <sval> IDENT

/* Operadores */
%token EQ NEQ GT LT GTE LTE

/* ─── Tipos de los no terminales ──────────────────────────────────── */
%type <sval>  id
%type <vval>  valor
%type <plist> pares par
%type <cond>  condicion condicion_opt
%type <asgn>  asignacion
%type <op>    operador

/* ─── Precedencia (más alto = mayor precedencia) ─────────────────── */
%right EQ
%left  GT LT GTE LTE NEQ

%%

/* ═══════════════════════════════════════════════════════════════════
   GRAMÁTICA
   ═══════════════════════════════════════════════════════════════════ */

programa
    : /* vacío */
    | programa sentencia
    ;

sentencia
    : create_op
    | read_op
    | update_op
    | delete_op
    ;

/* ── CREATE ─────────────────────────────────────────────────────── */
create_op
    : NUEVO id LBRACE pares RBRACE
        { op_create($2, $4); free($2); }
    ;

/* ── READ ───────────────────────────────────────────────────────── */
read_op
    : BUSCAR id condicion_opt
        { op_read($2, &$3); free($2); }
    ;

/* ── UPDATE ─────────────────────────────────────────────────────── */
update_op
    : ACTUALIZAR id ASIGNAR asignacion condicion_opt
        { op_update($2, &$4, &$5); free($2); }
    ;

/* ── DELETE ─────────────────────────────────────────────────────── */
delete_op
    : ELIMINAR id condicion_opt
        { op_delete($2, &$3); free($2); }
    ;

/* ── Condición opcional WHERE ───────────────────────────────────── */
condicion_opt
    : /* vacío */
        {
            $$.active = 0;
            $$.key[0] = '\0';
        }
    | DONDE condicion
        { $$ = $2; }
    ;

condicion
    : id operador valor
        {
            $$.active = 1;
            strncpy($$.key, $1, MAX_KEY_LEN - 1);
            $$.op  = $2;
            $$.val = $3;
            free($1);
        }
    ;

/* ── Asignación SET ─────────────────────────────────────────────── */
asignacion
    : id EQ valor
        {
            strncpy($$.key, $1, MAX_KEY_LEN - 1);
            $$.val = $3;
            free($1);
        }
    ;

/* ── Lista de pares clave-valor ─────────────────────────────────── */
pares
    : par
        { $$ = $1; }
    | par COMMA pares
        { $1->next = $3; $$ = $1; }
    ;

par
    : id COLON valor
        {
            PairList *p = (PairList *)malloc(sizeof(PairList));
            strncpy(p->key, $1, MAX_KEY_LEN - 1);
            p->val  = $3;
            p->next = NULL;
            free($1);
            $$ = p;
        }
    ;

/* ── Valor ──────────────────────────────────────────────────────── */
valor
    : NUMBER
        { $$.type = VAL_NUMBER; $$.num = $1; }
    | STRING_LIT
        { $$.type = VAL_STRING; strncpy($$.str, $1, MAX_STR_LEN - 1); free($1); }
    | BOOLEAN
        { $$.type = VAL_BOOL; $$.bval = $1; }
    | NUL
        { $$.type = VAL_NULL; }
    ;

/* ── Operador de comparación ────────────────────────────────────── */
operador
    : EQ   { $$ = OP_EQ;  }
    | NEQ  { $$ = OP_NEQ; }
    | GT   { $$ = OP_GT;  }
    | LT   { $$ = OP_LT;  }
    | GTE  { $$ = OP_GTE; }
    | LTE  { $$ = OP_LTE; }
    ;

/* ── Identificador ──────────────────────────────────────────────── */
id
    : IDENT
        { $$ = $1; }
    ;

%%

/* ═══════════════════════════════════════════════════════════════════
   FUNCIÓN DE ERROR
   ═══════════════════════════════════════════════════════════════════ */
void yyerror(const char *msg) {
    fprintf(stderr, "[Error Sintáctico] Línea %d: %s\n", yylineno, msg);
}

/* ═══════════════════════════════════════════════════════════════════
   FUNCIÓN PRINCIPAL
   ═══════════════════════════════════════════════════════════════════ */
int main(int argc, char *argv[]) {
    extern FILE *yyin;

    printf("════════════════════════════════════════\n");
    printf("   NQL — NoSQL Query Language (Bison)\n");
    printf("════════════════════════════════════════\n\n");

    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror(argv[1]);
            return 1;
        }
        printf("Ejecutando archivo: %s\n\n", argv[1]);
    } else {
        printf("Modo interactivo (Ctrl+D para salir):\n\n");
    }

    int result = yyparse();

    printf("\n════════════════════════════════════════\n");
    printf("   Estado final de la base de datos:\n");
    printf("════════════════════════════════════════\n");
    for (int i = 0; i < db_size; i++) {
        printf("Colección '%s' (%d doc):\n", db[i].name, db[i].count);
        int idx = 0;
        DocNode *doc = db[i].head;
        while (doc) {
            print_doc(doc, idx++);
            doc = doc->next;
        }
    }
    if (db_size == 0) printf("  (vacía)\n");
    printf("════════════════════════════════════════\n");

    if (argc > 1 && yyin) fclose(yyin);
    return result;
}
