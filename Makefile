CC=gcc
CFLAGS=-O0 -Wall -ggdb
LDFLAGS=-lm
PRJ=term

$(PRJ): $(PRJ).tab.o $(PRJ).lex.o string.o queue.o values.o
	$(CC) -o $@ $^ $(LDFLAGS)

$(PRJ).tab.c $(PRJ).tab.h: $(PRJ).y string.o queue.o
	bison -t --defines --report=all $(PRJ).y

$(PRJ).tab.o: $(PRJ).tab.c $(PRJ).tab.h

$(PRJ).lex.c: $(PRJ).l string.o queue.o
	flex -o $(PRJ).lex.c $(PRJ).l

$(PRJ).lex.o: $(PRJ).lex.c $(PRJ).tab.h

queue.o: queue.c queue.h

string.o: string.c string.h

values.o: values.c values.h

clean:
	rm -f $(PRJ).tab.* $(PRJ).lex.* $(PRJ) $(PRJ).output *.o *.gch
