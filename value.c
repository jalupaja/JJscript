#include "value.h"
#include "function.h"
#include "string.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>

val_t *value_create(void *new_val, val_type_t val_type) {
  val_t *val = (val_t *)malloc(sizeof(val_t));
  switch (val_type) {
  case INT_TYPE:
    val->val.intval = *(long *)new_val;
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
  val->return_val = false;
  val->indexes = NULL;

  return val;
}

val_t *value_read() {
  string *str = string_create(NULL);

  char ch;
  while ((ch = getchar()) != '\n' && ch != EOF) {
    string_append_char(str, (char)ch);
  }
  val_t *ret = string2val(str);
  string_free(str);
  return ret;
}

val_t *value_copy(val_t *val) {
  if (!val)
    return NULL;

  switch (val->val_type) {
  case INT_TYPE: {
    long res = val->val.intval;
    return value_create(&res, INT_TYPE);
  }
  case FLOAT_TYPE: {
    double res = val->val.floatval;
    return value_create(&res, FLOAT_TYPE);
  }
  case BOOL_TYPE: {
    bool res = val->val.boolval;
    return value_create(&res, BOOL_TYPE);
  }
  case STRING_TYPE:
    return value_create(string_copy(val->val.strval), STRING_TYPE);
  case QUEUE_TYPE:
    return value_create(queue_copy(val->val.qval), QUEUE_TYPE);
  default:
    return value_create(NULL, NULL_TYPE);
  }
}

val_t *string2val(string *str) {
  string *check = string_copy(str);

  string_strip(check);
  char *chars = string_get_chars(check);

  val_t *ret = NULL;

  if (chars[0] == '\0') {
    ret = value_create(string_create(NULL), STRING_TYPE);
  }

  char *end_ptr;

  if (!ret) {
#ifdef USE_OCTAL
    long int_val = strtol(chars, &end_ptr, 8); // OCTAL
#else
    long int_val = strtol(chars, &end_ptr, 0);
#endif
    if (*end_ptr == '\0') {
      ret = value_create(&int_val, INT_TYPE);
    }
  }

  if (!ret) {
    double float_val = strtod(chars, &end_ptr);
    if (*end_ptr == '\0') {
      ret = value_create(&float_val, FLOAT_TYPE);
    }
  }

  if (!ret && (strcmp(chars, "true") == 0 || strcmp(chars, "false") == 0)) {
    bool bool_val = (strcmp(chars, "true") == 0);
    ret = value_create(&bool_val, BOOL_TYPE);
  }

  if (!ret && strcmp(chars, "NONE") == 0) {
    ret = value_create(NULL, NULL_TYPE);
  }

  // TODO implement queue in queue if I get bored any time soon
  // QUEUE should be last (other then STRING) as it changes the check variable
  if (!ret && string_get_char_at(check, 0) == '[' &&
      string_get_char_at(check, -1) == ']') {
    queue *q = queue_create();

    // Create a string instance for manipulation
    string_remove_chars_from_beginning(check, 1);
    string_remove_chars_from_end(check, 1);

    size_t pos = 0;
    string *token;

    while ((token = string_tokenize_chars(check, ",", &pos)) != NULL) {
      string_strip(token);

      val_t *element = string2val(token);

      queue_enqueue(q, (void *)element);

      string_free(token);
    }

    ret = value_create(q, QUEUE_TYPE);
  }

  if (!ret) {
    ret = value_create(string_copy(str), STRING_TYPE);
  }

  string_free(check);

  return ret;
}

string *val2string(val_t *val) {
  if (!val) {
    return string_create("NULL");
  }

  switch (val->val_type) {
  case INT_TYPE: {
    char buf[32];
#ifdef USE_OCTAL
    // Apparently printf can't print negative octal numbers
    if (val->val.intval < 0)
      snprintf(buf, sizeof(buf), "-%o", -(int)val->val.intval); // OCTAL
    else
      snprintf(buf, sizeof(buf), "%o", (int)val->val.intval); // OCTAL
#else
    snprintf(buf, sizeof(buf), "%ld", val->val.intval);
#endif
    return string_create(buf);
  }
  case FLOAT_TYPE: {
    char buf[64];
    snprintf(buf, sizeof(buf), "%.2f", val->val.floatval);
    return string_create(buf);
  }
  case BOOL_TYPE:
    return string_create(val->val.boolval ? "true" : "false");
  case NULL_TYPE:
    return string_create("NONE");
  case STRING_TYPE:
    return string_copy(val->val.strval);
  case QUEUE_TYPE:
    return queue_to_string(val->val.qval, (string * (*)(void *)) val2string);
  case FUNCTION_TYPE:
    return string_create("FUNCTION");
  default:
    return string_create("Unknown type");
  }
}

void value_print(val_t *val) {
  if (!val)
    return;
  string *str = val2string(val);
  printf("%s", string_get_chars(str));
  // TODO should free but crashes when printing a queue?
  // string_free(str);
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
  case STRING_TYPE: {
    string *str = val->val.strval;
    return str == NULL || string_get_char_at(str, 0) == '\0';
  } break;
  default:
    printf("Unsupported value type(val_true)");
    break;
  }
  return false;
}

