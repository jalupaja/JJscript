%{
#include "function.h"
#include "string.h"
#include "queue.h"
#include "value.h"
#include "value_calc.h"
#include "env.h"
#include "ast.h"

#include <stdio.h>
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

%token _if _elif _else _while
%token _return
%token _str str_start <val> str_end
%token _id id_start <val> id_end <id> _id_eval
%token <val> embed_lcurly
%token _input _inline_expr _print <val> val fun
%token assign_id assign_fun eol delim
%token _le _ge _eq
%token lbrak rbrak lsquare rsquare lcurly rcurly

%type <queue> PARAMS ARGS EMBED_STR EMBED_ID
%type <ast> VAL FUN_CALL ID ID_EVAL STMTS STMT NON_STMT EXPR IFELSE STRING

%precedence delim
%left assign
%left '<' '>' _le _ge _eq
%left '-' '+'
%left '*' '/'
%right '^'
%%

S: STMTS { opt_ast($1); if (DEBUG) printf("\n"); if (DEBUG) ast_print($1); if (DEBUG) printf("\n"); ex($1); }

STMTS: STMTS STMT eol { $$ = node2(STMTS, $1, $2); }
     | STMTS NON_STMT { $$ = node2(STMTS, $1, $2); }
     | %empty { $$ = NULL; }

STMT: _print EXPR { $$ = node1(_print, $2); }
    | ID assign EXPR { $$ = node2(assign_id, $1, $3); }
    | _return EXPR { $$ = node1(_return, $2); }
    | EXPR { $$ = node1(STMT, $1); }

NON_STMT: ID assign lcurly lbrak PARAMS rbrak STMTS rcurly { $$ = node1(assign_fun, $1); $$->val = value_create(function_create($5, $7), FUNCTION_TYPE); /* assign a function */ }
        | _if EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
        | _while EXPR lcurly STMTS rcurly { $$ = node2(_while, $2, $4); }
        | lcurly STMTS rcurly { $$ = node1(lcurly, $2); /* local environment */ }

PARAMS: PARAMS delim ID { queue_enqueue($1, $3); $$ = $1; }
      | ID { $$ = queue_create(); queue_enqueue($$, $1); }
      | %empty { $$ = queue_create(); }

ARGS: ARGS delim EXPR { queue_enqueue($1, $3); $$ = $1; }
      | EXPR { $$ = queue_create(); queue_enqueue($$, $1); }
      | %empty { $$ = queue_create(); }

IFELSE: _elif EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
      | _else lcurly STMTS rcurly { $$ = node1(_else, $3); }
      | %empty { $$ = NULL; }

EXPR: EXPR '-' EXPR { $$ = node2('-', $1, $3); }
    | EXPR '+' EXPR { $$ = node2('+', $1, $3); }
    | EXPR '*' EXPR { $$ = node2('*', $1, $3); }
    | EXPR '/' EXPR { $$ = node2('/', $1, $3); }
    | EXPR _le EXPR { $$ = node2(_le, $1, $3); }
    | EXPR _ge EXPR { $$ = node2(_ge, $1, $3); }
    | EXPR _eq EXPR { $$ = node2(_eq, $1, $3); }
    | EXPR '<' EXPR { $$ = node2('<', $1, $3); }
    | EXPR '>' EXPR { $$ = node2('>', $1, $3); }
    | EXPR '^' EXPR { $$ = node2('^', $1, $3); }
    | lbrak EXPR rbrak  { $$ = $2; }
    | VAL
    | FUN_CALL
    | ID_EVAL
    | STRING
    | _input STRING { $$ = node0(_input); $$->val = $2->val; }
    | _input { $$ = node0(_input); }

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
    while (queue_len(segments) > 0) {

        prefix = (string *)queue_dequeue(segments);
        emb = (ast_t *)queue_dequeue(segments);
        suffix = (string *)queue_dequeue(segments);

        res = ex(emb);

        string_append_string(str, prefix);
        string_append_string(str, val2string(res));
        string_append_string(str, suffix);

        string_free(prefix);
        string_free(suffix);
    }
    queue_free(segments);

    env_pop();
    return str;
}

val_t *ex(ast_t *t) {
    if (!t)
        return value_create(NULL, NULL_TYPE);

    switch (t->type) {
        case STMTS:
            val_t *res = ex(t->c[0]);

            if (res->return_val) {
                res->return_val = false;
                return res;
            } else {
                return ex(t->c[1]);
            }
        case STMT:
            return ex(t->c[0]);
        case _return:
            val_t *ret = ex(t->c[0]);
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
        case assign_id: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            val_t *res = ex(t->c[1]);
            if (DEBUG)
                printf("assign_id: %s = %s\n", string_get_chars(id), string_get_chars(val2string(res)));
            // TODO value_free(id_val);
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
        case fun: {
            val_t *id_val = ex(t->c[0]);
            string *id = id_val->val.strval;

            var_t *cur = env_search(id);
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
            var_t *cur = env_search(str);

            // TODO maybe crash if id is not assigned yet?
            return cur ? cur->val : value_create(NULL, NULL_TYPE);
        }
        case lcurly: {
            // local environment
            env_push();
            ex(t->c[0]);
            env_pop();
            return NULL;
        }
        case _input: {
            // TODO default is string? or try to make double > int > bool > str
            if (t->val)
                value_print(t->val);
            return value_read();
        }
        case _print: {
            val_t *val = ex(t->c[0]);
            printf("> ");
            value_print(val);
            printf("\n");
            return value_create(NULL, NULL_TYPE);
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
  var_t *var = env_search(id);

  if (!var || var->val->val_type != FUNCTION_TYPE) {
    // TODO actual error. also below
    printf("Error: '%s' is not a function \n", string_get_chars(id));
    return value_create(NULL, NULL_TYPE);
  }

  fun_t *fun = var->val->val.funval;

  // start new environment
  env_push();

  ssize_t p_len = queue_len(fun->params);
  if (queue_len(args) != p_len) {
    printf("Error: Function '%s' expected %zd arguments but got %zd\n",
           string_get_chars(id), p_len, queue_len(args));
    // return value_create(NULL, NULL_TYPE);
  }

  // save args to env
  val_t *p_name_val;
  string *p_name;
  val_t *p_val;
  for (ssize_t i = 0; i < p_len; i++) {
    p_name_val = ex(queue_at(fun->params, i));
    p_name = p_name_val->val.strval;
    p_val = (val_t *)queue_at(args, i);
    if (DEBUG)
        printf("\t%s\n", string_get_chars(p_name)); /* not actually a function pointer */
    env_save(p_name, p_val);
  }

  val_t *res = ex(fun->body);

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
	yyparse();
}
