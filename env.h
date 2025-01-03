#ifndef ENV_H
#define ENV_H

#include "queue.h"
#include "string.h"
#include "value.h"
#include <stdlib.h>

typedef struct _env_t {
  queue *vars;
  struct _env_t *parent;
} env_t;

void env_push();
void pop_env();
void env_save(string *id, value *val);
var *env_search(string *id);

#endif // ENV_H
