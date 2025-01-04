#include "ast.h"
#include "value.h"

#include <stdio.h>

void ast_free_outer(ast_t *t) {
  string_free(t->id);
  value_free(t->val);
}

void ast_free(ast_t *t) {
  if (!t)
    return;
  string_free(t->id);
  value_free(t->val);
  for (int i = 0; i < MC; i++) {
    ast_free(t->c[i]);
  }
}

ast_t *node0(int type) {
  ast_t *ret = calloc(sizeof *ret, 1);
  ret->type = type;

  return ret;
}

ast_t *node1(int type, ast_t *c1) {
  ast_t *ret = node0(type);
  ret->c[0] = c1;

  return ret;
}

ast_t *node2(int type, ast_t *c1, ast_t *c2) {
  ast_t *ret = node1(type, c1);
  ret->c[1] = c2;

  return ret;
}

ast_t *node3(int type, ast_t *c1, ast_t *c2, ast_t *c3) {
  ast_t *ret = node2(type, c1, c2);
  ret->c[2] = c3;

  return ret;
}

void ast_print(ast_t *t) {
  if (!t)
    return;
  printf(" ( %d", t->type);
  for (int i = 0; i < MC; i++) {
    if (t->val) {
      printf("/");
      value_print(t->val);
    }
    printf(" ");
    ast_print(t->c[i]);
  }
  printf(" ) ");
}
