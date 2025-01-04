#include "value.h"
#include "string.h"
#include <stdio.h> // TODO rem

void value_free(val_t *val) {
  if (val->val_type == STRING_TYPE) {
    // free string as it will be overwritten
    string_free(val->val.strval);
  }
  free(val);
}

val_t *value_create(void *new_val, val_type_t val_type) {
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
  case QUEUE_TYPE:
    val->val.qval = (queue *)new_val;
    break;
  case FUNCTION_TYPE:
    val->val.funval = (fun_t *)new_val;
    break;
  default:
    break;
  }
  val->val_type = val_type;

  return val;
}

void value_print(val_t *val) {
  if (!val) {
    printf("NULL");
    return;
  }
  switch (val->val_type) {
  case INT_TYPE:
    // Apparently printf can't print negative numbers
    if (val->val.intval < 0)
      printf("-%o", -val->val.intval); // OCTAL
    else
      printf("%o", val->val.intval); // OCTAL
    break;
  case FLOAT_TYPE:
    printf("%f", val->val.floatval);
    break;
  case STRING_TYPE:
    printf("%s", string_get_chars(val->val.strval));
    break;
  case BOOL_TYPE:
    printf("%s", val->val.boolval ? "true" : "false");
    break;
  case NULL_TYPE:
    printf("NULL");
    break;
  case FUNCTION_TYPE:
    printf("FUNCTION");
    break;
  default:
    printf("Unknown type");
    break;
  }
}

int val_true(val_t *val) {
  switch (val->val_type) {
  case INT_TYPE:
    return val->val.intval != 0;
    break;
  case FLOAT_TYPE:
    return val->val.floatval != 0.0;
    break;
  case BOOL_TYPE:
    return val->val.boolval;
    break;
  case NULL_TYPE:
    return false;
    break;
  case STRING_TYPE:
    string *str = val->val.strval;
    return str == NULL || string_char_at(str, 0) == '\0';
    break;
  default:
    printf("Unsupported value type(val_true)");
    break;
  }
  return false;
}
