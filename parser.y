%{
#include "string.h"
#include "queue.h"
#include "value.h"
#include "env.h"
#include "ast.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define DEBUG 1

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

val_t *ex (ast_t *t);
void opt_ast ( ast_t *t);
void env_pop();

enum {
	STMTS = 10000
};

%}

%union {
    string *id;
    val_t *val;
    ast_t *ast;
}

%define parse.error detailed

%token _if _elif _else _while
%token _input _inline_expr _print <val> val <id> id
%token assign eol
%token _le _ge _eq
%token lbrak rbrak lsquare rsquare lcurly rcurly

%type <ast> VAL ID STMTS STMT EXPR CONDITIONAL IFELSE

%right assign
%left '<' '>' _le _ge _eq
%left '-' '+'
%left '*' '/'
%right '^'
%%

S: STMTS { opt_ast($1); printf("\n"); print_ast($1); printf("\n"); ex($1); }

STMTS: STMTS STMT eol { $$ = node2(STMTS, $1, $2); }
     | STMTS CONDITIONAL { $$ = node2(STMTS, $1, $2); }
     | %empty { $$ = NULL; }

STMT: _print EXPR { $$ = node1(_print, $2); }
    | id assign EXPR { $$ = node1(assign, $3); $$->id = $1; }

CONDITIONAL: lcurly STMTS rcurly { $$ = node1(lcurly, $2); }
           | _if EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
           | _while EXPR lcurly STMTS rcurly { $$ = node2(_while, $2, $4); }

IFELSE: _elif EXPR lcurly STMTS rcurly IFELSE { $$ = node3(_if, $2, $4, $6); }
      | _else lcurly STMTS rcurly { $$ = node1(_else, $3); }
      | %empty { $$ = NULL; }

EXPR:
      EXPR '-' EXPR { $$ = node2('-', $1, $3); }
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
    | ID
    | _input { $$ = node0(_input); }

VAL: val { $$ = node0(val); $$->val = $1; }
ID:  id  { $$ = node0(id); $$->id = $1; }

%%
// TODO external file

