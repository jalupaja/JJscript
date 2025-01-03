#include "value.h"
#include "string.h"

void free_value(val_t *val) {
  if (val->val_type == STRING_TYPE) {
    // free string as it will be overwritten
    string_free(val->val.strval);
  }
  free(val);
}

val_t *create_value(void *new_val, val_type_t val_type) {
  val_t *val = (val_t *)malloc(sizeof(val_t));
  switch (val_type) {
  case INT_TYPE:
    val->val.intval = *(int *)new_val;
    break;
  case FLOAT_TYPE:
    val->val.floatval = *(double *)new_val;
    break;
  case BOOL_TYPE:
    val->val.boolval = *(bool *)new_val;
    break;
  case NULL_TYPE:
    break;
  case STRING_TYPE:
    val->val.strval = (string *)new_val;
    break;
  default:
    break;
  }
  val->val_type = val_type;

  return val;
}
