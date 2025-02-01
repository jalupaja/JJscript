#include "ast.h"
#include "string.h"
#include "value.h"

#include <stdio.h>

void print_error(const char *);

void ast_free_outer(ast_t *t) {
#ifndef NO_FREE
  if (!t)
    return;
  string_free(t->id);
  t->id = NULL;
  value_free(t->val);
  t->val = NULL;
#else
  fprintf(stderr, "ast_free() (DISABLED)\n");
#endif
}

void ast_free(ast_t *t) {
#ifndef NO_FREE
  if (!t)
    return;
  string_free(t->id);
  t->id = NULL;
  value_free(t->val);
  t->val = NULL;
  for (int i = 0; i < MC; i++) {
    ast_free(t->c[i]);
    t->c[i] = NULL;
  }
#else
  fprintf(stderr, "ast_free() (DISABLED)\n");
#endif
}

ast_t *node0(int type) {
  ast_t *ret = calloc(sizeof *ret, 1);
  ret->type = type;
  ret->id = NULL;
  ret->val = NULL;
  for (int i = 0; i < MC; i++)
    ret->c[i] = NULL;

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

ast_t *node4(int type, ast_t *c1, ast_t *c2, ast_t *c3, ast_t *c4) {
  ast_t *ret = node3(type, c1, c2, c3);
  ret->c[3] = c4;
  return ret;
}

void ast_print(ast_t *t) {
  if (!t)
    return;
  printf(" ( %d", t->type);
  if (t->val) {
    printf("/");
    value_print(t->val);
  }
  for (int i = 0; i < MC; i++) {
    printf(" ");
    ast_print(t->c[i]);
  }
  printf(" ) ");
}
