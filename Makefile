CC=gcc
CFLAGS=-O0 -Wall -ggdb
LDFLAGS=-lm

LEXER=lexer
PARSER=parser
PRJ=prog

$(PRJ): $(PARSER).tab.o $(LEXER).lex.o ast.o string.o queue.o value.o env.o
	$(CC) -o $@ $^ $(LDFLAGS)

$(PARSER).tab.c $(PARSER).tab.h: $(PARSER).y string.o queue.o
	bison -t --defines --report=all $(PARSER).y

$(PARSER).tab.o: $(PARSER).tab.c $(PARSER).tab.h

$(LEXER).lex.c: $(LEXER).l string.o queue.o
	flex -o $(LEXER).lex.c $(LEXER).l

$(LEXER).lex.o: $(LEXER).lex.c $(PARSER).tab.h

ast.o: ast.c ast.h

queue.o: queue.c queue.h

string.o: string.c string.h

value.o: value.c value.h

env.o: env.c env.h

clean:
	rm -f $(PARSER).tab.* $(LEXER).lex.* $(PRJ) $(PARSER).output *.o
