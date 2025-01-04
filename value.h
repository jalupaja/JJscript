#ifndef VALUE_H
#define VALUE_H

#include "queue.h"
#include "string.h"
#include <stdbool.h>
#include <stdlib.h>

typedef struct fun_t fun_t;
typedef struct val_t val_t;
typedef struct var_t var_t;
typedef struct fun_t fun_t;
typedef struct emb_t emb_t;

typedef enum {
  INT_TYPE,
  FLOAT_TYPE,
  BOOL_TYPE,
  NULL_TYPE,
  STRING_TYPE,
  QUEUE_TYPE,
  FUNCTION_TYPE,
  EMBED_TYPE, // TODO implement in functions
} val_type_t;

union data_value {
  int intval;
  double floatval;
  bool boolval;
  string *strval;
  fun_t *funval;
  emb_t *embval;
  queue *qval;
};

struct val_t {
  union data_value val;
  val_type_t val_type;
};

// TODO remove??? / move + rename?
struct var_t {
  string *id;
  val_t *val;
};

val_t *value_create(void *new_val, val_type_t val_type);
void value_free(val_t *val);
void value_print(val_t *val);
bool val2bool(val_t *val);
string *val2string(val_t *val);

#endif // VALUE_H
