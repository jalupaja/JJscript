%{
/* TODO
*/

#include "string.h"
#include "queue.h"
#include "value.h"
#include "ast.h"
#include "parser.tab.h"

#include <stdbool.h>

string *cur_str = NULL;

#define DEBUG 0

void renew_str() {
    cur_str = string_create(NULL);
}

/* TODO like f-strings
<MULTI_STRING_DOUBLE>"\\${" { string_append_chars(cur_str, "${"); }
<MULTI_STRING_DOUBLE>"${" { yy_push_state(YYSTATE); BEGIN(EXPRESSION); }
*/
%}

%x EMBED
%x STRING_DOUBLE
%x STRING_SINGLE
%x COMMENT
%x ID

REVERSE_LINE_COMMENT ^.*\?\?\?
LINE_COMMENT \/\/.*
BLOCK_COMMENT_IN "/\*"
BLOCK_COMMENT_OUT "\*/"
OCTAL -?[0-7]+
NUM   [0-9]+
FP  -?({NUM}\.{NUM}f?|{NUM}\.f?|\.{NUM}f?|{NUM}f)
BOOLEAN "true"|"false"
NIL "NONE"
ID_START [a-zA-Z_\-]
ID_PART [a-zA-Z_\-0-9]
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
RETURN "return"
LE "<="
GE ">="
EQ "=="
DELIMITER [,]
OP [-+*/<>^&|%!]
ASSIGN "="
LBRAK "("
RBRAK ")"
LSQARE "["
RSQARE "]"
LCURLY "{"
RCURLY "}"
EOL ";"

%option noyywrap noinput stack noyy_top_state
%%

{REVERSE_LINE_COMMENT} { /* REVERSE LINE COMMENT */ }
{LINE_COMMENT} { /* LINE COMMENT */ }
{BLOCK_COMMENT_IN} {/* BLOCK COMMENT */ yy_push_state(YYSTATE); BEGIN(COMMENT); }
<COMMENT>. { }
<COMMENT>{BLOCK_COMMENT_OUT} { yy_pop_state(); }

{STR_DOUBLE} { yy_push_state(YYSTATE); BEGIN(STRING_DOUBLE); renew_str(); return str_start; }
<STRING_DOUBLE>"\"\"" { string_append_char(cur_str, '"'); /* append " on \" */ }
<STRING_DOUBLE>"\"" { if (DEBUG) printf("END_STR: %s\n", string_get_chars(cur_str)); yy_pop_state(); yylval.val = value_create(cur_str, STRING_TYPE); return str_end; }

{STR_SINGLE} { /* string with single quotes */ yy_push_state(YYSTATE); BEGIN(STRING_SINGLE); renew_str(); return str_start; }
<STRING_SINGLE>"''" { string_append_char(cur_str, '\''); /* append ' on '' */ }
<STRING_SINGLE>"'" { yy_pop_state(); yylval.val = value_create(cur_str, STRING_TYPE); return str_end; }

<STRING_DOUBLE,STRING_SINGLE>"\n" { string_append_char(cur_str, '\n'); /* append new line */ }
<STRING_DOUBLE,STRING_SINGLE>"\t" { string_append_char(cur_str, '\t'); /* append tab */ }
<STRING_DOUBLE,STRING_SINGLE>"\\${" { string_append_chars(cur_str, "${"); }
<STRING_DOUBLE,STRING_SINGLE>"${" { if (DEBUG) printf("EMB_STR: %s\n", string_get_chars(cur_str)); yy_push_state(YYSTATE); BEGIN(INITIAL); yylval.val = value_create(cur_str, STRING_TYPE); return embed_lcurly; }

<STRING_DOUBLE>"\\\\" { string_append_char(cur_str, '\\'); /* append \ on \\ */ }
<STRING_DOUBLE>"\\n" { string_append_char(cur_str, '\n'); /* append new line */ }
<STRING_DOUBLE>"\\t" { string_append_char(cur_str, '\t'); /* append tab */ }
<STRING_DOUBLE>"\\x"{HEX_NUM} { string_append_char(cur_str, strtol(&yytext[2], NULL, 16)); /* append hex value */ }

<STRING_DOUBLE,STRING_SINGLE>. { string_append_chars(cur_str, yytext); }

{DELIMITER} { return delim; }
{IF}        { return _if; }
{ELIF}      { return _elif; }
{ELSE}      { return _else; }
{WHILE}     { return _while; }
{PRINT}     { return _print; }
{INPUT}     { return _input; }
{RETURN}    { return _return; }
{OCTAL}       { long v = (long)strtol(yytext, NULL, 8); yylval.val = value_create(&v, INT_TYPE); return val; /* OCTAL */ }
{HEX}       { long v = (long)strtol(yytext, NULL, 8); yylval.val = value_create(&v, INT_TYPE); return val; /* HEX */ }
{FP}        { double v = atof(yytext); yylval.val = value_create(&v, FLOAT_TYPE); return val; }
{BOOLEAN}   { bool v = strcmp(yytext, "true") == 0; yylval.val = value_create(&v, BOOL_TYPE); return val; }
{NIL}       { yylval.val = value_create(NULL, NULL_TYPE); return val; }
{EOL}       { return eol; }
{LE}        { return _le; }
{GE}        { return _ge; }
{EQ}        { return _eq; }
{OP}        { return yytext[0]; /* single character operation */ }
{ASSIGN}    { return assign; }
{LBRAK}     { return lbrak; }
{RBRAK}     { return rbrak; }
{LSQARE}    { return lsquare; }
{RSQARE}    { return rsquare; }
{LCURLY}    { yy_push_state(YYSTATE); BEGIN(INITIAL); return lcurly; }
{RCURLY}    { yy_pop_state(); renew_str(); /* clear cur_str for embeddings */ return rcurly; }

{ID_START} { yy_push_state(YYSTATE); BEGIN(ID); renew_str(); string_append_chars(cur_str, yytext); return id_start; }
<ID>{ID_PART} { string_append_chars(cur_str, yytext); }
<ID>"${" { yy_push_state(YYSTATE); BEGIN(INITIAL); yylval.val = value_create(cur_str, STRING_TYPE); return embed_lcurly; }
<ID>. { yy_pop_state(); yylval.val = value_create(cur_str, STRING_TYPE); unput(*yytext); return id_end; }

[ \n\t]

.   { printf("LEXER: UNKNOWN: %s\n", yytext); }


%%
