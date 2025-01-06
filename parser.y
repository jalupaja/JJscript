%{
#include "function.h"
#include "string.h"
#include "queue.h"
#include "value.h"
#include "value_calc.h"
#include "env.h"
#include "ast.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#define DEBUG 0

int yydebug=0;
extern FILE *yyin;
int yylex (void);
void yyerror (const char *msg) {
    fprintf(stderr, "Parse error: %s\n", msg);
    exit(EXIT_FAILURE);
}

typedef struct ast_t ast_t;
val_t *ex (ast_t *t);
val_t *fun_call(string *id, queue *args);
void opt_ast ( ast_t *t);

enum {
    STMTS = 10000,
    STMT,
};

%}

%union {
    string *id;
    val_t *val;
    ast_t *ast;
    queue *queue;
}

%define parse.error detailed

%token _if _elif _else _while _for
%token _return
%token _str str_start <val> str_end
%token _id id_start <val> id_end <id> _id_eval
%token _arr <val> _range _arr_call _arr_eval
%token <val> embed_lcurly
%token _input _inline_expr _print _printl <val> val fun
%token assign_id assign_fun eol delim
%token lbrak rbrak lsquare rsquare lcurly rcurly

%type <queue> PARAMS ARGS EMBED_STR EMBED_ID
%type <ast> VAL LIST FUN_CALL ID ID_EVAL STMTS STMT NON_STMT EXPR IFELSE STRING

%left delim
%left assign assign_add assign_sub assign_mul assign_div assign_mod
%left '<' '>' _le _ge _eq _eq_a _eq_s _eq_m _eq_d _eq_mod
%left '&' '|' colon double_colon
%left '-' '+' _aa _ss
%left '*' '/' '%'
%right '^'
%right '!' _len
%left _split

%%

S: STMTS { opt_ast($1); if (DEBUG) printf("\n"); if (DEBUG) ast_print($1); if (DEBUG) printf("\n"); ex($1); }

STMTS: STMTS STMT eol { $$ = node2(STMTS, $1, $2); }
     | STMTS NON_STMT { $$ = node2(STMTS, $1, $2); }
     | %empty { $$ = NULL; }

STMT: ID assign EXPR { $$ = node2(assign_id, $1, $3); }
    | ID assign_add EXPR { $$ = node2(assign_add, $1, $3); }
    | ID assign_sub EXPR { $$ = node2(assign_sub, $1, $3); }
    | ID assign_mul EXPR { $$ = node2(assign_mul, $1, $3); }
    | ID assign_div EXPR { $$ = node2(assign_div, $1, $3); }
    | ID assign_mod EXPR { $$ = node2(assign_mod, $1, $3); }
    | ID _aa { $$ = node1(_aa, $1); }
    | ID _ss { $$ = node1(_ss, $1); }
    | _print lbrak EXPR rbrak { $$ = node1(_print, $3); }
    | _printl lbrak EXPR rbrak { $$ = node1(_printl, $3); }
    | _print lbrak rbrak { $$ = node1(_print, NULL); }
    | _printl lbrak rbrak { $$ = node1(_printl, NULL); }
    | _return lbrak rbrak { $$ = node1(_return, NULL); }
    | _return lbrak EXPR rbrak { $$ = node1(_return, $3); }
    | EXPR { $$ = node1(STMT, $1); }

NON_STMT: ID assign lcurly lbrak PARAMS rbrak STMTS rcurly { $$ = node1(assign_fun, $1); $$->val = value_create(function_create($5, $7), FUNCTION_TYPE); /* assign a function */ }
        | _if EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
        | _while EXPR lcurly STMTS rcurly { $$ = node2(_while, $2, $4); }
        | _for ID colon EXPR lcurly STMTS rcurly { $$ = node3(_for, $2, $4, $6); }
        | _for lbrak ID colon EXPR rbrak lcurly STMTS rcurly { $$ = node3(_for, $3, $5, $8); }
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
    | EXPR '-' EXPR { $$ = node2('-', $1, $3); }
    | EXPR '+' EXPR { $$ = node2('+', $1, $3); }
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
    | EXPR colon EXPR { $$ = node3(_range, $1, $3, NULL); }
    | EXPR double_colon EXPR double_colon EXPR { $$ = node3(_range, $1, $3, $5); }
    | '!' EXPR { $$ = node1('!', $2); }
    | lbrak EXPR rbrak  { $$ = $2; }
    | VAL
    | LIST
    | FUN_CALL
    | ID_EVAL
    | STRING
    | _input lbrak STRING rbrak { $$ = node0(_input); $$->val = $3->val; }
    | _input lbrak rbrak { $$ = node0(_input); }
    | _len lbrak EXPR rbrak { $$ = node1(_len, $3); }
    | _split lbrak EXPR delim EXPR delim rbrak { $$ = node2(_split, $3, $5); /* range with trailing comma */ }
    | _split lbrak EXPR delim EXPR rbrak { $$ = node2(_split, $3, $5); /* range */ }
    | _split lbrak EXPR rbrak { $$ = node2(_split, $3, NULL); }


