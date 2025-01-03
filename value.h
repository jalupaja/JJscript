#ifndef VALUE_H
#define VALUE_H

#include "string.h"
#include <stdbool.h>
#include <stdlib.h>

typedef struct val_t val_t;
typedef struct var_t var_t;
typedef struct fun_t fun_t;

typedef enum {
  INT_TYPE,
  FLOAT_TYPE,
  BOOL_TYPE,
  NULL_TYPE,
  STRING_TYPE,
  FUNCTION_TYPE
} val_type_t;

union data_value {
  int intval;
  double floatval;
  bool boolval;
  string *strval;
};

struct val_t {
  union data_value val;
  val_type_t val_type;
};

struct var_t {
  string *id;
  val_t *val;
};

val_t *create_value(void *new_val, val_type_t val_type);
void free_value(val_t *val);

#endif // VALUE_H
