%{
/* TODO
*/

#include "string.h"
#include "queue.h"
#include "value.h"
#include "ast.h"
#include "parser.tab.h"

#include <stdbool.h>

string *cur_str;

/* TODO like f-strings
<MULTI_STRING_DOUBLE>"\\${" { string_append_chars(cur_str, "${"); }
<MULTI_STRING_DOUBLE>"${" { yy_push_state(YYSTATE); BEGIN(EXPRESSION); }
*/
%}

%x STRING_DOUBLE
%x MULTI_STRING_DOUBLE
%x STRING_SINGLE
%x MULTI_STRING_SINGLE
%x COMMENT

REVERSE_LINE_COMMENT ^.*\?\?\?
LINE_COMMENT \/\/.*
BLOCK_COMMENT_IN "/\*"
BLOCK_COMMENT_OUT "\*/"
NUM -?[0-7]+
FP  -?({NUM}?\.{NUM}f?|{NUM}f)
BOOLEAN "true"|"false"
NIL "NONE"
ID  [a-z]+
HEX_NUM ([1-9a-fA-F][0-9a-fA-F]*|0)
HEX 0x{HEX_NUM}
PLUS "+"
MINUS "-"
STR_DOUBLE "\""
MULTI_STR_DOUBLE "\"\"\""
STR_SINGLE "'"
MULTI_STR_SINGLE "'''"
PRINT "print"
INPUT "input"
ELIF "elif"
IF "if"
ELSE "else"
WHILE "while"
LE "<="
GE ">="
EQ "=="
OP [-+*/<>^]
ASSIGN "="
LBRAK "("
RBRAK ")"
LSQARE "["
RSQARE "]"
LCURLY "{"
RCURLY "}"
EOL ";"

%option noyywrap noinput nounput stack noyy_top_state
%%

{REVERSE_LINE_COMMENT} { /* REVERSE LINE COMMENT */ }
{LINE_COMMENT} { /* LINE COMMENT */ }
{BLOCK_COMMENT_IN} {/* BLOCK COMMENT */ yy_push_state(YYSTATE); BEGIN(COMMENT); }
<COMMENT>. { }
<COMMENT>{BLOCK_COMMENT_OUT} { yy_pop_state(); }

{MULTI_STR_DOUBLE} { yy_push_state(YYSTATE); BEGIN(MULTI_STRING_DOUBLE); cur_str = string_create(NULL); }
<MULTI_STRING_DOUBLE>"\"\"\"" { yy_pop_state(); yylval.val = create_value(cur_str, STRING_TYPE); return val; }
<MULTI_STRING_DOUBLE>"\\\\" { string_append_char(cur_str, '\\'); /* append \ on \\ */ }
<MULTI_STRING_DOUBLE>"\\\"" { string_append_char(cur_str, '\"'); /* append " on \" */ }
<MULTI_STRING_DOUBLE>"\\\n" { string_append_char(cur_str, '\n'); /* append new line */ }
<MULTI_STRING_DOUBLE>"\n" { string_append_char(cur_str, '\n'); }
<MULTI_STRING_DOUBLE>"\\x"{HEX_NUM} { string_append_char(cur_str, strtol(&yytext[2], NULL, 16)); /* append hex value */ }
<MULTI_STRING_DOUBLE>. { string_append_chars(cur_str, yytext); }

{STR_DOUBLE} { /* string with double quotes */ yy_push_state(YYSTATE); BEGIN(STRING_DOUBLE); cur_str = string_create(NULL); }
<STRING_DOUBLE>"\"" { yy_pop_state(); yylval.val = create_value(cur_str, STRING_TYPE); return val; }
<STRING_DOUBLE>"\\\"" { string_append_char(cur_str, '"'); /* append " on \" */ }
<STRING_DOUBLE>"\\\\" { string_append_char(cur_str, '\\'); /* append \ on \\ */ }
<STRING_DOUBLE>"\\\n" { string_append_char(cur_str, '\n'); /* append new line */ }
<STRING_DOUBLE>"\\x"{HEX_NUM} { string_append_char(cur_str, strtol(&yytext[2], NULL, 16)); /* append hex value */ }
<STRING_DOUBLE>"\n" { yyterminate(); /* TODO crash if string isn't finished??? */ }
<STRING_DOUBLE>. { string_append_chars(cur_str, yytext); }

{MULTI_STR_SINGLE} { yy_push_state(YYSTATE); BEGIN(MULTI_STRING_SINGLE); cur_str = string_create(NULL); }
<MULTI_STRING_SINGLE>"'''" { yy_pop_state(); yylval.val = create_value(cur_str, STRING_TYPE); return val; }
<MULTI_STRING_SINGLE>"\n" { string_append_char(cur_str, '\n'); }
<MULTI_STRING_SINGLE>. { string_append_chars(cur_str, yytext); }

{STR_SINGLE} { /* string with single quotes */ yy_push_state(YYSTATE); BEGIN(STRING_SINGLE); cur_str = string_create(NULL); }
<STRING_SINGLE>"'" { yy_pop_state(); yylval.val = create_value(cur_str, STRING_TYPE); return val; }
<STRING_SINGLE>"''" { string_append_char(cur_str, '\''); /* append ' on '' */ }
<STRING_SINGLE>"\n" { yyterminate(); /* TODO crash if string isn't finished... */ }
<STRING_SINGLE>. { string_append_chars(cur_str, yytext); }

{IF}      { return _if; }
{ELIF}    { return _elif; }
{ELSE}    { return _else; }
{WHILE}   { return _while; }
{PRINT}   { return _print; }
{INPUT}   { return _input; }
{NUM}     { int v = (int)strtol(yytext, NULL, 8); yylval.val = create_value(&v, INT_TYPE); return val; /* OCTAL */ }
{FP}      { float v = atof(yytext); yylval.val = create_value(&v, FLOAT_TYPE); return val; }
{BOOLEAN} { bool v = strcmp(yytext, "true") == 0; yylval.val = create_value(&v, BOOL_TYPE); return val; }
{NIL}     { yylval.val = create_value(NULL, NULL_TYPE); return val; }
{ID}      { yylval.id = string_create(yytext); return id;   }
{EOL}     { return eol; }
{LE}      { return _le; }
{GE}      { return _ge; }
{EQ}      { return _eq; }
{OP}      { return yytext[0]; /* single character operation */ }
{ASSIGN}  { return assign; }
{LBRAK}   { return lbrak; }
{RBRAK}   { return rbrak; }
{LSQARE}  { return lsquare; }
{RSQARE}  { return rsquare; }
{LCURLY}  { return lcurly; }
{RCURLY}  { return rcurly; }

[ \n\t]

.   { printf("UNKNOWN: %s\n", yytext); }

%%

