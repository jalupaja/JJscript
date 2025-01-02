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

%option noyywrap noinput nounput
%%

{IF}      { return _if; }
{ELSE}    { return _else; }
{WHILE}   { return _while; }
{PRINT}   { return print; }
{INPUT}   { return _input; }
{NUM}     { yylval.num = atoi(yytext); return num;   }
{FP}      { yylval.fp = atof(yytext); return fp; }
{BOOLEAN} { yylval.boolean = strcmp(yytext, "true") == 0; return boolean; }
{NIL}     { return nil; }
{ID}      { yylval.id = string_create(yytext); return id;   }
{STR}     { /* removed "' */ yylval.str = string_create(yytext+1); string_remove_chars_from_end(yylval.str, 1); return str; }

[ \n\t]

.   { return yytext[0]; }
