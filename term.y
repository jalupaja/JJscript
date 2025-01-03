%{
#include "string.h"
#include "queue.h"
#include "values.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

/* TODO
recursion (environments)
error msg on no file
change names (STMTS, ....)
implement floats
implement strings (variables...)

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

#define MC 3

struct _ast_t {
	int type;
	string *id;
    value *val;
	struct _ast_t *c[MC];
};
typedef struct _ast_t ast_t;

queue *vars;

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

var* queue_search_id(queue *q, string *id) {
    var *cur;
    ssize_t q_len = queue_len(q);
    for (ssize_t i = 0; i < q_len; i++) {
        cur = (var *) queue_at(q, i);
        if (cur != NULL && string_cmp(id, cur->id) == 0)
            return cur;
    }
    return NULL;
}

value *create_value(void *new_val, var_type val_type) {
    value *val = (value *)malloc(sizeof(value));
    switch(val_type) {
        case INT_TYPE:
            val->val.intval = *(int *)new_val;
            break;
        case FLOAT_TYPE:
            val->val.floatval = *(double *)new_val;
            break;
        case BOOL_TYPE:
            val->val.boolval  = *(bool *)new_val;
            break;
        case NULL_TYPE:
            break;
        case STRING_TYPE:
            val->val.strval = (string *)new_val;
            break;
        default:
            break;
    }
    val->val_type = val_type;

    return val;
}

void free_value(value *val) {
    if (val->val_type == STRING_TYPE) {
        // free string as it will be overwritten
        string_free(val->val.strval);
    }
    free(val);
}

void free_ast_outer(ast_t *t) {
    string_free(t->id);
    free_value(t->val);
}

void free_ast(ast_t *t) {
	if (!t) return;
    string_free(t->id);
    free_value(t->val);
	for (int i = 0; i < MC; i++) {
		free_ast(t->c[i]);
	}
}

void queue_save_val(queue *q, string *id, value *val) {
    var *cur = queue_search_id(q, id);
    if (cur != NULL) {
        // id already exists -> update value
        free_value(cur->val);
        cur->val = val;

    } else {
        // enqueue new value
        var *new = (var *) malloc(sizeof(var));
        new->id = id;
        new->val = val;
        queue_enqueue(q, new);
    }
}

ast_t *node0(int type) {
	ast_t *ret = calloc(sizeof *ret, 1);
	ret->type = type;

	return ret;
}

ast_t *node1(int type, ast_t *c1) {
	ast_t *ret = node0(type);
	ret->c[0] = c1;

	return ret;
}

ast_t *node2(int type, ast_t *c1, ast_t *c2) {
	ast_t *ret = node1(type, c1);
	ret->c[1] = c2;

	return ret;
}

ast_t *node3(int type, ast_t *c1, ast_t *c2, ast_t *c3) {
	ast_t *ret = node2(type, c1, c2);
	ret->c[2] = c3;

	return ret;
}

void print_ast (ast_t *t) {
	if (!t) return;
	printf(" ( %d ", t->type);
	for (int i = 0; i < MC; i++) {
		print_ast(t->c[i]);
	}
	printf(" ) ");
}

value *ex (ast_t *t);
void opt_ast ( ast_t *t);

enum {
	STMTS = 10000
};

%}

%union {
    string *id;
    value *val;
    int op;
    ast_t *ast;
}

%define parse.error detailed

%token _if _elif _else _while _input _le _ge _eq print <val> val <id> id <op> op

%type <ast> VAL ID STMTS STMT EXPR CONDITIONAL IFELSE

%right '='
%left '<' '>' _le _ge _eq
%left '-' '+'
%left '*' '/'
%right '^'
%%

S: STMTS { opt_ast($1); printf("\n"); print_ast($1); printf("\n"); ex($1); }

STMTS: STMTS STMT ';' { $$ = node2(STMTS, $1, $2); }
     | STMTS CONDITIONAL { $$ = node2(STMTS, $1, $2); }
     | %empty { $$ = NULL; }

STMT: VAL
    | print EXPR { $$ = node1(print, $2); }
    | id '=' EXPR { $$ = node1('=', $3); $$->id = $1; }

CONDITIONAL: _if EXPR '{' STMTS '}' IFELSE { $$ = node3(_if, $2, $4, $6); }
           | _while EXPR '{' STMTS '}' { $$ = node2(_while, $2, $4); }

IFELSE: _elif EXPR '{' STMTS '}' IFELSE { $$ = node3(_if, $2, $4, $6); }
      | _else '{' STMTS '}' { $$ = node1(_else, $3); }
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
    | '(' EXPR ')'  { $$ = $2; }
    | VAL
    | ID
    | _input { $$ = node0(_input); }

VAL: val { $$ = node0(val); $$->val = $1; }
ID:  id  { $$ = node0(id); $$->id = $1; }

%%
// TODO external file

value *addition(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    switch (a->val_type) {
        case STRING_TYPE:
            switch (b->val_type) {
                case STRING_TYPE: {
                    string *res = string_copy(a->val.strval);
                    string_append_string(res, b->val.strval);
                    return create_value(res, STRING_TYPE);
                }
                case INT_TYPE: {
                    char buffer[32];
                    snprintf(buffer, sizeof(buffer), "%d", b->val.intval);
                    string *res = string_copy(a->val.strval);
                    string_append_chars(res, buffer);
                    return create_value(res, STRING_TYPE);
                }
                case FLOAT_TYPE: {
                    char buffer[64];
                    snprintf(buffer, sizeof(buffer), "%f", b->val.floatval);
                    string *res = string_copy(a->val.strval);
                    string_append_chars(res, buffer);
                    return create_value(res, STRING_TYPE);
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
                    return create_value(res, STRING_TYPE);
                }
                case INT_TYPE: {
                    int res = a->val.intval + b->val.intval;
                    return create_value(&res, INT_TYPE);
                }
                case FLOAT_TYPE: {
                    double res = a->val.intval + b->val.floatval;
                    return create_value(&res, FLOAT_TYPE);
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
                    return create_value(res, STRING_TYPE);
                }
                case INT_TYPE: {
                    double res = a->val.floatval + b->val.intval;
                    return create_value(&res, FLOAT_TYPE);
                }
                case FLOAT_TYPE: {
                    double res = a->val.floatval + b->val.floatval;
                    return create_value(&res, FLOAT_TYPE);
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }

    printf("Unsupported add operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *subtraction(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) -
                         (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
            return create_value(&res, FLOAT_TYPE);
        } else {
            int res = a->val.intval - b->val.intval;
            return create_value(&res, INT_TYPE);
        }
    }
    printf("Unsupported sub operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *multiplication(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) *
                         (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
            return create_value(&res, FLOAT_TYPE);
        } else {
            int res = a->val.intval * b->val.intval;
            return create_value(&res, INT_TYPE);
        }
    }
    printf("Unsupported mul operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *division(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {
        if ((b->val_type == INT_TYPE && b->val.intval == 0) ||
            (b->val_type == FLOAT_TYPE && b->val.floatval == 0.0)) {
            printf("Error: Division by zero\n");
            return create_value(NULL, NULL_TYPE);
        }

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) /
                         (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
            return create_value(&res, FLOAT_TYPE);
        } else {
            int res = a->val.intval / b->val.intval;
            return create_value(&res, INT_TYPE);
        }
    }
    printf("Unsupported div operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

// TODO maybe also for string like operations?
value *less_than(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) <
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return create_value(&res, BOOL_TYPE);
    }
    printf("Unsupported less_than operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *greater_than(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) >
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return create_value(&res, BOOL_TYPE);
    }
    printf("Unsupported greater_than operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *less_equal_than(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) <=
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return create_value(&res, BOOL_TYPE);
    }
    printf("Unsupported less_equal_than operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *greater_equal_than(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) >=
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return create_value(&res, BOOL_TYPE);
    }
    printf("Unsupported greater_equal_than operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *equal(value *a, value *b) {
    // TODO strcmp, null, ...
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        bool res = (a->val_type == INT_TYPE ? a->val.intval : a->val.floatval) ==
                   (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval);
        return create_value(&res, BOOL_TYPE);
    }
    printf("Unsupported equal operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

value *power(value *a, value *b) {
    if (!a || !b) return create_value(NULL, NULL_TYPE);

    if ((a->val_type == INT_TYPE || a->val_type == FLOAT_TYPE) &&
        (b->val_type == INT_TYPE || b->val_type == FLOAT_TYPE)) {

        if (a->val_type == FLOAT_TYPE || b->val_type == FLOAT_TYPE) {
            double res = pow((a->val_type == INT_TYPE ? a->val.intval : a->val.floatval),
                             (b->val_type == INT_TYPE ? b->val.intval : b->val.floatval));
            return create_value(&res, FLOAT_TYPE);
        } else {
            int res = (int)pow(a->val.intval, b->val.intval);
            return create_value(&res, INT_TYPE);
        }
    }
    printf("Unsupported power operation between types %d and %d\n", a->val_type, b->val_type);
    return create_value(NULL, NULL_TYPE);
}

void print_value(value *val) {
    if (!val) {
        printf("> NULL\n");
        return;
    }
    switch (val->val_type) {
        case INT_TYPE:
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

int val_true(value *val) {
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

value *ex(ast_t *t) {
    if (!t)
        return create_value(NULL, NULL_TYPE);

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
        case '=': {
            value *res = ex(t->c[0]);
            queue_save_val(vars, t->id, res);
            return res;
        }
        case val:
            return t->val;
        case id: {
            var *cur = queue_search_id(vars, t->id);
            return cur ? cur->val : create_value(NULL, NULL_TYPE);
        }
        case _input: {
            // TODO default is string? or try to make double > int > bool > str
            int input = input_int();
            return create_value(&input, INT_TYPE);
        }
        case print: {
            value *val = ex(t->c[0]);
            print_value(val);
            return create_value(NULL, NULL_TYPE);
        }
        case _if:
            if (val_true(ex(t->c[0]))) {
                return ex(t->c[1]);
            } else if (t->c[2]) {
                return ex(t->c[2]);
            }
            return create_value(NULL, NULL_TYPE);
        case _else:
            return ex(t->c[0]);
        case _while:
            while (val_true(ex(t->c[0]))) {
                ex(t->c[1]);
            }
            return create_value(NULL, NULL_TYPE);
        default:
            printf("Unsupported node type %d\n", t->type);
            break;
    }

    return create_value(NULL, NULL_TYPE);
}


void opt_ast ( ast_t *t) {
	if (!t) return;

	for (int i = 0; i < MC; i++)
		opt_ast(t->c[i]);

    value *test_val;
	switch (t->type) {
        case _if:
            // dead code elimination
            opt_ast(t->c[0]), opt_ast(t->c[1]);
            if (t->c[2]) opt_ast(t->c[2]);

            if (t->c[0]->type == val && !val_true(t->c[0]->val)) {
                printf("Eliminating true case\n");
                free_ast(t->c[1]);
                free_ast_outer(t);
                if (t->c[2]) {
                    memcpy(t, t->c[2], sizeof *t);
                } else {
                    t->type = NULL_TYPE; // TODO free?
                }
            } else if (t->c[0]->type == val && val_true(t->c[0]->val)) {
                printf("Eliminating false case\n");
                free_ast(t->c[2]);
                free_ast_outer(t);
                memcpy(t, t->c[1], sizeof *t);
            }
            break;
        // TODO if else, else
        // TODO dead code after return?
        // TODO implement more, per file typecheck val_type. is type necessary/ is val_type...
        // TODO global add/... functions for "all" datatypes?
		case '+':
            test_val = addition(t->c[0]->val, t->c[1]->val);
            if (test_val->val_type != NULL_TYPE) {
				t->type = val;
				t->val = test_val;

                // TODO create free_a... (id has to be freed too)
                free_value(t->c[0]->val);
                free_value(t->c[1]->val);
				t->c[0] = t->c[1] = NULL;
			} else {
                free_value(test_val);
            }
            break;
	}
}


int main (int argc, char **argv) {
    vars = queue_create();
	yyin = fopen(argv[1], "r");
	yyparse();
}
