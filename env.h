#ifndef ENV_H
#define ENV_H

#include "queue.h"
#include "string.h"
#include <stdlib.h>

typedef struct env_t env_t;
typedef struct val_t val_t;
typedef struct env_var_t env_var_t;

struct env_t {
  queue *vars;
  struct env_t *parent;
};

struct env_var_t {
  string *id;
  val_t *val;
};

void env_push();
void env_pop();
val_t *env_search(val_t *id);
void env_save(val_t *id, val_t *val);

#endif // ENV_H
