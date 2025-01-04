#include "value_calc.h"
#include "value.h"

#include <math.h>
#include <stdio.h>

val_t *addition(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  switch (a->val_type) {
  case STRING_TYPE:
    switch (b->val_type) {
    case STRING_TYPE: {
      string *res = string_copy(a->val.strval);
      string_append_string(res, b->val.strval);
      return value_create(res, STRING_TYPE);
    }
    case INT_TYPE: {
      char buffer[32];
      snprintf(buffer, sizeof(buffer), "%d", b->val.intval);
      string *res = string_copy(a->val.strval);
      string_append_chars(res, buffer);
      return value_create(res, STRING_TYPE);
    }
    case FLOAT_TYPE: {
      char buffer[64];
      snprintf(buffer, sizeof(buffer), "%f", b->val.floatval);
      string *res = string_copy(a->val.strval);
      string_append_chars(res, buffer);
      return value_create(res, STRING_TYPE);
    }
    default:
      break;
    }
    break;
  case INT_TYPE:
    switch (b->val_type) {
    case STRING_TYPE: {
      char buffer[32];
      snprintf(buffer, sizeof(buffer), "%d", a->val.intval);
      string *res = string_create(buffer);
      string_append_string(res, b->val.strval);
      return value_create(res, STRING_TYPE);
    }
    case INT_TYPE: {
      int res = a->val.intval + b->val.intval;
      return value_create(&res, INT_TYPE);
    }
    case FLOAT_TYPE: {
      double res = a->val.intval + b->val.floatval;
      return value_create(&res, FLOAT_TYPE);
    }
    default:
      break;
    }
    break;
  case FLOAT_TYPE:
    switch (b->val_type) {
    case STRING_TYPE: {
      char buffer[64];
      snprintf(buffer, sizeof(buffer), "%f", a->val.floatval);
      string *res = string_create(buffer);
      string_append_string(res, b->val.strval);
      return value_create(res, STRING_TYPE);
    }
    case INT_TYPE: {
      double res = a->val.floatval + b->val.intval;
      return value_create(&res, FLOAT_TYPE);
    }
    case FLOAT_TYPE: {
      double res = a->val.floatval + b->val.floatval;
      return value_create(&res, FLOAT_TYPE);
    }
    default:
      break;
    }
    break;
  default:
    break;
  }

  printf("Unsupported add operation between types %d and %d\n", a->val_type,
         b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *subtraction(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) -
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
      return value_create(&res, FLOAT_TYPE);
    } else {
      int res = a->val.intval - b->val.intval;
      return value_create(&res, INT_TYPE);
    }
  }
  printf("Unsupported sub operation between types %d and %d\n", a->val_type,
         b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *multiplication(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) *
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
      return value_create(&res, FLOAT_TYPE);
    } else {
      int res = a->val.intval * b->val.intval;
      return value_create(&res, INT_TYPE);
    }
  }
  printf("Unsupported mul operation between types %d and %d\n", a->val_type,
         b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *division(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {
    if ((b->val_type == INT_TYPE && b->val.intval == 0) ||
        (b->val_type == FLOAT_TYPE && b->val.floatval == 0.0)) {
      printf("Error: Division by zero\n");
      return value_create(NULL, NULL_TYPE);
    }

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) /
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
      return value_create(&res, FLOAT_TYPE);
    } else {
      int res = a->val.intval / b->val.intval;
      return value_create(&res, INT_TYPE);
    }
  }
  printf("Unsupported div operation between types %d and %d\n", a->val_type,
         b->val_type);
  return value_create(NULL, NULL_TYPE);
}

// TODO maybe also for string like operations?
val_t *less_than(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) <
               (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
    return value_create(&res, BOOL_TYPE);
  }
  printf("Unsupported less_than operation between types %d and %d\n",
         a->val_type, b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *greater_than(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) >
               (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
    return value_create(&res, BOOL_TYPE);
  }
  printf("Unsupported greater_than operation between types %d and %d\n",
         a->val_type, b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *less_equal_than(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) <=
               (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
    return value_create(&res, BOOL_TYPE);
  }
  printf("Unsupported less_equal_than operation between types %d and %d\n",
         a->val_type, b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *greater_equal_than(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) >=
               (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
    return value_create(&res, BOOL_TYPE);
  }
  printf("Unsupported greater_equal_than operation between types %d and %d\n",
         a->val_type, b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *equal(val_t *a, val_t *b) {
  // TODO strcmp, null, ...
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) ==
               (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
    return value_create(&res, BOOL_TYPE);
  }
  printf("Unsupported equal operation between types %d and %d\n", a->val_type,
         b->val_type);
  return value_create(NULL, NULL_TYPE);
}

val_t *power(val_t *a, val_t *b) {
  if (!a || !b)
    return value_create(NULL, NULL_TYPE);

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res =
          pow((a->val_type == INT_TYPE ? a->val.intval : a->val.floatval),
              (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval));
      return value_create(&res, FLOAT_TYPE);
    } else {
      int res = (int)pow(a->val.intval, b->val.intval);
      return value_create(&res, INT_TYPE);
    }
  }
  printf("Unsupported power operation between types %d and %d\n", a->val_type,
         b->val_type);
  return value_create(NULL, NULL_TYPE);
}
