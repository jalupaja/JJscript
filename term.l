%{
/* TODO
*/

typedef struct _ast_t ast_t;

#include "string.h"
#include "queue.h"
#include "values.h"
#include "term.tab.h"

#include <stdbool.h>

%}
NUM -?[0-7]+
FP  -?({NUM}?\.{NUM}f?|{NUM}f)
BOOLEAN "true"|"false"
NIL "NONE"
ID  [a-z]+
PLUS "+"
MINUS "-"
STR \"[^\"]*\"
PRINT "print"
INPUT "input"
ELIF "elif"
IF "if"
ELSE "else"
WHILE "while"
LE "<="
GE ">="
EQ "=="

%option noyywrap noinput nounput
%%

{IF}      { return _if; }
{ELIF}    { return _elif; }
{ELSE}    { return _else; }
{WHILE}   { return _while; }
{PRINT}   { return print; }
{INPUT}   { return _input; }
{LE}      { return _le; }
{GE}      { return _ge; }
{EQ}      { return _eq; }
{NUM}     { int v = (int)strtol(yytext, NULL, 8); yylval.val = create_value(&v, INT_TYPE); return val; /* OCTAL */ }
{FP}      { float v = atof(yytext); yylval.val = create_value(&v, FLOAT_TYPE); return val; }
{BOOLEAN} { bool v = strcmp(yytext, "true") == 0; yylval.val = create_value(&v, BOOL_TYPE); return val; }
{NIL}     { yylval.val = create_value(NULL, NULL_TYPE); return val; }
{ID}      { yylval.id = string_create(yytext); return id;   }
{STR}     { /* removed "' */ string *str = string_create(yytext+1);
            string_remove_chars_from_end(str, 1);
            yylval.val = create_value(str, STRING_TYPE);
            return val;
          }

[ \n\t]

.   { return yytext[0]; }
