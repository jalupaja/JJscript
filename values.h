#ifndef VALUES_H
#define VALUES_H

#include "string.h"
#include <stdbool.h>
#include <stdlib.h>

enum _var_type { INT_TYPE, FLOAT_TYPE, BOOL_TYPE, NULL_TYPE, STRING_TYPE };
typedef enum _var_type var_type;

union data_value {
  int intval;
  double floatval;
  bool boolval;
  string *strval;
};

typedef struct {
  union data_value val;
  var_type val_type;
} value;

typedef struct {
  string *id;
  value *val;
} var;

void free_value(value *val);

#endif // VALUES_H
