%{
#include "function.h"
#include "string.h"
#include "queue.h"
#include "value.h"
#include "value_calc.h"
#include "env.h"
#include "ast.h"
#include "utils.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>

#define DEBUG 0

typedef struct yy_buffer_state *YY_BUFFER_STATE;

extern int yyparse();
extern int yylex();
extern void yyerror(const char *s);
extern void print_error(const char *msg);
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);
extern FILE *yyin;
extern int error_count;
extern bool parsing_finished;

int yydebug=0;
void yyerror (const char *msg) {
    print_error(msg);
}

typedef struct ast_t ast_t;
val_t *ex (ast_t *t);
val_t *fun_call(val_t *id, queue *args);
void opt_ast ( ast_t *t);

ast_t *root;

enum {
    STMTS = 10000,
    STMT,
};
%}
%define parse.error verbose

%union {
    string *id;
    val_t *val;
    ast_t *ast;
    queue *queue;
}

%token _if _elif _else _while _for
%token _return
%token _str str_start <val> str_end
%token _id id_start <val> id_end <id> _id_eval
%token _arr_create <val> _range _arr_call _arr
%token <val> embed_lcurly
%token _input _inline_expr _print _printl _eval <val> val fun
%token assign_id assign_fun eol delim
%token lsquare rsquare lcurly rcurly

%type <queue> PARAMS ARGS EMBED_STR EMBED_ID
%type <ast> VAL LIST FUN_CALL ID ID_EVAL STMTS STMT NON_STMT EXPR IFELSE STRING

%precedence delim
%right assign assign_add assign_sub assign_mul assign_div assign_mod
%left '|'
%left '&'
%left '!'
%left '<' '>' _le _ge _eq _neq
%left _in
%left colon double_colon
%left '-' '+'
%left '*' '/' '%'
%right '^'
%left _aa _ss
%left _len _split _random
%left rbrak
%right lbrak

%%

S: STMTS { opt_ast($1); if (DEBUG) printf("\n"); if (DEBUG) ast_print($1); if (DEBUG) printf("\n"); root = $1; }

STMTS: STMTS STMT eol { $$ = node2(STMTS, $1, $2); }
     | STMTS NON_STMT { $$ = node2(STMTS, $1, $2); }
     | %empty { $$ = NULL; }

STMT: ID assign EXPR { $$ = node2(assign_id, $1, $3); }
    | ID assign_add EXPR { $$ = node2(assign_add, $1, $3); }
    | ID assign_sub EXPR { $$ = node2(assign_sub, $1, $3); }
    | ID assign_mul EXPR { $$ = node2(assign_mul, $1, $3); }
    | ID assign_div EXPR { $$ = node2(assign_div, $1, $3); }
    | ID assign_mod EXPR { $$ = node2(assign_mod, $1, $3); }
    | _print lbrak EXPR rbrak { $$ = node1(_print, $3); }
    | _printl lbrak EXPR rbrak { $$ = node1(_printl, $3); }
    | _print lbrak rbrak { $$ = node1(_print, NULL); }
    | _printl lbrak rbrak { $$ = node1(_printl, NULL); }
    | _return lbrak rbrak { $$ = node1(_return, NULL); }
    | _return lbrak EXPR rbrak { $$ = node1(_return, $3); }
    | _eval lbrak STRING rbrak { $$ = node1(_eval, $3); }
    | EXPR { $$ = node1(STMT, $1); }

NON_STMT: ID assign lcurly lbrak PARAMS rbrak STMTS rcurly { $$ = node1(assign_fun, $1); $$->val = value_create(function_create($5, $7), FUNCTION_TYPE); /* assign a function */ }
        | _if EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
        | _while EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_while, $2, $4, $6); }
        | _for ID colon EXPR lcurly STMTS rcurly IFELSE { $$ = node4(_for, $2, $4, $6, $8); }
        | _for lbrak ID colon EXPR rbrak lcurly STMTS rcurly IFELSE { $$ = node4(_for, $3, $5, $8, $10); }
        | lcurly STMTS rcurly { $$ = node1(lcurly, $2); /* local environment */ }

PARAMS: PARAMS delim ID { queue_enqueue($1, $3); $$ = $1; }
      | ID { $$ = queue_create(); queue_enqueue($$, $1); }
      | %empty { $$ = queue_create(); }

