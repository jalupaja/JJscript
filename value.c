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
  case EMBED_TYPE:
    val->val.embval = (emb_t *)new_val;
    break;
  default:
    break;
  }
  val->val_type = val_type;

  return val;
}

string *val2string(val_t *val) {
  if (!val) {
    return string_create("NULL");
  }

  switch (val->val_type) {
  case INT_TYPE: {
    char buf[32];
    // Apparently printf can't print negative numbers
    if (val->val.intval < 0)
      snprintf(buf, sizeof(buf), "-%o", -val->val.intval); // OCTAL
    else
      snprintf(buf, sizeof(buf), "%o", val->val.intval); // OCTAL
    return string_create(buf);
  }
  case FLOAT_TYPE: {
    char buf[64];
    snprintf(buf, sizeof(buf), "%f", val->val.floatval);
    return string_create(buf);
  }
  case BOOL_TYPE:
    return string_create(val->val.boolval ? "true" : "false");
  case NULL_TYPE:
    return string_create("NULL");
  case STRING_TYPE:
    return string_copy(val->val.strval);
  case QUEUE_TYPE:
    return queue_to_string(val->val.qval, (string * (*)(void *)) val2string);
  case FUNCTION_TYPE:
    return string_create("FUNCTION");
  case EMBED_TYPE:
    return string_create("EMBEDDING (how are you here)?");
  default:
    return string_create("Unknown type");
  }
}

void value_print(val_t *val) {
  string *str = val2string(val);
  printf("%s", string_get_chars(str));
  string_free(str);
}

bool val2bool(val_t *val) {
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