LIST: lsquare ARGS rsquare { $$ = node0(_arr); $$->val = value_create($2, QUEUE_TYPE); }

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
        | ID lsquare EXPR rsquare { /* TODO theoretically remove, if _arr_call returns the pointer?/ id +index */ $$ = node2(_arr_eval, $1, $3); }

ID:       id_start id_end { $$ = node0(_id); $$->val = $2; }
        | id_start EMBED_ID  { $$ = node0(_id); $$->val = value_create($2, QUEUE_TYPE); /* TODO | ID lsquare EXPR rsquare { $$ = node2(_arr_call, $1, $3); */ }

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
// TODO external file
string *join_embeds(queue *segments) {
    string *str = string_create(NULL);

    env_push();

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

    env_pop();
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
        case _return:
            val_t *ret;
            if (t->c[0]) {
                ret = ex(t->c[0]);
            } else {
                ret = value_create(NULL, NULL_TYPE);
            }
            ret->return_val = true;
            return ret;
        case '+':
            return addition(ex(t->c[0]), ex(t->c[1]));
        case '-':
            return subtraction(ex(t->c[0]), ex(t->c[1]));
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
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *res = ex(t->c[1]);
            if (DEBUG)
                printf("assign_id: %s = %s\n", string_get_chars(id), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_add: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *val = ex(t->c[1]);

            env_var_t *cur = env_search(id);
            val_t *res = addition(cur->val, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_add: %s += %s\n", string_get_chars(id), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case _aa: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            int one = 1;
            val_t *val = value_create(&one, INT_TYPE);

            env_var_t *cur = env_search(id);
            val_t *res = addition(cur->val, val);

            value_free(val);

            if (DEBUG)
                printf("assign_++: %s\n", string_get_chars(id));
            env_save(id, res);
            return res;
        }
        case assign_sub: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *val = ex(t->c[1]);

            env_var_t *cur = env_search(id);
            val_t *res = subtraction(cur->val, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_sub: %s += %s\n", string_get_chars(id), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case _ss: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            int one = 1;
            val_t *val = value_create(&one, INT_TYPE);

            env_var_t *cur = env_search(id);
            val_t *res = subtraction(cur->val, val);

            value_free(val);

            if (DEBUG)
                printf("assign_--: %s\n", string_get_chars(id));
            env_save(id, res);
            return res;
        }
        case assign_mul: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *val = ex(t->c[1]);

            env_var_t *cur = env_search(id);
            val_t *res = multiplication(cur->val, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_mul: %s += %s\n", string_get_chars(id), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_div: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *val = ex(t->c[1]);

            env_var_t *cur = env_search(id);
            val_t *res = division(cur->val, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_div: %s += %s\n", string_get_chars(id), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_mod: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *val = ex(t->c[1]);

            env_var_t *cur = env_search(id);
            val_t *res = modulo(cur->val, val);

            // TODO? value_free(val);

            if (DEBUG)
                printf("assign_mod: %s += %s\n", string_get_chars(id), string_get_chars(val2string(res)));
            env_save(id, res);
            return res;
        }
        case assign_fun: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

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
        case _arr: {
            queue *old_elems = t->val->val.qval;
            queue *new_elems = queue_create();

            size_t q_len = queue_len(old_elems);
            for (size_t i = 0; i < q_len; i++) {
                val_t *new_val = ex((ast_t *)queue_at(old_elems, i));
                queue_enqueue(new_elems, new_val);
            }

            val_t *ret = value_create(new_elems, QUEUE_TYPE);
            if (DEBUG) {
                printf("LIST ELEMENTS: %s\n", string_get_chars(val2string(ret)));
            }
            return ret;
        }
        case _arr_call: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;
            // TODO env_save_at
            env_var_t *cur = env_search(id);
            val_t *at = ex(t->c[1]);

            return value_at(cur->val, val2int(at));
        }
        case _arr_eval: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;
            env_var_t *cur = env_search(id);
            val_t *at = ex(t->c[1]);

            return value_at(cur->val, val2int(at));
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
                fprintf(stderr, "The start of the range can't be higher then the end.");
                return value_create(NULL, NULL_TYPE);
            }

            val_t *ret;
            if (left->val_type == STRING_TYPE || right->val_type == STRING_TYPE) {
                string *str = string_create(NULL);
                if ((int)step == 0)
                    step += 1;
                for (char l = val2int(left); l < val2float(right); l += (int)step) {
                    string_append_char(str, l);
                }
                ret = value_create(str, STRING_TYPE);
            } else {
                queue *q = queue_create();
                if (left->val_type == FLOAT_TYPE || (int)step != step) {
                    for (double l = val2float(left); l < val2float(right); l += step) {
                        queue_enqueue(q, value_create(&l, FLOAT_TYPE));
                    }
                } else {
                    if ((int)step == 0)
                        step += 1;
                    for (long l = val2int(left); l < val2float(right); l += (int)step) {
                        queue_enqueue(q, value_create(&l, INT_TYPE));
                    }
                }
                ret = value_create(q, QUEUE_TYPE);
            }

            return ret;
        }
        case fun: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            env_var_t *cur = env_search(id);
            if (!cur || cur->val->val_type != FUNCTION_TYPE) {
                fprintf(stderr, "Error: Undefined or invalid function %s\n", string_get_chars(id));
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

            val_t *result = fun_call(id, new_args);

            queue_free(new_args);

            return result;
        }
        case _id: {
            string *str;

            if (t->val->val_type == STRING_TYPE) {
                str = t->val->val.strval;
            } else if (t->val->val_type == QUEUE_TYPE) {
                queue *segments = t->val->val.qval;
                str = join_embeds(segments);
            } else {
                printf("ERROR in _id. This can't happen\n");
                return value_create(NULL, NULL_TYPE);
            }

            return value_create(str, STRING_TYPE);
        }
        case _id_eval: {
            val_t *id_val = ex(t->c[0]);
            string *str = id_val->val.strval;
            env_var_t *cur = env_search(str);

            if (cur) {
                return cur->val;
            } else {
                // TODO maybe crash if id is not assigned yet?
                fprintf(stderr, "ID '%s' not found!\n", string_get_chars(str));
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
            if (t->val)
                value_print(t->val);
            return value_read();
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

            queue *ret;
            if (val->val_type == STRING_TYPE) {
                ret = string_split(val->val.strval, delim);
            } else if (val->val_type == QUEUE_TYPE) {
                ret = queue_copy(val->val.qval);
            } else {
                ret = queue_create();
                queue_enqueue(ret, val);
            }
            return value_create(ret, QUEUE_TYPE);
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
        case _while:
            while (val2bool(ex(t->c[0]))) {
                ex(t->c[1]);
            }
            return value_create(NULL, NULL_TYPE);
        case _for: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *expr = ex(t->c[1]);

            size_t expr_len = value_len(expr);
            val_t *cur;
            for (size_t i = 0; i < expr_len; i++) {
                cur = value_at(expr, i);
                env_save(id, value_copy(cur));
                ex(t->c[2]);
            }

            return value_create(NULL, NULL_TYPE);
        }
        default:
            // TODO ERROR
            printf("Unsupported node type %d\n", t->type);
            break;
    }

    return value_create(NULL, NULL_TYPE);
}

