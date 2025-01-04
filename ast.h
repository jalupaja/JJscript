#ifndef AST_H
#define AST_H

#include "string.h"

#define MC 3

typedef struct ast_t ast_t;
typedef struct val_t val_t;

struct ast_t {
  int type;
  string *id;
  val_t *val;
  struct ast_t *c[MC];
};

void ast_free_outer(ast_t *t);

void ast_free(ast_t *t);

ast_t *node0(int type);

ast_t *node1(int type, ast_t *c1);

ast_t *node2(int type, ast_t *c1, ast_t *c2);

ast_t *node3(int type, ast_t *c1, ast_t *c2, ast_t *c3);

void ast_print(ast_t *t);

#endif // AST_H
