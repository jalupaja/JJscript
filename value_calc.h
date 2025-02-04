#ifndef VALUE_CALC_H
#define VALUE_CALC_H

#include <stdbool.h>

typedef struct val_t val_t;

val_t *addition(val_t *a, val_t *b);

val_t *subtraction(val_t *a, val_t *b);

val_t *multiplication(val_t *a, val_t *b);

val_t *division(val_t *a, val_t *b);

val_t *power(val_t *a, val_t *b);

val_t *modulo(val_t *a, val_t *b);

val_t *AND(val_t *a, val_t *b);

val_t *OR(val_t *a, val_t *b);

val_t *NOT(val_t *a);

int value_cmp(val_t *a, val_t *b);

val_t *less_than(val_t *a, val_t *b);

val_t *greater_than(val_t *a, val_t *b);

val_t *less_equal_than(val_t *a, val_t *b);

val_t *greater_equal_than(val_t *a, val_t *b);

bool value_in(val_t *a, val_t *b);

val_t *equal(val_t *a, val_t *b);

#endif // VALUE_CALC_H
