%{
#include "string.h"
#include "queue.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

int yydebug=0;
extern FILE *yyin;
int yylex (void);
void yyerror (const char *msg) {
    fprintf(stderr, "Parse error: %s\n", msg);
    exit(EXIT_FAILURE);
}

typedef enum { INT_TYPE, FLOAT_TYPE, BOOL_TYPE, NULL_TYPE, STRING_TYPE, EMPTY_TYPE } var_type;

union data_value {
    int intval;
    double floatval;
    bool boolval;
    string *strval;
};

typedef struct {
    union data_value val;
    var_type val_type;
    // TODO check all var_types...
} value;


typedef struct {
    string *id;
    value *val;
} var;

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
    // TODO octal
    return atoi(string_get_chars(input()));
}

int input_float() {
    return atof(string_get_chars(input()));
}

char *input_chars() {
    return string_get_chars(input());
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
            val->val.floatval = *(float *)new_val;
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

int exec = 0;
#define EXEC if (exec == 0)

#define MC 3

struct ast {
	int type;
	string *id;
    value *val;
	struct ast *c[MC];
};

typedef struct ast ast_t;

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

// TODO WTF
enum {
	STMTS = 10000
};

void print_ast (ast_t *t) {
	if (!t) return;
	printf(" ( %d ", t->type);
	for (int i = 0; i < MC; i++) {
		print_ast(t->c[i]);
	}
	printf(" ) ");
}

int ex (ast_t *t);
void opt_ast ( ast_t *t);

// TODO maybe not num but value?
%}

%union {
	int num;
	string *id;
	string *str;
	int op;
	ast_t *ast;
}

%define parse.error detailed

%token _if _else _while _input print <num> num <id> id <op> op <str> str

%type <ast> TERM NUMORID NUM ID STMTS STMT

%right '='
%left '<'
%left '-' '+'
%left '*' '/'
%right '^'
%%

S: STMTS { opt_ast($1); printf("\n"); print_ast($1); printf("\n"); ex($1); }

STMTS: STMTS STMT ';' { $$ = node2(STMTS, $1, $2); }
 | %empty { $$ = NULL; }

STMT: TERM
        | print str { $$ = node0(print); $$->val = create_value($2, STRING_TYPE); }
		| print TERM { $$ = node1(print, $2); }
		| _if TERM '{' STMTS '}' _else '{' STMTS '}'
		  { $$ = node3(_if, $2, $4, $8); }
		| _while TERM '{' STMTS '}' { $$ = node2(_while, $2, $4); }

TERM:
      TERM '-' TERM { $$ = node2('-', $1, $3); }
    | TERM '+' TERM { $$ = node2('+', $1, $3); }
    | TERM '*' TERM { $$ = node2('*', $1, $3); }
    | TERM '/' TERM { $$ = node2('/', $1, $3); }
    | TERM '<' TERM { $$ = node2('<', $1, $3); }
    | TERM '^' TERM { $$ = node2('^', $1, $3); }
    | '(' TERM ')'  { $$ = $2; }
    | NUMORID
    | id '=' TERM { $$ = node1('=', $3); $$->id = $1; }
    | _input { $$ = node0(_input); }

NUMORID: NUM
       | ID

NUM: num { $$ = node0(num); $$->val = create_value(&$1, INT_TYPE); }
ID:  id  { $$ = node0(id); $$->id = $1; }

%%

int ex (ast_t *t) {
	if (!t)
		return 0;

	switch (t->type) {
		case STMTS:
			return ex(t->c[0]), ex(t->c[1]);
		case '+':
			return ex(t->c[0]) + ex(t->c[1]);
		case '-':
			return ex(t->c[0]) - ex(t->c[1]);
		case '*':
			return ex(t->c[0]) * ex(t->c[1]);
		case '/':
			return ex(t->c[0]) / ex(t->c[1]);
		case '<':
			return ex(t->c[0]) < ex(t->c[1]);
		case '^':
			return pow(ex(t->c[0]), ex(t->c[1]));
		case '=':
            // TODO allow different types
            // TODO void* wrong?
            int res = ex(t->c[0]);
            value *val = create_value(&res, INT_TYPE);

            queue_save_val(vars, t->id, val);

            return val->val.intval;
			// return vars[(int) t->id[0]] = ex(t->c[0]);
		case num:
			return t->val->val.intval;
		case id:
            // TODO different datatypes (or just return val??? -> type for later)
            var *cur = queue_search_id(vars, t->id);
            return cur->val->val.intval;
			// return vars[(int) t->id[0]];
		case _input:
			return input_int();
		case print:
            // TODO wtf
			if (t->c[0] == NULL)
				printf("> %s\n", string_get_chars(t->val->val.strval));
			else
				printf("> %d\n", ex(t->c[0]));
			return 0;
		case _if:
			if (ex(t->c[0]))
				return ex(t->c[1]);
			else
				return ex(t->c[2]);
		case _while:
			while (ex(t->c[0]))
				ex(t->c[1]);
			return 0;
		default:
			printf("Unsupported node type %d\n", t->type);
			break;
	}

	return 0;
}

int val2bool(value *val) {
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
            printf("Unsupported value type(val2bool)");
            break;
    }
    return false;
}

void opt_ast ( ast_t *t) {
	if (!t) return;

	for (int i = 0; i < MC; i++)
		opt_ast(t->c[i]);

	switch (t->type) {
        case _if:
            // dead code elimination
            opt_ast(t->c[0]), opt_ast(t->c[1]), opt_ast(t->c[2]);
            // TODO type
            if (t->c[0]->type == num && !val2bool(t->c[0]->val)) {
                printf("Eliminating true case\n");
                memcpy(t, t->c[2], sizeof *t);
            } else if (t->c[0]->type == num && val2bool(t->c[0]->val)) {
                printf("Eliminating false case\n");
                memcpy(t, t->c[1], sizeof *t);
            }
            break;
        // TODO if else, else
        // TODO dead code after return?
        // TODO implement more, per file typecheck val_type. is type necessary/ is val_type...
        // TODO global add/... functions for "all" datatypes?
		case '+':
			if (t->c[0]->type == num && t->c[1]->type == num) {
				t->type = num;
				t->val->val.intval = t->c[0]->val->val.intval + t->c[1]->val->val.intval;

                free_value(t->c[0]->val);
                free_value(t->c[1]->val);
				t->c[0] = t->c[1] = NULL;
			}
	}

}


int main (int argc, char **argv) {
    vars = queue_create();
	yyin = fopen(argv[1], "r");
	yyparse();
}
