#include "string.h"
#include "queue.h"
#include "value.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INITIAL_CAPACITY 16

#define DEBUG 0

size_t calc_index(size_t index, size_t length) {
  if (length == 0)
    return 0;
  while (index < 0)
    index += length;
  return index % length;
}

string *string_create(const char *init) {
  string *str = (string *)malloc(sizeof(string));
  if (DEBUG)
    printf("NEW STRING: %s (%p)\n", init, init);
  if (!str) {
    fprintf(stderr, "Memory allocation failed for string struct\n");
    exit(EXIT_FAILURE);
  }
  str->length = init ? strlen(init) : 0;
  str->capacity =
      (str->length + 1 > INITIAL_CAPACITY) ? str->length + 1 : INITIAL_CAPACITY;

  str->data = (char *)malloc(str->capacity);
  if (!str->data) {
    fprintf(stderr, "Memory allocation failed for string data\n");
    free(str);
    exit(EXIT_FAILURE);
  }
  if (DEBUG)
    printf("Allocating string data at %p with capacity %zu - '%s'\n",
           (void *)str->data, str->capacity, init);

  if (init) {
    strcpy(str->data, init);
  } else {
    str->data[0] = '\0';
  }

  return str;
}

string *string_copy(string *str) { return string_create(str->data); }

size_t string_len(string *str) { return str->length; }

bool string_in(string *str1, string *str2) {
  return strstr(str2->data, str1->data) != NULL;
}

queue *string_split(string *str, string *delim) {
  if (!str || !delim)
    return queue_create();

  queue *ret = queue_create();
  string *token;
  size_t pos = 0;

  while ((token = string_tokenize_string(str, delim, &pos)) != NULL) {
    queue_enqueue(ret, value_create(token, STRING_TYPE));
  }

  return ret;
}

void string_append_char(string *str, const char suffix) {
  if (str->length + 1 >= str->capacity) {

    str->capacity *= 2;
    str->data = (char *)realloc(str->data, str->capacity);
  }

  str->data[str->length] = suffix;
  str->length++;
  str->data[str->length] = '\0';
}

void string_append_chars(string *str, const char *suffix) {
  size_t suffix_len = strlen(suffix);

  if (str->length + suffix_len >= str->capacity) {
    while (str->length + suffix_len >= str->capacity) {
      str->capacity *= 2;
    }
    str->data = (char *)realloc(str->data, str->capacity);
  }

  strcat(str->data, suffix);
  str->length += suffix_len;
}

void string_remove_chars_from_beginning(string *str, int amount) {
  str->length = str->length - amount;
  memmove(str->data, str->data + amount, str->length);
  str->data[str->length] = '\0';
}

void string_remove_chars_from_end(string *str, int amount) {
  size_t new_len = str->length - amount;
  if (new_len < 0)
    new_len = 0;
  str->data[new_len] = '\0';
  str->length = new_len;
}

void string_append_string(string *str1, string *str2) {
  if (!str2)
    return;

  if (str1->length + str2->length >= str1->capacity) {
    while (str1->length + str2->length >= str1->capacity) {
      str1->capacity *= 2;
    }
    str1->data = (char *)realloc(str1->data, str1->capacity);
  }

  strcat(str1->data, str2->data);
  str1->length += str2->length;
}

void string_prefix_chars(const char *prefix, string *str) {
  // TODO untested
  size_t prefix_len = strlen(prefix);
  char *old_ptr = NULL;

  if (str->length + prefix_len >= str->capacity) {
    while (str->length + prefix_len >= str->capacity) {
      str->capacity *= 2;
    }
    old_ptr = str->data;
    str->data = (char *)malloc(str->capacity);
  }

  strcpy(str->data, prefix);
  strcat(str->data, old_ptr);
  free(old_ptr);
  str->length += prefix_len;
}