ARGS: ARGS delim EXPR { queue_enqueue($1, $3); $$ = $1; }
    | ARGS delim { $$ = $1; /* allow trailing commas */ }
    | EXPR { $$ = queue_create(); queue_enqueue($$, $1); }
    | %empty { $$ = queue_create(); }

IFELSE: _elif EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
      | _else lcurly STMTS rcurly { $$ = node1(_else, $3); }
      | %empty { $$ = NULL; }

EXPR: EXPR _eq EXPR { $$ = node2(_eq, $1, $3); }
    | EXPR _neq EXPR { $$ = node2(_neq, $1, $3); }
    | EXPR '-' EXPR { $$ = node2('-', $1, $3); }
    | EXPR '+' EXPR { $$ = node2('+', $1, $3); }
    | '-' EXPR { $$ = node2('-', NULL, $2); }
    | '+' EXPR { $$ = node2('+', NULL, $2); }
    | EXPR '*' EXPR { $$ = node2('*', $1, $3); }
    | EXPR '/' EXPR { $$ = node2('/', $1, $3); }
    | EXPR _le EXPR { $$ = node2(_le, $1, $3); }
    | EXPR _ge EXPR { $$ = node2(_ge, $1, $3); }
    | EXPR '<' EXPR { $$ = node2('<', $1, $3); }
    | EXPR '>' EXPR { $$ = node2('>', $1, $3); }
    | EXPR '^' EXPR { $$ = node2('^', $1, $3); }
    | EXPR '&' EXPR { $$ = node2('&', $1, $3); }
    | EXPR '|' EXPR { $$ = node2('|', $1, $3); }
    | EXPR '%' EXPR { $$ = node2('%', $1, $3); }
    | EXPR _in EXPR { $$ = node2(_in, $1, $3); }
    | EXPR colon EXPR { $$ = node3(_range, $1, $3, NULL); }
    | EXPR double_colon EXPR double_colon EXPR { $$ = node3(_range, $1, $3, $5); }
    | '!' EXPR { $$ = node1('!', $2); }
    | lbrak EXPR rbrak  { $$ = $2; }
    | ID _aa { $$ = node1(_aa, $1); }
    | ID _ss { $$ = node1(_ss, $1); }
    | VAL
    | LIST
    | FUN_CALL
    | ID_EVAL
    | STRING
    | _input lbrak STRING rbrak { $$ = node1(_input, $3); }
    | _input lbrak rbrak { $$ = node1(_input, NULL); }
    | _len lbrak EXPR rbrak { $$ = node1(_len, $3); }
    | _split lbrak EXPR delim EXPR delim rbrak { $$ = node2(_split, $3, $5); /* range with trailing comma */ }
    | _split lbrak EXPR delim EXPR rbrak { $$ = node2(_split, $3, $5); /* range */ }
    | _split lbrak EXPR rbrak { $$ = node2(_split, $3, NULL); }
    | _random lbrak EXPR delim EXPR delim rbrak { $$ = node2(_random, $3, $5); }
    | _random lbrak EXPR delim EXPR rbrak { $$ = node2(_random, $3, $5); }
    | _random lbrak rbrak { $$ = node2(_random, NULL, NULL); }


LIST: lsquare ARGS rsquare { $$ = node0(_arr_create); $$->val = value_create($2, QUEUE_TYPE); }

STRING: str_start str_end { $$ = node0(val); $$->val = $2; }
      | str_start EMBED_STR { $$ = node0(_str); $$->val = value_create($2, QUEUE_TYPE); }

EMBED_STR: embed_lcurly EXPR rcurly str_end {
           $$ = queue_create();
           queue_enqueue($$, $1->val.strval);
           queue_enqueue($$, $2);
           queue_enqueue($$, $4->val.strval);
       }
      | embed_lcurly EXPR rcurly EMBED_STR {
           $$ = $4;
           queue_enqueue_at($$, $1->val.strval, 0);
           queue_enqueue_at($$, $2, 1);
           queue_enqueue_at($$, NULL, 2);
       };

