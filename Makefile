CC=gcc
CFLAGS=-O0 -Wall -ggdb
LDFLAGS=-lm

LEXER=lexer
PARSER=parser
PRJ=prog

$(PRJ): $(PARSER).tab.o $(LEXER).lex.o string.o queue.o values.o env.o
	$(CC) -o $@ $^ $(LDFLAGS)

$(PARSER).tab.c $(PARSER).tab.h: $(PARSER).y string.o queue.o
	bison -t --defines --report=all $(PARSER).y

$(PARSER).tab.o: $(PARSER).tab.c $(PARSER).tab.h

$(LEXER).lex.c: $(LEXER).l string.o queue.o
	flex -o $(LEXER).lex.c $(LEXER).l

$(LEXER).lex.o: $(LEXER).lex.c $(PARSER).tab.h

queue.o: queue.c queue.h

string.o: string.c string.h

values.o: values.c values.h

env.o: env.c env.h

clean:
	rm -f $(PARSER).tab.* $(LEXER).lex.* $(PRJ) $(PARSER).output *.o