string *string_substring(string *str, size_t start, size_t end) {
  start = calc_index(start, str->length);
  end = calc_index(end, str->length);

  size_t sub_length;

  if (start == end) {
    sub_length = str->length; // Wraparound: full string
  } else if (start < end) {
    sub_length = end - start;
  } else {
    sub_length = str->length - start + end;
  }

  string *sub = (string *)malloc(sizeof(string));
  sub->length = sub_length;
  sub->capacity = sub->length + 1;
  sub->data = (char *)malloc(sub->capacity);

  size_t pos = 0;
  for (size_t i = 0; i < sub_length; i++) {
    sub->data[pos++] = str->data[calc_index(start + i, str->length)];
  }
  sub->data[sub->length] = '\0';

  return sub;
}

void string_repeat(string *str, size_t n) {
  if (n == 0 || str->length == 0) {
    string_clear(str);
    return;
  } else if (n < 0 || n == 1) {
    return;
  }

  size_t new_length = str->length * n;

  if (new_length >= str->capacity) {
    str->capacity = (n * str->length) + 1;
    str->data = (char *)realloc(str->data, str->capacity);
  }

  for (size_t i = 1; i < n; i++) {
    strncpy(str->data + (i * str->length), str->data, str->length);
  }

  str->length = new_length;
  str->data[str->length] = '\0';
}

char string_get_char_at(string *str, size_t index) {
  index = calc_index(index, str->length);
  return str->data[index];
}

char *string_get_chars(string *str) {
  if (str)
    return str->data;
  else
    return NULL;
}

char *string_get_chars_at(string *str, size_t index) {
  index = calc_index(index, str->length);
  return &str->data[index];
}

int string_cmp(string *str1, string *str2) {
  return strcmp(str1->data, str2->data);
}

int string_cmp_chars(string *str1, const char *str2) {
  return strcmp(str1->data, str2);
}

void string_strip(string *str) {
  size_t start = 0;
  while (start < str->length &&
         (str->data[start] == ' ' || str->data[start] == '\t' ||
          str->data[start] == '\n')) {
    start++;
  }

  size_t end = str->length;
  while (end > start &&
         (str->data[end - 1] == ' ' || str->data[end - 1] == '\t' ||
          str->data[end - 1] == '\n')) {
    end--;
  }

  size_t new_len = end - start;
  if (start > 0) {
    memmove(str->data, str->data + start, new_len);
  }
  str->data[new_len] = '\0';
  str->length = new_len;
}

bool string_starts_with(string *str1, string *str2, size_t skip) {
  if (str2->length > str1->length - skip) {
    return false;
  } else {
    string *tmp = string_substring(str1, skip, skip + str2->length);
    bool ret = string_cmp(tmp, str2) == 0;
    // string_free(tmp);
    return ret;
  }
}

string *string_tokenize_string(string *str, string *delim, size_t *position) {
  if (!str || !delim || *position >= str->length) {
    return NULL;
  }
  char *delimiter = string_get_chars(delim);

  size_t start = *position;

  while (start < str->length && string_starts_with(str, delim, start)) {
    start += strlen(delimiter);
  }

  if (start >= str->length) {
    *position = str->length;
    return NULL;
  }

  size_t end = start;

  while (end < str->length && !string_starts_with(str, delim, end)) {
    end++;
  }

  string *token = string_substring(str, start, end);
  *position = end + strlen(delimiter);
  return token;
}

string *string_tokenize_chars(string *str, const char *delimiters,
                              size_t *position) {
  if (*position >= str->length) {
    return NULL; // No more tokens
  }

  size_t start = *position;
  while (start < str->length && strchr(delimiters, str->data[start])) {
    start++;
  }

  if (start >= str->length) {
    *position = str->length;
    return NULL;
  }

  size_t end = start;
  while (end < str->length && !strchr(delimiters, str->data[end])) {
    end++;
  }

  string *token = string_substring(str, start, end);
  *position = end;
  return token;
}

void string_clear(string *str) {
  str->data[0] = '\0';
  str->length = 0;
}

void string_free(string *str) {
#ifndef NO_FREE
  if (DEBUG)
    printf("FREEING: %s(%p)\n", string_get_chars(str), str);
  if (!str)
    return;
  if (str->data != NULL) {
    free(str->data);
  }
  free(str);
#else
  printf("string_free() (DISABLED)\n");
#endif
}
