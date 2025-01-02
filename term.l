%{

#include "string.h"
#include "queue.h"
#include <stdbool.h>

typedef struct ast ast_t;
#include "term.tab.h"

%}
NUM -?[0-9]+
FP  -?({NUM}?\.{NUM}f?|{NUM}f)
BOOLEAN "true"|"false"
NIL "NONE"
ID  [a-z]+
PLUS "+"
MINUS "-"
STR \"[^\"]*\"
PRINT "print"
INPUT "input"
IF "if"
ELSE "else"
WHILE "while"
LE "<="
GE ">="
EQ "=="

%option noyywrap noinput nounput
%%

{IF}      { return _if; }
{ELSE}    { return _else; }
{WHILE}   { return _while; }
{PRINT}   { return print; }
{INPUT}   { return _input; }
{LE}      { return _le; }
{GE}      { return _ge; }
{EQ}      { return _eq; }
{NUM}     { int v = atoi(yytext); yylval.val = create_value(&v, INT_TYPE); return val; }
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