VAL:      val { $$ = node0(val); $$->val = $1; }
FUN_CALL: ID lbrak ARGS rbrak { $$ = node1(fun, $1); $$->val = value_create($3, QUEUE_TYPE); /* function call */ }
ID_EVAL:  ID { $$ = node1(_id_eval, $1); }

ID:       id_start id_end { $$ = node0(_id); $$->val = $2; }
        | id_start EMBED_ID  { $$ = node0(_id); $$->val = value_create($2, QUEUE_TYPE); }
        | ID lsquare ARGS rsquare { $$ = node1(_arr, $1); $$->val = value_create($3, QUEUE_TYPE); }

EMBED_ID: embed_lcurly EXPR rcurly id_end {
           $$ = queue_create();
           queue_enqueue($$, $1->val.strval);
           queue_enqueue($$, $2);
           queue_enqueue($$, $4->val.strval);
       }
      | embed_lcurly EXPR rcurly EMBED_ID {
           $$ = $4;
           queue_enqueue_at($$, $1->val.strval, 0);
           queue_enqueue_at($$, $2, 1);
           queue_enqueue_at($$, NULL, 2);
       };

%%

val_t *eval(string *str, bool suppress_errors) {
    parsing_finished = false;
    if (suppress_errors)
        if(freopen("/dev/null", "w", stderr) == NULL); // restore stderr
    YY_BUFFER_STATE buffer = yy_scan_string(string_get_chars(str));
    val_t *res = NULL;

    // Parse the input
    if (yyparse() == 0) {
        res = ex(root);
        // ast_free(root); // TODO
        yy_delete_buffer(buffer);
    } else {
        yy_delete_buffer(buffer);
        res = NULL;
    }
    if (suppress_errors)
        if(freopen("/dev/tty", "w", stderr) == NULL); // restore stderr
    parsing_finished = true;
    return res;
}

string *join_embeds(queue *segments) {
    string *str = string_create(NULL);

    string *prefix;
    ast_t *emb;
    val_t *res;
    string *suffix;
    size_t q_len = queue_len(segments);
    for (size_t i = 0; i < q_len; i += 3) {

        prefix = (string *)queue_at(segments, i);
        emb = (ast_t *)queue_at(segments, i + 1);
        suffix = (string *)queue_at(segments, i + 2);

        res = ex(emb);

        string_append_string(str, prefix);
        string_append_string(str, val2string(res));
        string_append_string(str, suffix);
    }

    return str;
}

