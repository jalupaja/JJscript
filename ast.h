#ifndef AST_H
#define AST_H

#include "queue.h"
#include "string.h"
#include "value.h"

#define MC 3

typedef struct _ast_t {
  int type;
  string *id;
  value *val;
  struct _ast_t *c[MC];
} ast_t;

void ast_free_outer(ast_t *t);

void ast_free(ast_t *t);

ast_t *node0(int type);

ast_t *node1(int type, ast_t *c1);

ast_t *node2(int type, ast_t *c1, ast_t *c2);

ast_t *node3(int type, ast_t *c1, ast_t *c2, ast_t *c3);

void print_ast(ast_t *t);

#endif // AST_H
