#include "value_calc.h"
#include "queue.h"
#include "string.h"
#include "value.h"

#include <math.h>
#include <stdbool.h>
#include <stdio.h>

#define DEBUG 0

void print_error(const char *);

int value_cmp(val_t *a, val_t *b) {
  if (!a || !b)
    return 0;

  if (a->val_type == STRING_TYPE || b->val_type == STRING_TYPE) {
    return string_cmp(val2string(a), val2string(b));
  } else if (a->val_type == QUEUE_TYPE && b->val_type == QUEUE_TYPE) {
    size_t len_diff = queue_len(a->val.qval) - queue_len(b->val.qval);
    if (len_diff != 0)
      return len_diff;
    return queue_cmp(a->val.qval, b->val.qval);
  } else if (a->val_type == QUEUE_TYPE || b->val_type == QUEUE_TYPE) {
    return 0;
  } else if (a->val_type == BOOL_TYPE || b->val_type == BOOL_TYPE) {
    return val2bool(a) - val2bool(b);
  }

  switch (a->val_type) {
  case INT_TYPE:
    switch (b->val_type) {
    case INT_TYPE:
      return a->val.intval - b->val.intval;
    case FLOAT_TYPE: {
      double res = a->val.intval - b->val.floatval;
      return (res > 0) - (res < 0);
    }
    default:
      break;
    }
    break;

  case FLOAT_TYPE:
    switch (b->val_type) {
    case INT_TYPE: {
      double res = a->val.floatval - b->val.intval;
      return (res > 0) - (res < 0);
    }
    case FLOAT_TYPE: {
      double res = a->val.floatval - b->val.floatval;
      return (res > 0) - (res < 0);
    }
    default:
      break;
    }
    break;
  default:
    break;
  }
  print_error("Unsupported comparison");
  return 0;
}

val_t *addition(val_t *a, val_t *b) {
  if (DEBUG)
    printf("ADDING: %s + %s\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)));

  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  if (a->val_type == QUEUE_TYPE && b->val_type == QUEUE_TYPE) {
    queue *new = queue_copy(a->val.qval);
    queue_append(new, b->val.qval);
    return value_create(new, QUEUE_TYPE);
  } else if (a->val_type == QUEUE_TYPE) {
    queue *new = queue_copy(a->val.qval);
    queue_enqueue(new, value_copy(b));
    return value_create(new, QUEUE_TYPE);
  } else if (b->val_type == QUEUE_TYPE) {
    queue *new = queue_copy(b->val.qval);
    queue_enqueue_at(new, value_copy(a), 0);
    return value_create(new, QUEUE_TYPE);
  } else if (b->val_type == STRING_TYPE) {
    string *new = val2string(a);
    string_append_string(new, b->val.strval);
    return value_create(new, STRING_TYPE);
  } else if (a->val_type == STRING_TYPE) {
    string *new = string_copy(a->val.strval);
    string *append = val2string(b);
    string_append_string(new, append);
    string_free(append);
    return value_create(new, STRING_TYPE);
  }

  if (a->val_type == BOOL_TYPE && b->val_type == BOOL_TYPE) {
    bool res = a->val.boolval || b->val.boolval;
    return value_create(&res, BOOL_TYPE);
  }

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE ||
       a->val_type == BOOL_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE ||
       b->val_type == BOOL_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = val2float(a) + val2float(b);
      return value_create(&res, FLOAT_TYPE);
    } else {
      long res = val2int(a) + val2int(b);
      return value_create(&res, INT_TYPE);
    }
  }

  print_error("Unsupported addition");
  return value_create(NULL, NULL_TYPE);
}

val_t *subtraction(val_t *a, val_t *b) {
  if (DEBUG)
    printf("SUBBING: %s - %s\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)));

  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  if (a->val_type == QUEUE_TYPE && b->val_type == QUEUE_TYPE) {
    queue *new = queue_create();
    queue *rem = b->val.qval;
    size_t q_len = queue_len(rem);
    val_t *new_elem;

    // return all in a but not in b -> remove all b from a
    for (size_t i = 0; i < q_len; i++) {
      new_elem = queue_at(rem, i);
      if (!value_in(new_elem, a)) {
        queue_enqueue(new, new_elem);
      }
    }

    return value_create(new, QUEUE_TYPE);
  } else if (a->val_type == QUEUE_TYPE) {
    queue *new = queue_copy(a->val.qval);
    val_t *elem;
    for (int i = 0; i < val2int(b); i++) {
      elem = queue_dequeue_at(new, queue_len(new) - 1);
      // can probably expect the queue to have val_t
      value_free(elem);
    }
    return value_create(new, QUEUE_TYPE);
  } else if (b->val_type == QUEUE_TYPE) {
    queue *new = queue_copy(b->val.qval);
    val_t *elem;
    for (int i = 0; i < val2int(a); i++) {
      elem = queue_dequeue(new);
      // can probably expect the queue to have val_t
      value_free(elem);
    }
    return value_create(new, QUEUE_TYPE);
  } else if (a->val_type == STRING_TYPE && b->val_type == STRING_TYPE) {
    return value_create(string_remove_chars(a->val.strval, b->val.strval),
                        STRING_TYPE);
  } else if (a->val_type == STRING_TYPE) {
    string *new = string_copy(a->val.strval);
    string_remove_chars_from_end(new, val2int(b));
    return value_create(new, STRING_TYPE);
  } else if (b->val_type == STRING_TYPE) {
    string *new = string_copy(b->val.strval);
    string_remove_chars_from_beginning(new, val2int(a));
    return value_create(new, STRING_TYPE);
  }

  if (a->val_type == BOOL_TYPE && b->val_type == BOOL_TYPE) {
    bool res = (bool)(a->val.boolval - b->val.boolval);
    return value_create(&res, BOOL_TYPE);
  }

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE ||
       a->val_type == BOOL_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE ||
       b->val_type == BOOL_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = val2float(a) - val2float(b);
      return value_create(&res, FLOAT_TYPE);
    } else {
      long res = val2int(a) - val2int(b);
      return value_create(&res, INT_TYPE);
    }
  }

  print_error("Unsupported subtraction");
  return value_create(NULL, NULL_TYPE);
}

