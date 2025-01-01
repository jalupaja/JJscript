#ifndef STRING_H
#define STRING_H

#include <stdlib.h>

typedef struct {
  char *data;
  size_t length;
  size_t capacity;
} string;

string *string_create(const char *init);
void string_append_char(string *str, const char suffix);
void string_append_chars(string *str, const char *suffix);
void string_remove_chars_from_end(string *str, int amount);
void string_append_string(string *str1, string *str2);
string *string_substring(string *str, size_t start, size_t end);
char string_char_at(string *str, size_t index);
char *string_get_chars(string *str);
int string_cmp(string *str1, string *str2);
void string_free(string *str);

#endif // STRING_H