val_t *addition(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    switch (a->val_type) {
        case STRING_TYPE:
            switch (b->val_type) {
                case STRING_TYPE: {
                    string *res = string_copy(a->val.strval);
                    string_append_string(res, b->val.strval);
                    return value_create(res, STRING_TYPE);
                }
                case INT_TYPE: {
                    char buffer[32];
                    snprintf(buffer, sizeof(buffer), "%d", b->val.intval);
                    string *res = string_copy(a->val.strval);
                    string_append_chars(res, buffer);
                    return value_create(res, STRING_TYPE);
                }
                case FLOAT_TYPE: {
                    char buffer[64];
                    snprintf(buffer, sizeof(buffer), "%f", b->val.floatval);
                    string *res = string_copy(a->val.strval);
                    string_append_chars(res, buffer);
                    return value_create(res, STRING_TYPE);
                }
                default:
                    break;
            }
            break;
        case INT_TYPE:
            switch (b->val_type) {
                case STRING_TYPE: {
                    char buffer[32];
                    snprintf(buffer, sizeof(buffer), "%d", a->val.intval);
                    string *res = string_create(buffer);
                    string_append_string(res, b->val.strval);
                    return value_create(res, STRING_TYPE);
                }
                case INT_TYPE: {
                    int res = a->val.intval + b->val.intval;
                    return value_create(&res, INT_TYPE);
                }
                case FLOAT_TYPE: {
                    double res = a->val.intval + b->val.floatval;
                    return value_create(&res, FLOAT_TYPE);
                }
                default:
                    break;
            }
            break;
        case FLOAT_TYPE:
            switch (b->val_type) {
                case STRING_TYPE: {
                    char buffer[64];
                    snprintf(buffer, sizeof(buffer), "%f", a->val.floatval);
                    string *res = string_create(buffer);
                    string_append_string(res, b->val.strval);
                    return value_create(res, STRING_TYPE);
                }
                case INT_TYPE: {
                    double res = a->val.floatval + b->val.intval;
                    return value_create(&res, FLOAT_TYPE);
                }
                case FLOAT_TYPE: {
                    double res = a->val.floatval + b->val.floatval;
                    return value_create(&res, FLOAT_TYPE);
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }

    printf("Unsupported add operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *subtraction(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) -
                         (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
            return value_create(&res, FLOAT_TYPE);
        } else {
            int res = a->val.intval - b->val.intval;
            return value_create(&res, INT_TYPE);
        }
    }
    printf("Unsupported sub operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *multiplication(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) *
                         (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
            return value_create(&res, FLOAT_TYPE);
        } else {
            int res = a->val.intval * b->val.intval;
            return value_create(&res, INT_TYPE);
        }
    }
    printf("Unsupported mul operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *division(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {
        if ((b->val_type == INT_TYPE && b->val.intval == 0) ||
            (b->val_type == FLOAT_TYPE && b->val.floatval == 0.0)) {
            printf("Error: Division by zero\n");
            return value_create(NULL, NULL_TYPE);
        }

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) /
                         (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
            return value_create(&res, FLOAT_TYPE);
        } else {
            int res = a->val.intval / b->val.intval;
            return value_create(&res, INT_TYPE);
        }
    }
    printf("Unsupported div operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

// TODO maybe also for string like operations?
val_t *less_than(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) <
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return value_create(&res, BOOL_TYPE);
    }
    printf("Unsupported less_than operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *greater_than(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) >
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return value_create(&res, BOOL_TYPE);
    }
    printf("Unsupported greater_than operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *less_equal_than(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) <=
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return value_create(&res, BOOL_TYPE);
    }
    printf("Unsupported less_equal_than operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *greater_equal_than(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) >=
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return value_create(&res, BOOL_TYPE);
    }
    printf("Unsupported greater_equal_than operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *equal(val_t *a, val_t *b) {
    // TODO strcmp, null, ...
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) ==
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return value_create(&res, BOOL_TYPE);
    }
    printf("Unsupported equal operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

val_t *power(val_t *a, val_t *b) {
    if (!a || !b) return value_create(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = pow((a->val_type == INT_TYPE ? a->val.intval : a->val.floatval),
                             (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval));
            return value_create(&res, FLOAT_TYPE);
        } else {
            int res = (int)pow(a->val.intval, b->val.intval);
            return value_create(&res, INT_TYPE);
        }
    }
    printf("Unsupported power operation between types %d and %d\n", a->val_type, b->val_type);
    return value_create(NULL, NULL_TYPE);
}

void print_value(val_t *val) {
    if (!val) {
        printf("> NULL\n");
        return;
    }
    switch (val->val_type) {
        case INT_TYPE:
            // Apparently printf can't print negative numbers
            if (val->val.intval < 0)
                printf("> -%o\n", -val->val.intval); // OCTAL
            else
                printf("> %o\n", val->val.intval); // OCTAL
            break;
        case FLOAT_TYPE:
            printf("> %f\n", val->val.floatval);
            break;
        case STRING_TYPE:
            printf("> %s\n", string_get_chars(val->val.strval));
            break;
        case BOOL_TYPE:
            printf("> %s\n", val->val.boolval ? "true" : "false");
            break;
        case NULL_TYPE:
            printf("> NULL\n");
            break;
        default:
            printf("> Unknown type\n");
            break;
    }
}

int val_true(val_t *val) {
    switch(val->val_type) {
        case INT_TYPE:
            return val->val.intval != 0;
            break;
        case FLOAT_TYPE:
            return val->val.floatval != 0.0;
            break;
        case BOOL_TYPE:
            return val->val.boolval;
            break;
        case NULL_TYPE:
            return false;
            break;
        case STRING_TYPE:
            string *str = val->val.strval;
            return str == NULL || string_char_at(str, 0) == '\0';
            break;
        default:
            printf("Unsupported value type(val_true)");
            break;
    }
    return false;
}

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
        case assign: {
            val_t *res = ex(t->c[0]);
            env_save(t->id, res);
            return res;
        }
        case val:
            return t->val;
        case id: {
            var_t *cur = env_search(t->id);
            return cur ? cur->val : value_create(NULL, NULL_TYPE);
        }
        case lcurly: {
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
            print_value(val);
            return value_create(NULL, NULL_TYPE);
        }
        case _if:
            if (val_true(ex(t->c[0]))) {
                return ex(t->c[1]);
            } else if (t->c[2]) {
                return ex(t->c[2]);
            }
            return value_create(NULL, NULL_TYPE);
        case _else:
            return ex(t->c[0]);
        case _while:
            while (val_true(ex(t->c[0]))) {
                ex(t->c[1]);
            }
            return value_create(NULL, NULL_TYPE);
        default:
            printf("Unsupported node type %d\n", t->type);
            break;
    }

    return value_create(NULL, NULL_TYPE);
}

void opt_ast(ast_t *t) {
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

    if (t->c[0]->type == val && !val_true(t->c[0]->val)) {
      printf("Eliminating true case\n");
      ast_free(t->c[1]);
      ast_free_outer(t);
      if (t->c[2]) {
        memcpy(t, t->c[2], sizeof *t);
      } else {
        t->type = NULL_TYPE; // TODO free?
      }
    } else if (t->c[0]->type == val && val_true(t->c[0]->val)) {
      printf("Eliminating false case\n");
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
