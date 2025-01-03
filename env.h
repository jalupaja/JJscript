#ifndef ENV_H
#define ENV_H

#include "queue.h"
#include "string.h"
#include <stdlib.h>

typedef struct env_t env_t;
typedef struct val_t val_t;
typedef struct var_t var_t;

struct env_t {
  queue *vars;
  struct env_t *parent;
};

void env_push();
void pop_env();
var_t *env_search(string *id);
void env_save(string *id, val_t *val);

#endif // ENV_H