val_t *multiplication(val_t *a, val_t *b) {
  if (DEBUG)
    printf("MULTIPLYING: %s * %s\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)));

  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  if (a->val_type == QUEUE_TYPE && b->val_type == QUEUE_TYPE) {
    return value_create(queue_interleave(a->val.qval, b->val.qval), QUEUE_TYPE);
  } else if (a->val_type == QUEUE_TYPE) {
    queue *new = queue_copy(a->val.qval);
    queue_repeat(new, val2int(b));
    return value_create(new, QUEUE_TYPE);
  } else if (b->val_type == QUEUE_TYPE) {
    queue *new = queue_copy(b->val.qval);
    queue_repeat(new, val2int(a));
    return value_create(new, QUEUE_TYPE);
  } else if (a->val_type == STRING_TYPE && b->val_type == STRING_TYPE) {
    return value_create(string_interleave(a->val.strval, b->val.strval),
                        STRING_TYPE);
  } else if (a->val_type == STRING_TYPE) {
    string *new = string_copy(a->val.strval);
    string_repeat(new, val2int(b));
    return value_create(new, STRING_TYPE);
  } else if (b->val_type == STRING_TYPE) {
    string *new = string_copy(b->val.strval);
    string_repeat(new, val2int(a));
    return value_create(new, STRING_TYPE);
  }

  if (a->val_type == BOOL_TYPE && b->val_type == BOOL_TYPE) {
    bool res = a->val.boolval && b->val.boolval;
    return value_create(&res, BOOL_TYPE);
  }

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE ||
       a->val_type == BOOL_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE ||
       b->val_type == BOOL_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = val2float(a) * val2float(b);
      return value_create(&res, FLOAT_TYPE);
    } else {
      long res = val2int(a) * val2int(b);
      return value_create(&res, INT_TYPE);
    }
  }

  print_error("Unsupported multiplication");
  return value_create(NULL, NULL_TYPE);
}

val_t *division(val_t *a, val_t *b) {
  if (DEBUG)
    printf("DIVIDING: %s / %s\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)));

  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  if (a->val_type == QUEUE_TYPE || b->val_type == QUEUE_TYPE ||
      (b->val_type == STRING_TYPE && a->val_type != STRING_TYPE)) {
    return subtraction(a, b);
  } else if (a->val_type == STRING_TYPE) {
    return value_create(string_split(a->val.strval, val2string(b)),
                        STRING_TYPE);
  }

  if (a->val_type == BOOL_TYPE && b->val_type == BOOL_TYPE) {
    bool res = a->val.boolval || b->val.boolval;
    return value_create(&res, BOOL_TYPE);
  }

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE ||
       a->val_type == BOOL_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE ||
       b->val_type == BOOL_TYPE)) {

    double b_val = val2float(b);
    if (b_val == 0.0) {
      print_error("Division by 0");
      return value_create(NULL, NULL_TYPE);
    }
    double res = val2float(a) / b_val;
    return value_create(&res, FLOAT_TYPE);
  }

  print_error("Unsupported division");
  return value_create(NULL, NULL_TYPE);
}

val_t *power(val_t *a, val_t *b) {
  if (DEBUG)
    printf("POWER: %s ^ %s\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)));

  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  // TODO
  if (a->val_type == QUEUE_TYPE && b->val_type == QUEUE_TYPE) {
  } else if (a->val_type == QUEUE_TYPE) {
  } else if (b->val_type == QUEUE_TYPE) {
  } else if (a->val_type == STRING_TYPE) {
  } else if (b->val_type == STRING_TYPE) {
  }

  if (a->val_type == BOOL_TYPE && b->val_type == BOOL_TYPE) {
    bool res = a->val.boolval ^ b->val.boolval;
    return value_create(&res, BOOL_TYPE);
  }

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE ||
       a->val_type == BOOL_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE ||
       b->val_type == BOOL_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = pow(val2float(a), val2float(b));
      return value_create(&res, FLOAT_TYPE);
    } else {
      long res = (long)pow(val2int(a), val2int(b));
      return value_create(&res, INT_TYPE);
    }
  }

  print_error("Unsupported power operation");
  return value_create(NULL, NULL_TYPE);
}