val_t *ex(ast_t *t) {
    if (!t)
        return value_create(NULL, NULL_TYPE);

    switch (t->type) {
        case STMTS:
            val_t *res = ex(t->c[0]);

            if (res && res->return_val) {
                return res;
            } else {
                return ex(t->c[1]);
            }
        case STMT:
            return ex(t->c[0]);
        case _return: {
            val_t *res;
            if (t->c[0]) {
                res = ex(t->c[0]);
            } else {
                res = value_create(NULL, NULL_TYPE);
            }
            res->return_val = true;
            return res;
        }
        case '+':
            if (t->c[0] == NULL) {
                // +3 as number -> not an operation
                    return ex(t->c[1]);
            } else {
                return addition(ex(t->c[0]), ex(t->c[1]));
            }
        case '-': {
            if (t->c[0] == NULL) {
                // -3 as number -> not an operation
                long mul = -1;
                val_t *mul_val = value_create(&mul, INT_TYPE);
                val_t *res = multiplication(ex(t->c[1]), mul_val);
                value_free(mul_val);
                return res;
            } else {
                return subtraction(ex(t->c[0]), ex(t->c[1]));
            }
        }
        case '*':
            return multiplication(ex(t->c[0]), ex(t->c[1]));
        case '/':
            return division(ex(t->c[0]), ex(t->c[1]));
        case '<':
            return less_than(ex(t->c[0]), ex(t->c[1]));
        case '>':
            return greater_than(ex(t->c[0]), ex(t->c[1]));
        case _le:
            return less_equal_than(ex(t->c[0]), ex(t->c[1]));
        case _ge:
            return greater_equal_than(ex(t->c[0]), ex(t->c[1]));
        case _eq:
            return equal(ex(t->c[0]), ex(t->c[1]));
        case _neq: {
            val_t *res = equal(ex(t->c[0]), ex(t->c[1]));
            res->val.boolval = ! (bool)res->val.boolval;
            return res;
        }
        case '^':
            return power(ex(t->c[0]), ex(t->c[1]));
        case '%':
            return modulo(ex(t->c[0]), ex(t->c[1]));
        case '|':
            return OR(ex(t->c[0]), ex(t->c[1]));
        case '&':
            return AND(ex(t->c[0]), ex(t->c[1]));
        case '!':
            return NOT(ex(t->c[0]));
        case assign_id: {
            val_t *id = ex(t->c[0]);

            val_t *res = ex(t->c[1]);
            if (DEBUG)
                printf("assign_id: %s = %s\n", string_get_chars(id->val.strval), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_add: {
            val_t *id = ex(t->c[0]);

            val_t *val = ex(t->c[1]);

            val_t *cur = env_search(id);
            val_t *res = addition(cur, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_add: %s += %s\n", string_get_chars(id->val.strval), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case _aa: {
            val_t *id = ex(t->c[0]);

            int one = 1;
            val_t *val = value_create(&one, INT_TYPE);

            val_t *cur = env_search(id);
            val_t *res = addition(cur, val);

            value_free(val);

            if (DEBUG)
                printf("assign_++: %s\n", string_get_chars(id->val.strval));
            env_save(id, res);
            return res;
        }
        case assign_sub: {
            val_t *id = ex(t->c[0]);

            val_t *val = ex(t->c[1]);

            val_t *cur = env_search(id);
            val_t *res = subtraction(cur, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_sub: %s += %s\n", string_get_chars(id->val.strval), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case _ss: {
            val_t *id = ex(t->c[0]);

            int one = 1;
            val_t *val = value_create(&one, INT_TYPE);

            val_t *cur = env_search(id);
            val_t *res = subtraction(cur, val);

            value_free(val);

            if (DEBUG)
                printf("assign_--: %s\n", string_get_chars(id->val.strval));
            env_save(id, res);
            return res;
        }
        case assign_mul: {
            val_t *id = ex(t->c[0]);

            val_t *val = ex(t->c[1]);

            val_t *cur = env_search(id);
            val_t *res = multiplication(cur, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_mul: %s += %s\n", string_get_chars(id->val.strval), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_div: {
            val_t *id = ex(t->c[0]);

            val_t *val = ex(t->c[1]);

            val_t *cur = env_search(id);
            val_t *res = division(cur, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_div: %s += %s\n", string_get_chars(id->val.strval), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_mod: {
            val_t *id = ex(t->c[0]);

            val_t *val = ex(t->c[1]);

            val_t *cur = env_search(id);
            val_t *res = modulo(cur, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_mod: %s += %s\n", string_get_chars(id->val.strval), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_fun: {
            val_t *id = ex(t->c[0]);

            env_save(id, t->val);
            return t->val;
        }
        case _str: {
            queue *segments = t->val->val.qval;
            string *str = join_embeds(segments);
            return value_create(str, STRING_TYPE);
        }
        case val:
            return t->val;
        case _arr_create: {
            queue *old_elems = t->val->val.qval;
            queue *new_elems = queue_create();

            size_t q_len = queue_len(old_elems);
            for (size_t i = 0; i < q_len; i++) {
                val_t *new_val = ex((ast_t *)queue_at(old_elems, i));
                queue_enqueue(new_elems, new_val);
            }

            val_t *res = value_create(new_elems, QUEUE_TYPE);
            if (DEBUG) {
                printf("LIST ELEMENTS: %s\n", string_get_chars(val2string(res)));
            }
            return res;
        }
        case _arr_call: {
            val_t *id = ex(t->c[0]);
            // TODO env_save_at
            val_t *cur = env_search(id);
            val_t *at = ex(t->c[1]);

            return value_at(cur, val2int(at));
        }
        case _arr: {
            val_t *id = ex(t->c[0]);

            queue *indexes = id->indexes;
            if (!indexes) {
                id->indexes = queue_create();
                indexes = id->indexes;
            }

            queue *new_indexes = queue_create();

            queue *args = t->val->val.qval;

            size_t q_len = queue_len(args);
            for (size_t i = 0; i < q_len; i++) {
                val_t *new_val = ex((ast_t *)queue_at(args, i));

                if (new_val->val_type == QUEUE_TYPE) {
                    queue_append(new_indexes, new_val->val.qval);
                } else {
                    queue_enqueue(new_indexes, (void *)new_val);
                }
            }

            // enqueue new_indexes to indexes
            queue_enqueue(indexes, new_indexes);

            return id;
        }
        case _in: {
            val_t *left = ex(t->c[0]);
            val_t *right = ex(t->c[1]);

            bool res = value_in(left, right);
            return value_create(&res, BOOL_TYPE);
        }
        case _range: {
            val_t *left = ex(t->c[0]);
            val_t *right = ex(t->c[1]);
            double step = 1;
            if (t->c[2]) {
                step = val2float(ex(t->c[2]));
            }

            if (step <= 0) {
                return value_create(queue_create(), QUEUE_TYPE);
            } else if (val2int(left) > val2int(right)) {
                val_t *tmp = left;
                left = right;
                right = tmp;
            }

            val_t *res;
            if (left->val_type == STRING_TYPE || right->val_type == STRING_TYPE) {
                string *str = string_create(NULL);
                if ((int)step == 0)
                    step += 1;
                for (char l = val2int(left); l <= val2float(right); l += (int)step) {
                    string_append_char(str, l);
                }
                res = value_create(str, STRING_TYPE);
            } else {
                queue *q = queue_create();
                if (left->val_type == FLOAT_TYPE || (int)step != step) {
                    for (double l = val2float(left); l <= val2float(right); l += step) {
                        queue_enqueue(q, value_create(&l, FLOAT_TYPE));
                    }
                } else {
                    if ((int)step == 0)
                        step += 1;
                    for (long l = val2int(left); l <= val2float(right); l += (int)step) {
                        queue_enqueue(q, value_create(&l, INT_TYPE));
                    }
                }
                res = value_create(q, QUEUE_TYPE);
            }

            return res;
        }
        case fun: {
            val_t *id = ex(t->c[0]);

            val_t *cur = env_search(id);
            if (!cur || cur->val_type != FUNCTION_TYPE) {
                string *err_str = string_create("Undefined function ");
                string_append_string(err_str, id->val.strval);
                print_error(string_get_chars(err_str));
                string_free(err_str);
                return value_create(NULL, NULL_TYPE);
            }

            queue *old_args = t->val->val.qval;
            queue *new_args = queue_create();

            size_t q_len = queue_len(old_args);
            for (size_t i = 0; i < q_len; i++) {
                val_t *new_val = ex((ast_t *)queue_at(old_args, i));
                queue_enqueue(new_args, new_val);
            }

            if (DEBUG) {
                printf("ARGS: ");
                queue_print(new_args, (void (*)(void*)) value_print);
                printf("\n");
            }

            val_t *res = fun_call(id, new_args);

            queue_free(new_args);

            return res;
        }
        case _id: {
            string *str;

            if (t->val->val_type == STRING_TYPE) {
                str = t->val->val.strval;
            } else if (t->val->val_type == QUEUE_TYPE) {
                queue *segments = t->val->val.qval;
                str = join_embeds(segments);
            } else {
                print_error("Invalid ID. This can't happen");
                return value_create(NULL, NULL_TYPE);
            }

            return value_create(str, STRING_TYPE);
        }
        case _id_eval: {
            val_t *id = ex(t->c[0]);
            val_t *cur = env_search(id);

            if (cur) {
                return cur;
            } else {
                string *err_str = string_create("Undefined variable ");
                string_append_string(err_str, id->val.strval);
                print_error(string_get_chars(err_str));
                string_free(err_str);
                return value_create(NULL, NULL_TYPE);
            }
        }
        case lcurly: {
            // local environment
            env_push();
            ex(t->c[0]);
            env_pop();
            return NULL;
        }
        case _input: {
            if (t->c[0]) {
                value_print(ex(t->c[0]));
            }
            string *str = string_read();
            string_append_char(str, ';');
            val_t *res = eval(str, true);
            if (!res || res->val_type == NULL_TYPE || res->val_type == FUNCTION_TYPE) {
                string_remove_chars_from_end(str, 1);
                return value_create(str, STRING_TYPE);
            } else {
                string_free(str);
                return res;
            }
            /*
            return value_read();
            */
        }
        case _print: {
            val_t *val = ex(t->c[0]);
            value_print(val);
            return value_create(NULL, NULL_TYPE);
        }
        case _printl: {
            if (t->c[0]) {
                val_t *val = ex(t->c[0]);
                value_print(val);
            }
            printf("\n");
            return value_create(NULL, NULL_TYPE);
        }
        case _eval: {
            val_t *val = ex(t->c[0]);
            string *str = val2string(val);
            val_t *res = eval(str, false);
            if (res) {
                return res;
            } else {
                print_error("Parsing failed");
                return value_create(NULL, NULL_TYPE);
            }
        }
        case _len: {
            val_t *val = ex(t->c[0]);
            if (!val || val->val_type == NULL_TYPE) {
                return value_create(NULL, NULL_TYPE);
            }
            size_t len = value_len(val);
            return value_create(&len, INT_TYPE);
        }
        case _split: {
            val_t *val = ex(t->c[0]);
            string *delim;
            if (t->c[1]) {
                val_t *delim_val = ex(t->c[1]);
                delim = val2string(delim_val);
            } else {
                delim = string_create(" ");
            }

            queue *res;
            if (val->val_type == STRING_TYPE) {
                res = string_split(val->val.strval, delim);
            } else if (val->val_type == QUEUE_TYPE) {
                res = queue_copy(val->val.qval);
            } else {
                res = queue_create();
                queue_enqueue(res, val);
            }
            return value_create(res, QUEUE_TYPE);
        }
        case _random: {
            val_t *val_1, *val_2;
            double start, end;
            bool ret_float = false;
            if (t->c[0] && t->c[1]) {
                val_1 = ex(t->c[0]);
                val_2 = ex(t->c[1]);

                start = val2float(val_1);
                end = val2float(val_2);
                ret_float = val_1->val_type == FLOAT_TYPE || val_2->val_type == FLOAT_TYPE;
            } else {
                start = 0.0;
                end = 10.0;
            }

            if (start > end) {
                double tmp = start;
                start = end;
                end = tmp;
            }

            if (ret_float) {
                // pseudo floating points
                int int_start = (int)(start * 100);
                int int_end = (int)(end * 100);
                int int_ret = int_start + rand() % (int_end - int_start + 1);
                double res = (double)int_ret / 100.0;
                return value_create(&res, FLOAT_TYPE);
            } else {
                int res = (int)start + rand() % ((int)end - (int)start + 1);
                return value_create(&res, INT_TYPE);
            }
        }
        case _if:
            if (val2bool(ex(t->c[0]))) {
                return ex(t->c[1]);
            } else if (t->c[2]) {
                return ex(t->c[2]);
            }
            return value_create(NULL, NULL_TYPE);
        case _else:
            return ex(t->c[0]);
        case _while: {
            val_t *ret = NULL;
            while (val2bool(ex(t->c[0]))) {
                ret = ex(t->c[1]);
            }
            // elif/else
            if (!ret) {
                ret = ex(t->c[2]);
            }
            return ret;
        }
        case _for: {
            val_t *id = ex(t->c[0]);

            val_t *expr = ex(t->c[1]);

            size_t expr_len = value_len(expr);
            val_t *cur;
            val_t *ret = NULL;
            for (size_t i = 0; i < expr_len; i++) {
                cur = value_at(expr, i);
                env_save(id, value_copy(cur));
                ret = ex(t->c[2]);
            }
            // elif/else
            if (!ret) {
                ret = ex(t->c[3]);
            }
            return ret;
        }
        default:
            print_error("Unsupported node");
            break;
    }

    return value_create(NULL, NULL_TYPE);
}

val_t *fun_call(val_t *id, queue *args) {
  if (DEBUG)
      printf("fun_call (%s) with %ld args\n", string_get_chars(id->val.strval), queue_len(args));
  // search function
  val_t *cur = env_search(id);

  if (!cur || cur->val_type != FUNCTION_TYPE) {
    // TODO actual error. also below
    string *err_str = string_create("Invalid function ");
    string_append_string(err_str, id->val.strval);
    print_error(string_get_chars(err_str));
    string_free(err_str);
    return value_create(NULL, NULL_TYPE);
  }

  fun_t *fun = cur->val.funval;

  // start new environment
  env_push();

  size_t p_len = queue_len(fun->params);
  queue *final_args = args;
  if (queue_len(args) != p_len) {
    if (queue_len(args) == 1 && (((val_t *)queue_at(args, 0))->val_type == QUEUE_TYPE) &&
                                queue_len(((val_t *)queue_at(args, 0))->val.qval) == p_len) {
      // TODO if there is only one argument, it expects more but the first is a queue ->
      // use first argument as args
      final_args = ((val_t *)queue_at(args, 0))->val.qval;
    } else {
      char buf[32];
      string *err_str = string_create("Function '");
      string_append_string(err_str, id->val.strval);
      string_append_chars(err_str, "' expected ");
      snprintf(buf, sizeof(buf), "%ld", p_len);
      string_append_chars(err_str, buf);
      string_append_chars(err_str, " arguments but got ");
      snprintf(buf, sizeof(buf), "%ld", queue_len(args));
      string_append_chars(err_str, buf);
      print_error(string_get_chars(err_str));
      string_free(err_str);
      return value_create(NULL, NULL_TYPE);
    }
  }

  // save args to env
  val_t *p_name;
  val_t *p_val;
  for (size_t i = 0; i < p_len; i++) {
    p_name = ex(queue_at(fun->params, i));
    p_val = (val_t *)queue_at(final_args, i);
    if (DEBUG)
        printf("\t%s\n", string_get_chars(p_name->val.strval)); /* not actually a function pointer */
    env_save(p_name, p_val);
  }

  val_t *res = ex(fun->body);
  res->return_val = false;

  env_pop();

  return res;
}

void opt_ast(ast_t *t) {
  // TODO functions that are never called, ...
  // TODO
  return;
  if (!t)
    return;

  for (int i = 0; i < MC; i++)
    opt_ast(t->c[i]);

  val_t *test_val;
  switch (t->type) {
  case _if:
    // dead code elimination
    opt_ast(t->c[0]), opt_ast(t->c[1]);
    if (t->c[2])
      opt_ast(t->c[2]);

    if (t->c[0]->type == val && !val2bool(t->c[0]->val)) {
      ast_free(t->c[1]);
      ast_free_outer(t);
      if (t->c[2]) {
        memcpy(t, t->c[2], sizeof *t);
      } else {
        t->type = NULL_TYPE; // TODO free?
      }
    } else if (t->c[0]->type == val && val2bool(t->c[0]->val)) {
      ast_free(t->c[2]);
      ast_free_outer(t);
      memcpy(t, t->c[1], sizeof *t);
    }
    break;
    // TODO if else, else
    // TODO dead code after return?
    // TODO implement more, per file typecheck val_type. is type necessary/ is
    // val_type...
    // TODO global add/... functions for "all" datatypes?
  case '+':
    test_val = addition(t->c[0]->val, t->c[1]->val);
    if (test_val->val_type != NULL_TYPE) {
      t->type = val;
      t->val = test_val;

      // TODO create free_a... (id has to be freed too)
      ast_free(t->c[0]);
      ast_free(t->c[1]);
      t->c[0] = t->c[1] = NULL;
    } else {
      value_free(test_val);
    }
    break;
  }
}

int main (int argc, char **argv) {
    srand(time(NULL));
    error_count = 0;
    parsing_finished = true;

    // check if file ends with .jj
    size_t str_len = strlen(argv[1]);
    if (str_len < 4 || strncmp(argv[1] + str_len - 3, ".jj", 3) != 0) {
        fprintf(stderr, "Invalid filetype. Does it end with .jj?");
    } else {
        env_push(); // create main environment
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            string *err_str = string_create("File '");
            string_append_chars(err_str, argv[1]);
            string_append_chars(err_str, "' not found");
            print_error(string_get_chars(err_str));
            string_free(err_str);
            return 1;
        }
        parsing_finished = false;
        yyparse();
        parsing_finished = true;

        if (error_count > 0) {
            fprintf(stderr, BOLD RED_COLOR "Execution Halted!" RESET_COLOR "\n");
            fprintf(stderr, RED_COLOR "Too many errors (%d) detected. Please fix them and try again." RESET_COLOR "\n", error_count);
        } else {
            ex(root);
        }
    }
}
