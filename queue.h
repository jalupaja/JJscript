#ifndef QUEUE_H_
#define QUEUE_H_

#include "string.h"
#include <stdlib.h>
typedef struct queue queue;

queue *queue_create();
void queue_free(queue *q);
queue *queue_copy(queue *q);
void queue_enqueue(queue *q, void *data);
void queue_append(queue *q1, queue *q2);
void queue_repeat(queue *q, long n);
void *queue_dequeue(queue *q);
size_t queue_len(queue *q);
void queue_enqueue_at(queue *q, void *data, long n);
void queue_append_at(queue *q1, queue *q2, long n);
void *queue_dequeue_at(queue *q, long n);
int queue_cmp(queue *q1, queue *q2);
void **queue_ptr_at(queue *q, long n);
void *queue_at(queue *q, long n);
queue *queue_interleave(queue *q1, queue *q2);
string *queue_to_string(queue *q, string *(*to_string_func)(void *));
void queue_print(queue *q, void (*print_func)(void *));

#endif // QUEUE_H_
