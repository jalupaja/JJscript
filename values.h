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

struct _value {
  union data_value val;
  var_type val_type;
};
typedef struct _value value;

struct _var {
  string *id;
  value *val;
};
typedef struct _var var;

#endif // VALUES_H
