#ifndef VALUES_H
#define VALUES_H

#include "string.h"
#include <stdbool.h>
#include <stdlib.h>

typedef enum {
  INT_TYPE,
  FLOAT_TYPE,
  BOOL_TYPE,
  NULL_TYPE,
  STRING_TYPE,
  FUNCTION_TYPE
} var_type_t;

union data_value {
  int intval;
  double floatval;
  bool boolval;
  string *strval;
};

typedef struct {
  union data_value val;
  var_type_t val_type;
} val_t;

typedef struct {
  string *id;
  val_t *val;
} var_t;

void free_value(val_t *val);

#endif // VALUES_H
