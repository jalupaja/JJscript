#ifndef FUNCTION_H
#define FUNCTION_H

#include "queue.h"
#include "string.h"
#include "value.h"

#include <stdlib.h>

typedef struct fun_t fun_t;
typedef struct ast_t ast_t;

struct fun_t {
  int test;
  queue *params;
  ast_t *body;
};

fun_t *function_create(queue *params, ast_t *body);
void function_free(fun_t *fun);
val_t *function_call(string *id, queue *args);

#endif // FUNCTION_H
