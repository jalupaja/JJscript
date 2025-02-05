%{

#include "string.h"
#include "queue.h"
#include "value.h"
#include "ast.h"
#include "parser.tab.h"
#include "utils.h"

#include <stdbool.h>

string *cur_str = NULL;

#define DEBUG 0

void renew_str() {
    cur_str = string_create(NULL);
}
int prev_line_num, cur_line_num, cur_chr;
string *prev_line = NULL;
string *cur_line = NULL;
string *cur_file_name;
int error_count = 0;
bool parsing_finished = false;

void _unput();

void print_error(const char *msg) {
    error_count++;
    char *c_line;
    if (cur_line) {
        c_line = string_get_chars(cur_line);
    } else {
        c_line = "";
    }
    int _cur_chr_num = cur_chr - yyleng;
    int _cur_line_num = cur_line_num;
    bool eol_error = false;

    if (!parsing_finished) {
        if (_cur_chr_num == 0 && strstr(msg, "expecting eol") != NULL) {
                // MISSING EOL ERROR
                eol_error = true;
                _cur_line_num = prev_line_num;
                yyleng = 1;
                _cur_chr_num = string_len(prev_line);
                string_append_char(prev_line, ';'); // manually add the missing ';';
                c_line = string_get_chars(prev_line);
                msg = "syntax error, missing End Of Line character"; // custom message
                yytext = ";";
        } else {
            if (_cur_chr_num > strlen(c_line))
                _cur_chr_num = strlen(c_line) - 1;
        }

        if (cur_file_name)
            fprintf(stderr, BOLD RED_COLOR "Error in %s" RESET_COLOR ":" BOLD CYAN_COLOR "%d:%d" RESET_COLOR ": %s\n", string_get_chars(cur_file_name), _cur_line_num, _cur_chr_num + 1, msg);
        else
            fprintf(stderr, BOLD RED_COLOR "Error" RESET_COLOR ":" BOLD CYAN_COLOR "%d:%d" RESET_COLOR ": %s\n", _cur_line_num, _cur_chr_num + 1, msg);

        if (_cur_chr_num >= strlen(c_line))
            fprintf(stderr, "%.*s" BOLD RED_COLOR "%.*s" BOLD RESET_COLOR "\n", _cur_chr_num, c_line, yyleng, c_line + _cur_chr_num);
        else
            fprintf(stderr, "%.*s" BOLD RED_COLOR "%.*s" BOLD RESET_COLOR "%s\n", _cur_chr_num, c_line, yyleng, c_line + _cur_chr_num, c_line + _cur_chr_num + yyleng);

        for (int i = 0; i < _cur_chr_num; i++) {
            if (c_line[i] == '\t') {
                fprintf(stderr, "\t");
            } else {
                fprintf(stderr, " ");
            }
        }

        fprintf(stderr, RED_COLOR BOLD);
        for (int i = 0; i < yyleng; i++) {
            fprintf(stderr, "^");
        }
        fprintf(stderr, RESET_COLOR "\n");

        fprintf(stderr, RED_COLOR "%s: \"%.*s\"" RESET_COLOR " at " CYAN_COLOR "%d:%d" RESET_COLOR "\n\n", msg, yyleng, yytext, _cur_line_num, _cur_chr_num + 1);
    } else {
        _cur_chr_num = string_len(prev_line);

        fprintf(stderr, BOLD RED_COLOR "Error" RESET_COLOR ": %s\n", msg);

        if (_cur_chr_num >= strlen(c_line))
            fprintf(stderr, BOLD RED_COLOR "%.*s" "%.*s" "\n" BOLD RESET_COLOR, _cur_chr_num, c_line, yyleng, c_line + _cur_chr_num);
        else
            fprintf(stderr, BOLD RED_COLOR "%.*s" "%.*s" "%s\n" BOLD RESET_COLOR, _cur_chr_num, c_line, yyleng, c_line + _cur_chr_num, c_line + _cur_chr_num + yyleng);

        fprintf(stderr, RED_COLOR BOLD);
        int t_len = yyleng + strlen(c_line + yyleng);
        for (int i = 0; i < t_len; i++) {
            fprintf(stderr, "^");
        }
        fprintf(stderr, RESET_COLOR "\n");
        if (eol_error)
            fprintf(stderr, "%s\n", c_line);

        fprintf(stderr, RED_COLOR "%s" RESET_COLOR "\n\n", msg);
    }
}

void save_line(char *line) {
    if (!cur_line) {
        // first setup
        cur_line = string_create(NULL);
        prev_line = string_create(NULL);
        prev_line_num = 0;
        cur_line_num = 0;
    } else {
        if (string_cmp_chars(cur_line, "")) {
            // only save if cur_line is not empty for better EOL errors

            string_clear(prev_line);
            string_append_string(prev_line, cur_line);
            prev_line_num = cur_line_num;
        }
        string_clear(cur_line);
    }

    cur_line_num++;
    cur_chr = 0;
    string_append_chars(cur_line, line);
}

#define YY_USER_ACTION cur_chr+=yyleng;

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
IMPORT "import"
EVAL "eval"
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

^.*$ { save_line(yytext);  REJECT; }

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
{IF}/{X}       { return _if; }
{ELIF}/{X}     { return _elif; }
{ELSE}/{X}     { return _else; }
{WHILE}/{X}    { return _while; }
{FOR}/{X}      { return _for; }
{PRINTLN}/{X}  { return _printl; }
{PRINT}/{X}    { return _print; }
{IMPORT}/{X}   { return _import; }
{EVAL}/{X}     { return _eval; }
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
<ID>. { yy_pop_state(); yylval.val = value_create(cur_str, STRING_TYPE); _unput(); return id_end; }

[ \n\t]

.   { print_error("Unexpected character"); }


%%

void _unput() {
    cur_chr-=yyleng;
    unput(*yytext);
}

