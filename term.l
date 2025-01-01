%{

#include "string.h"
#include "queue.h"

typedef struct ast ast_t;
#include "term.tab.h"

%}
NUM [0-9]+
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

{IF} { return _if; }
{ELSE} { return _else; }
{WHILE} { return _while; }
{PRINT} { return print; }
{INPUT} { return _input; }
{NUM}   { yylval.num = atoi(yytext); return num;   }
{ID}    { yylval.id = string_create(yytext); return id;   }
{STR}   { /* removed "/' */ yylval.str = string_create(yytext+1); string_remove_chars_from_end(yylval.str, 1); return str; }

[ \n\t]

.   { return yytext[0]; }
