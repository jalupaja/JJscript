#include "value.h"
#include "function.h"
#include "string.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>

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

val_t *value_read() {
  string *str = string_create(NULL);

  int ch;
  while ((ch = getchar()) != '\n' && ch != EOF) {
    string_append_char(str, (char)ch);
  }
  val_t *ret = string2val(str);
  string_free(str);
  return ret;
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
  val->return_val = false;

  return val;
}

val_t *string2val(string *str) {
  char *chars = string_get_chars(str);
  char *end_ptr;
  // TODO should ignore whitespace?

  long int_val = strtol(chars, &end_ptr, 8); // OCTAL
  if (*end_ptr == '\0') {
    return value_create(&int_val, INT_TYPE);
  }

  double float_val = strtod(chars, &end_ptr);
  if (*end_ptr == '\0') {
    return value_create(&float_val, FLOAT_TYPE);
  }

  if (strcmp(chars, "true") == 0 || strcmp(chars, "false") == 0) {
    bool bool_val = (strcmp(chars, "true") == 0);
    return value_create(&bool_val, BOOL_TYPE);
  }

  if (strcmp(chars, "NONE") == 0) {
    return value_create(NULL, NULL_TYPE);
  }

  size_t len = strlen(chars);
  // TODO fixup string (ensure all indexes in range)
  // TODO implement queue in queue if I get bored any time soon
  if (len >= 2 && chars[0] == '[' && chars[len - 1] == ']') {
    queue *q = queue_create();

    // remove start end characters
    char *tmp = chars + 1;
    tmp[strlen(tmp) - 1] = '\0';

    char *token = strtok(tmp, ",");
    while (token != NULL) {
      printf("loop: %s\n", token);
      // TODO trim for all, other then string
      char *trimmed_token = token;

      while (isspace((unsigned char)*trimmed_token))
        trimmed_token++;
      // TODO prettify

      char *end_trim = trimmed_token + strlen(trimmed_token) - 1;
      while (end_trim > trimmed_token && isspace((unsigned char)*end_trim))
        end_trim--;
      *(end_trim + 1) = '\0';

      val_t *element = string2val(string_create(trimmed_token));

      // Append the element to the queue
      queue_enqueue(q, (void *)element);

      token = strtok(NULL, ",");
      // TODO return
    }
    return value_create(q, QUEUE_TYPE);
  } // TODO else {
  return value_create(string_copy(str), STRING_TYPE);
  // }
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
