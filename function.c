#include "function.h"
#include "ast.h"
#include "env.h"
#include "queue.h"
#include "value.h"

#include <stdio.h>

fun_t *function_create(queue *params, ast_t *body) {
  fun_t *fun = (fun_t *)malloc(sizeof(fun_t));
  fun->params = params;
  fun->body = body;
  return fun;
}

void function_free(fun_t *fun) {
#ifndef NO_FREE
  if (!fun)
    return;
  queue_free(fun->params);
  ast_free(fun->body);
  free(fun);
#else
  fprintf(stderr, "function_free() (DISABLED)\n");
#endif
}
