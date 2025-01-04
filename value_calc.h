#ifndef VALUE_CALC_H
#define VALUE_CALC_H

typedef struct val_t val_t;

val_t *addition(val_t *a, val_t *b);

val_t *subtraction(val_t *a, val_t *b);

val_t *multiplication(val_t *a, val_t *b);

val_t *division(val_t *a, val_t *b);

val_t *less_than(val_t *a, val_t *b);

val_t *greater_than(val_t *a, val_t *b);

val_t *less_equal_than(val_t *a, val_t *b);

val_t *greater_equal_than(val_t *a, val_t *b);

val_t *equal(val_t *a, val_t *b);

val_t *power(val_t *a, val_t *b);

#endif // VALUE_CALC_H
