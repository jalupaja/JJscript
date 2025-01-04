%{
#include "function.h"
#include "embed.h"
#include "string.h"
#include "queue.h"
#include "value.h"
#include "value_calc.h"
#include "env.h"
#include "ast.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define DEBUG 0

/* TODO
recursion (environments)
for
error msg on no file
implement strings (variables...)

multi line strings, ... (old exercises)

return?
bools

make bs
*/


int yydebug=0;
extern FILE *yyin;
int yylex (void);
void yyerror (const char *msg) {
    fprintf(stderr, "Parse error: %s\n", msg);
    exit(EXIT_FAILURE);
}


// TODO what
int exec = 0;
#define EXEC if (exec == 0)

string *input() {
    string *str = string_create(NULL);

    int ch;
    while ((ch = getchar()) != '\n' && ch != EOF) {
        string_append_char(str, (char)ch);
    }

    return str;
}

int input_int() {
    string *str = input();
    int ret = (int)strtol(string_get_chars(str), NULL, 8); // OCTAL
    // int ret = atoi(string_get_chars(str));
    string_free(str);
    return ret;
}

double input_float() {
    string *str = input();
    double ret = atof(string_get_chars(str));
    string_free(str);
    return ret;
}

char *input_chars() {
    string *str = input();

    char *ret = malloc(str->length + 1);
    strcpy(ret, string_get_chars(str));

    string_free(str);
    return ret;
}

typedef struct ast_t ast_t;
val_t *ex (ast_t *t);
val_t *fun_call(string *id, queue *args);
void opt_ast ( ast_t *t);

enum {
	STMTS = 10000
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
%token _str str_start str_part <val> embed_lcurly str_end
%token _input _inline_expr _print <val> val fun <id> _id
%token assign_id assign_fun eol delim
%token _le _ge _eq
%token lbrak rbrak lsquare rsquare lcurly rcurly

%type <queue> PARAMS ARGS
%type <ast> VAL FUN_CALL ID STMTS STMT NON_STMT EXPR IFELSE STRING EMBEDS

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
    | _id assign EXPR { $$ = node1(assign_id, $3); $$->id = $1; }

NON_STMT: _id assign lcurly lbrak PARAMS rbrak STMTS rcurly { $$ = node0(assign_fun), $$->id = $1; $$->val = value_create(function_create($5, $7), FUNCTION_TYPE); /* assign a function */ }
        | _if EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
        | _while EXPR lcurly STMTS rcurly { $$ = node2(_while, $2, $4); }

PARAMS: PARAMS delim ID { queue_enqueue($1, $3->id); $$ = $1; }
      | ID { $$ = queue_create(); queue_enqueue($$, $1->id); }
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
    | lcurly STMTS rcurly { $$ = node1(lcurly, $2); /* local environment */ }
    | VAL
    | FUN_CALL
    | ID
    | STRING
    | _input { $$ = node0(_input); }

STRING: str_start EMBEDS str_end { $$ = node0(_str);
      // TODO need beginning string here
              string *str = string_copy($3->val.strval);
              $$->val = value_create(embed_create($2, str, STRING_TYPE), EMBED_TYPE);
                        // ast_free($1); // TODO
                        // ast_free($3); // TODO
                        // TODO allow more then one EMBED
              }

EMBEDS: embed_lcurly EXPR rcurly { $$ = $2; }
      | %empty { $$ = NULL; }

VAL:      val { $$ = node0(val); $$->val = $1; }
FUN_CALL: _id lbrak ARGS rbrak { $$ = node0(fun); $$->id = $1; $$->val = value_create($3, QUEUE_TYPE); /* function call */ }
ID:       _id  { $$ = node0(_id); $$->id = $1; }

%%
// TODO external file

val_t *ex(ast_t *t) {
    if (!t)
        return value_create(NULL, NULL_TYPE);

    switch (t->type) {
        case STMTS:
            ex(t->c[0]);
            return ex(t->c[1]);
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
            val_t *res = ex(t->c[0]);
            env_save(t->id, res);
            return res;
        }
        case assign_fun: {
            env_save(t->id, t->val);
            return t->val;
        }
        case _str: {
            // TODO missing string from str_start
            // TODO
            emb_t *emb = t->val->val.embval;

            if (emb->embeds) {
                env_push();

                val_t *suffix = ex(emb->embeds);
                value_print(suffix);
                string *str = val2string(suffix);

                env_pop();
                value_free(suffix);

                string_append_string(str, emb->str_end);
                // embed_free(emb); // TODO
                return value_create(str, STRING_TYPE);
            } else {
                return value_create(emb->str_end, STRING_TYPE);
            }
        }
        case val:
            return t->val;
        case fun: {
            var_t *cur = env_search(t->id);
            if (!cur || cur->val->val_type != FUNCTION_TYPE) {
                fprintf(stderr, "Error: Undefined or invalid function %s\n", string_get_chars(t->id));
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

            val_t *result = fun_call(t->id, new_args);

            queue_free(new_args);

            return result;
        }
        case _id: {
            var_t *cur = env_search(t->id);
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
            int input = input_int();
            return value_create(&input, INT_TYPE);
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
  for (ssize_t i = 0; i < p_len; i++) {
    string *p_name = (string *)queue_at(fun->params, i);
    val_t *p_val = (val_t *)queue_at(args, i);
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
      value_free(t->c[0]->val);
      value_free(t->c[1]->val);
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
