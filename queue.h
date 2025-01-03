#ifndef QUEUE_H_
#define QUEUE_H_

#include <stdlib.h>
typedef struct queue_t queue_t;

queue_t *queue_create();
void queue_destroy(queue_t *q);
void queue_enqueue(queue_t *q, void *data);
void *queue_dequeue(queue_t *q);
ssize_t queue_len(queue_t *q);
void queue_enqueue_at(queue_t *q, void *data, int n);
void *queue_dequeue_at(queue_t *q, int n);
void *queue_at(queue_t *q, int n);
void queue_print_all_val(queue_t *q, void (*print_func)(void *));

#endif // QUEUE_H_