val_t *fun_call(string *id, queue *args) {
  if (DEBUG)
      printf("fun_call (%s) with %ld args\n", string_get_chars(id), queue_len(args));
  // search function
  env_var_t *var = env_search(id);

  if (!var || var->val->val_type != FUNCTION_TYPE) {
    // TODO actual error. also below
    printf("Error: '%s' is not a function \n", string_get_chars(id));
    return value_create(NULL, NULL_TYPE);
  }

  fun_t *fun = var->val->val.funval;

  // start new environment
  env_push();

  size_t p_len = queue_len(fun->params);
  if (queue_len(args) != p_len) {
    printf("Error: Function '%s' expected %zd arguments but got %zd\n",
           string_get_chars(id), p_len, queue_len(args));
    // return value_create(NULL, NULL_TYPE);
  }

  // save args to env
  val_t *p_name_val;
  string *p_name;
  val_t *p_val;
  for (size_t i = 0; i < p_len; i++) {
    p_name_val = ex(queue_at(fun->params, i));
    p_name = p_name_val->val.strval;
    p_val = (val_t *)queue_at(args, i);
    if (DEBUG)
        printf("\t%s\n", string_get_chars(p_name)); /* not actually a function pointer */
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
    env_push(); // create main environment
	yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "File '%s' not found!\n", argv[1]);
        return 1;
    }
    yyparse();
}
