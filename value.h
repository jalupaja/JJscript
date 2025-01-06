#ifndef VALUE_H
#define VALUE_H

#include "queue.h"
#include "string.h"
#include <stdbool.h>
#include <stdlib.h>

typedef struct fun_t fun_t;
typedef struct val_t val_t;
typedef struct fun_t fun_t;

typedef enum {
  INT_TYPE,
  FLOAT_TYPE,
  BOOL_TYPE,
  NULL_TYPE,
  STRING_TYPE,
  QUEUE_TYPE,
  FUNCTION_TYPE,
} val_type_t;

union data_value {
  long intval;
  double floatval;
  bool boolval;
  string *strval;
  fun_t *funval;
  queue *qval;
};

struct val_t {
  union data_value val;
  val_type_t val_type;
  bool return_val;
};

val_t *value_create(void *new_val, val_type_t val_type);
val_t *value_read();
val_t *value_copy(val_t *val);
void value_print(val_t *val);

bool val2bool(val_t *val);
long val2int(val_t *val);
double val2float(val_t *val);
val_t *string2val(string *str);
string *val2string(val_t *val);
size_t value_len(val_t *val);
val_t *value_at(val_t *val, int n);

void value_free(val_t *val);

#endif // VALUE_H
