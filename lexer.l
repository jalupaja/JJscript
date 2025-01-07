%{

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

// {X} is "not in ID_PART" because my ID parsing structure needs uses shorter strings and therefore the variable print_me would result in a lexer error
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
OCTAL [0-7]+
NUM   [0-9]+
DECIMAL [0-9]+
FP  ({NUM}\.{NUM}f?|{NUM}\.f?|\.{NUM}f?|{NUM}f)
BOOLEAN "true"|"false"
NIL "NONE"
ID_START [a-zA-Z\_]
ID_PART [a-zA-Z\_0-9]
X [^a-zA-Z\_0-9$]
HEX_NUM ([1-9a-fA-F][0-9a-fA-F]*|0)
HEX 0x{HEX_NUM}
STR_DOUBLE "\""
MULTI_STR_DOUBLE "\"\"\""
STR_SINGLE "'"
MULTI_STR_SINGLE "'''"
PRINTLN "printl"
PRINT "print"
LEN "len"
SPLIT "split"
RANDOM "rand"
INPUT "input"
ELIF "elif"
IF "if"
ELSE "else"
WHILE "while"
FOR "for"
RETURN "return"
IN "in"
LE "<="
GE ">="
EQ "=="
NEQ "!="
AA "++"
SS "--"
DELIMITER [,]
ASSIGN "="
ASSIGN_ADD "+="
ASSIGN_SUB "-="
ASSIGN_MUL "*="
ASSIGN_DIV "/="
ASSIGN_MOD "%="
OP [-+*/<>^&|%!]
LBRAK "("
RBRAK ")"
LSQARE "["
RSQARE "]"
LCURLY "{"
RCURLY "}"
DOUBLE_COLON "::"
COLON ":"
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

{DELIMITER}    { return delim; }
{IF}/{X}       { printf("OK\n"); return _if; }
{ELIF}/{X}     { return _elif; }
{ELSE}/{X}     { return _else; }
{WHILE}/{X}    { return _while; }
{FOR}/{X}      { return _for; }
{PRINT}/{X}    { return _print; }
{PRINTLN}/{X}  { return _printl; }
{LEN}/{X}      { return _len; }
{SPLIT}/{X}    { return _split; }
{RANDOM}/{X}   { return _random; }
{INPUT}/{X}    { return _input; }
{RETURN}       { return _return; }
{IN}/{X}       { return _in; }
{DECIMAL}      { long v = strtol(yytext, NULL, 0); yylval.val = value_create(&v, INT_TYPE); return val; /* DECIMAL */ }
{HEX}          { long v = strtol(yytext, NULL, 8); yylval.val = value_create(&v, INT_TYPE); return val; /* HEX */ }
{FP}           { double v = atof(yytext); yylval.val = value_create(&v, FLOAT_TYPE); return val; }
{BOOLEAN}/{X}  { bool v = strcmp(yytext, "true") == 0; yylval.val = value_create(&v, BOOL_TYPE); return val; }
{NIL}/{X}      { yylval.val = value_create(NULL, NULL_TYPE); return val; }
{EOL}          { return eol; }
{DOUBLE_COLON} { return double_colon; }
{COLON}        { return colon; }
{LE}           { return _le; }
{GE}           { return _ge; }
{EQ}           { return _eq; }
{NEQ}          { return _neq; }
{ASSIGN}       { return assign; }
{ASSIGN_ADD}   { return assign_add; }
{ASSIGN_SUB}   { return assign_sub; }
{ASSIGN_MUL}   { return assign_mul; }
{ASSIGN_DIV}   { return assign_div; }
{ASSIGN_MOD}   { return assign_mod; }
{AA}           { return _aa; }
{SS}           { return _ss; }
{OP}           { return yytext[0]; /* single character operation */ }
{LBRAK}        { return lbrak; }
{RBRAK}        { return rbrak; }
{LSQARE}       { return lsquare; }
{RSQARE}       { return rsquare; }
{LCURLY}       { yy_push_state(YYSTATE); BEGIN(INITIAL); return lcurly; }
{RCURLY}       { yy_pop_state(); renew_str(); /* clear cur_str for embeddings */ return rcurly; }

{ID_START} { yy_push_state(YYSTATE); BEGIN(ID); renew_str(); string_append_chars(cur_str, yytext); return id_start; }
<ID>{ID_PART} { string_append_chars(cur_str, yytext); }
<ID>"${" { yy_push_state(YYSTATE); BEGIN(INITIAL); yylval.val = value_create(cur_str, STRING_TYPE); return embed_lcurly; }
<ID>. { yy_pop_state(); yylval.val = value_create(cur_str, STRING_TYPE); unput(*yytext); return id_end; }

[ \n\t]

.   { printf("LEXER: UNKNOWN: %s\n", yytext); }


%%
