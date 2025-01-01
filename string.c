#include "string.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// TODO need to free on realloc?
#define INITIAL_CAPACITY 16

#define DEBUG 0

string *string_create(const char *init) {
  string *str = (string *)malloc(sizeof(string));
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

ssize_t string_len(string *str) { return str->length; }

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

void string_remove_chars_from_end(string *str, int amount) {
  ssize_t new_len = str->length - amount;
  if (new_len < 0)
    new_len = 0;
  str->data[new_len] = '\0';
  str->length = new_len;
}

void string_append_string(string *str1, string *str2) {
  if (str1->length + str2->length >= str1->capacity) {
    while (str1->length + str2->length >= str1->capacity) {
      str1->capacity *= 2;
    }
    str1->data = (char *)realloc(str1->data, str1->capacity);
  }

  strcat(str1->data, str2->data);
  str1->length += str2->length;
}

string *string_substring(string *str, size_t start, size_t end) {
  if (start > end || end > str->length) {
    fprintf(stderr, "Invalid substring range.\n");
    exit(EXIT_FAILURE);
  }
  string *sub = (string *)malloc(sizeof(string));
  sub->length = end - start;
  sub->capacity = sub->length + 1;
  sub->data = (char *)malloc(sub->capacity);
  strncpy(sub->data, str->data + start, sub->length);
  sub->data[sub->length] = '\0';
  return sub;
}

char string_char_at(string *str, size_t index) {
  if (index >= str->length) {
    fprintf(stderr, "Index out of bounds.\n");
    exit(EXIT_FAILURE);
  }
  return str->data[index];
}

char *string_get_chars(string *str) { return str->data; }

int string_cmp(string *str1, string *str2) {
  return strcmp(str1->data, str2->data);
}

void string_free(string *str) {
  if (str->data != NULL) {
    free(str->data);
    str->data = NULL;
  }
  str->length = 0;
  str->capacity = 0;
}