val_t *modulo(val_t *a, val_t *b) {
  if (DEBUG)
    printf("MODULOing: %s %% %s\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)));

  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  // TODO
  if (a->val_type == QUEUE_TYPE && b->val_type == QUEUE_TYPE) {
  } else if (a->val_type == QUEUE_TYPE) {
  } else if (b->val_type == QUEUE_TYPE) {
  } else if (a->val_type == STRING_TYPE && b->val_type == STRING_TYPE) {
  } else if (a->val_type == STRING_TYPE) {
  } else if (b->val_type == STRING_TYPE) {
  }

  if (a->val_type == BOOL_TYPE && b->val_type == BOOL_TYPE) {
    bool res = a->val.boolval ^ b->val.boolval;
    return value_create(&res, BOOL_TYPE);
  }

  if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE ||
       a->val_type == BOOL_TYPE) &&
      (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE ||
       b->val_type == BOOL_TYPE)) {

    if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
      double res = (double)(val2int(a) % val2int(b));
      return value_create(&res, FLOAT_TYPE);
    } else {
      long res = val2int(a) % val2int(b);
      return value_create(&res, INT_TYPE);
    }
  }

  print_error("Unsupported modulo");
  return value_create(NULL, NULL_TYPE);
}

val_t *AND(val_t *a, val_t *b) {
  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = val2bool(a) && val2bool(b);
  if (DEBUG)
    printf("CMP: %s & %s -> %d\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)), res);
  return value_create(&res, BOOL_TYPE);
}

val_t *OR(val_t *a, val_t *b) {
  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = val2bool(a) || val2bool(b);
  if (DEBUG)
    printf("CMP: %s | %s -> %d\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)), res);
  return value_create(&res, BOOL_TYPE);
}

val_t *NOT(val_t *a) {
  if (!a || a->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = !val2bool(a);
  if (DEBUG)
    printf("CMP: !%s -> %d\n", string_get_chars(val2string(a)), res);
  return value_create(&res, BOOL_TYPE);
}

val_t *less_than(val_t *a, val_t *b) {
  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = value_cmp(a, b) < 0;
  if (DEBUG)
    printf("CMP: %s < %s -> %d\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)), res);
  return value_create(&res, BOOL_TYPE);
}

val_t *greater_than(val_t *a, val_t *b) {
  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = value_cmp(a, b) > 0;
  if (DEBUG)
    printf("CMP: %s > %s -> %d\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)), res);
  return value_create(&res, BOOL_TYPE);
}

val_t *less_equal_than(val_t *a, val_t *b) {
  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = value_cmp(a, b) <= 0;
  if (DEBUG)
    printf("CMP: %s <= %s -> %d\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)), res);
  return value_create(&res, BOOL_TYPE);
}

val_t *greater_equal_than(val_t *a, val_t *b) {
  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = value_cmp(a, b) >= 0;
  if (DEBUG)
    printf("CMP: %s >= %s -> %d\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)), res);
  return value_create(&res, BOOL_TYPE);
}

bool value_in(val_t *a, val_t *b) {
  if (DEBUG)
    printf("VALUE_IN: ");
  if (!a || !b)
    return false;
  if (DEBUG)
    printf("%s + %s\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)));

  if (a->val_type == QUEUE_TYPE && b->val_type == QUEUE_TYPE) {
    // all in a are also in b
    bool res;
    queue *q = a->val.qval;
    size_t q_len = queue_len(q);

    for (size_t i = 0; i < q_len; i++) {
      res = value_in(queue_at(q, i), b);
      if (!res)
        return false;
    }
    return true;
  } else if (a->val_type == QUEUE_TYPE) {
    return false;
  } else if (b->val_type == QUEUE_TYPE) {
    bool res;
    queue *q = b->val.qval;
    size_t q_len = queue_len(q);

    for (size_t i = 0; i < q_len; i++) {
      res = value_cmp(a, queue_at(q, i)) == 0;
      if (res)
        return true;
    }
    return false;
  } else if (b->val_type == STRING_TYPE) {
    return string_in(val2string(a), b->val.strval);
  } else if (a->val_type == STRING_TYPE) {
    return false;
  }

  val_t *eq = equal(a, b);
  bool ret = eq->val.boolval;
  value_free(eq);
  return ret;
}

val_t *equal(val_t *a, val_t *b) {
  if (!a || !b || a->val_type == NULL_TYPE || b->val_type == NULL_TYPE)
    return value_create(NULL, NULL_TYPE);

  bool res = value_cmp(a, b) == 0;
  if (DEBUG)
    printf("CMP: %s == %s -> %d\n", string_get_chars(val2string(a)),
           string_get_chars(val2string(b)), res);
  return value_create(&res, BOOL_TYPE);
}
