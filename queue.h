#ifndef QUEUE_H_
#define QUEUE_H_

#include <stdlib.h>
typedef struct queue queue;

queue *queue_create();
void queue_free(queue *q);
void queue_enqueue(queue *q, void *data);
void *queue_dequeue(queue *q);
ssize_t queue_len(queue *q);
void queue_enqueue_at(queue *q, void *data, int n);
void *queue_dequeue_at(queue *q, int n);
void *queue_at(queue *q, int n);
void queue_print_all_val(queue *q, void (*print_func)(void *));

#endif // QUEUE_H_