long val2int(val_t *val) {
  if (val->val_type == INT_TYPE)
    return val->val.intval;
  else if (val->val_type == FLOAT_TYPE)
    return (long)val->val.floatval;
  else if (val->val_type == BOOL_TYPE)
    return (long)val->val.boolval;
  else if (val->val_type == STRING_TYPE)
    return (long)string_get_char_at(val->val.strval, 0);
  else
    printf("VAL2INT: Unsupported val_type %d\n", val->val_type);
  return 0;
}

double val2float(val_t *val) {
  if (val->val_type == INT_TYPE)
    return (double)val->val.intval;
  else if (val->val_type == FLOAT_TYPE)
    return val->val.floatval;
  else if (val->val_type == BOOL_TYPE)
    return (double)val->val.boolval;
  else if (val->val_type == STRING_TYPE)
    return (double)string_get_char_at(val->val.strval, 0);
  else
    printf("VAL2FLOAT: Unsupported val_type %d\n", val->val_type);
  return 0;
}

size_t value_len(val_t *val) {
  if (!val)
    return 0;

  if (val->val_type == INT_TYPE) {
    return 1;
  } else if (val->val_type == FLOAT_TYPE) {
    return 1;
  } else if (val->val_type == BOOL_TYPE) {
    return 1;
  } else if (val->val_type == NULL_TYPE) {
    return 0;
  } else if (val->val_type == STRING_TYPE) {
    return string_len(val->val.strval);
  } else if (val->val_type == QUEUE_TYPE) {
    return queue_len(val->val.qval);
  } else {
    printf("VALUE_LEN: Unsupported val_type %d\n", val->val_type);
  }
  return 0;
}

val_t **value_ptr_at(val_t *val, long n) {
  // a return value of NULL signals that there is no index. This should be
  // interpreted to return the value itself
  val_t **ret = NULL;
  if (!val) {
    val_t *null_val = value_create(NULL, NULL_TYPE);
    ret = &null_val;
  } else if (val->val_type == INT_TYPE) {
  } else if (val->val_type == FLOAT_TYPE) {
  } else if (val->val_type == BOOL_TYPE) {
  } else if (val->val_type == NULL_TYPE) {
    val_t *null_val = value_create(NULL, NULL_TYPE);
    ret = &null_val;
  } else if (val->val_type == STRING_TYPE) {
    char chr = string_get_char_at(val->val.strval, n);
    string *str = string_create(NULL);
    string_append_char(str, chr);
    // TODO change if I want to allow str[0] =...
    val_t *string_val = value_create(str, STRING_TYPE);
    ret = &string_val;
  } else if (val->val_type == QUEUE_TYPE) {
    ret = (val_t **)queue_ptr_at(val->val.qval, n);
  } else {
    printf("VALUE_AT: Unsupported val_type %d\n", val->val_type);
  }
  return ret;
}

val_t *value_at(val_t *val, long n) {
  val_t **res = value_ptr_at(val, n);
  if (res)
    return *res;
  else
    return NULL;
}

void value_free(val_t *val) {
#ifndef NO_FREE
  if (!val)
    return;
  switch (val->val_type) {
  case STRING_TYPE:
    // free string as it will be overwritten
    string_free(val->val.strval);
    break;
  case QUEUE_TYPE:
    queue_free(val->val.qval);
    break;
  case FUNCTION_TYPE:
    function_free(val->val.funval);
    break;
  default:
    break;
  }
  free(val);
#else
  printf("value_free() (DISABLED)\n");
#endif
}
