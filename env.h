#ifndef ENV_H
#define ENV_H

#include "queue.h"
#include "string.h"
#include "value.h"
#include <stdlib.h>

typedef struct _env_t {
  queue_t *vars;
  struct _env_t *parent;
} env_t;

void env_push();
void pop_env();
var_t *env_search(string *id);
void env_save(string *id, val_t *val);

#endif // ENV_H
