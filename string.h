#ifndef STRING_H
#define STRING_H

#include <stdbool.h>
#include <stdlib.h>

typedef struct {
  char *data;
  size_t length;
  size_t capacity;
} string;

typedef struct queue queue;

string *string_create(const char *init);
string *string_copy(string *str);
size_t string_len(string *str);
bool string_in(string *str1, string *str2);
queue *string_split(string *str, string *delim);
void string_append_char(string *str, const char suffix);
void string_append_chars(string *str, const char *suffix);
void string_remove_chars_from_beginning(string *str, int amount);
void string_remove_chars_from_end(string *str, int amount);
string *string_remove_chars(string *str, string *str2);
void string_append_string(string *str1, string *str2);
void string_prefix_chars(const char *prefix, string *str2);
string *string_substring(string *str, size_t start, size_t end);
void string_repeat(string *str, size_t n);
char string_get_char_at(string *str, size_t index);
char *string_get_chars(string *str);
char *string_get_chars_at(string *str, size_t index);
string *string_interleave(string *str1, string *str2);
int string_cmp(string *str1, string *str2);
int string_cmp_chars(string *str1, const char *str2);
void string_strip(string *str);
string *string_tokenize_string(string *str, string *delim, size_t *position);
string *string_tokenize_chars(string *str, const char *delimiters,
                              size_t *position);
void string_clear(string *str);
void string_free(string *str);

#endif // STRING_H
