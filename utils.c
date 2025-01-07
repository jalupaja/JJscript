#include "utils.h"

#include <stdio.h>

size_t min(size_t a, size_t b) {
  if (a <= b) {
    return a;
  } else {
    return b;
  }
}

size_t max(size_t a, size_t b) {
  if (a >= b) {
    return a;
  } else {
    return b;
  }
}
