#include "value.h"
#include "string.h"

void free_value(val_t *val) {
  if (val->val_type == STRING_TYPE) {
    // free string as it will be overwritten
    string_free(val->val.strval);
  }
  free(val);
}
