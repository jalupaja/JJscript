CC=gcc
CFLAGS=-O0 -Wall -ggdb
LDFLAGS=-lm

LEXER=lexer
PARSER=parser
PRJ=prog

$(PRJ): $(PARSER).tab.o $(LEXER).lex.o ast.o string.o queue.o value.o value_calc.o env.o function.o utils.o
	$(CC) -o $@ $^ $(LDFLAGS)

$(PARSER).tab.c $(PARSER).tab.h: $(PARSER).y string.o queue.o
	bison -t --defines --report=all $(PARSER).y -Wcounterexamples

$(PARSER).tab.o: $(PARSER).tab.c $(PARSER).tab.h

$(LEXER).lex.c: $(LEXER).l string.o queue.o
	flex -o $(LEXER).lex.c $(LEXER).l

$(LEXER).lex.o: $(LEXER).lex.c $(PARSER).tab.h

ast.o: ast.c ast.h

queue.o: queue.c queue.h

string.o: string.c string.h

value.o: value.c value.h
value_calc.o: value_calc.c value_calc.h

function.o: function.c function.h

env.o: env.c env.h

utils.o: utils.c utils.h

clean:
	rm -f $(PARSER).tab.* $(LEXER).lex.* $(PRJ) $(PARSER).output *.o
