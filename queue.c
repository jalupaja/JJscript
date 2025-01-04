#include "queue.h"

#include <stdio.h>
#include <stdlib.h>

#define DEBUG 0

typedef struct node {
  void *val;
  struct node *next;
  struct node *prev;
} node;

struct queue {
  node *head;
  node *tail;
  size_t size;
};

queue *queue_create() {
  if (DEBUG)
    printf("queue_create\n");
  queue *q = (queue *)malloc(sizeof(queue));
  q->head = NULL;
  q->tail = NULL;
  q->size = 0;
  return q;
}

void queue_enqueue(queue *q, void *data) {
  node *new_node = (node *)malloc(sizeof(node));
  new_node->val = data;

  if (q->size == 0) {
    new_node->next = new_node;
    new_node->prev = new_node;
    q->head = new_node;
    q->tail = new_node;
  } else {
    new_node->prev = q->tail;
    new_node->next = q->head;
    q->tail->next = new_node;
    q->head->prev = new_node;
    q->tail = new_node;
  }

#include "value.h"
  q->size++;
  printf("Enqueued element '%d'. New size: %zu\n",
         ((val_t *)new_node->val)->val.intval, q->size);
  if (DEBUG)
    printf("Enqueued element. New size: %zu\n", q->size);
}

void *queue_dequeue(queue *q) {
  if (q->size == 0)
    return NULL;

  node *deq_node = q->head;
  void *data = deq_node->val;

  if (q->size == 1) {
    q->head = NULL;
    q->tail = NULL;
  } else {
    q->head = deq_node->next;
    q->tail->next = q->head;
    q->head->prev = q->tail;
  }

  free(deq_node);
  q->size--;

  if (DEBUG)
    printf("Dequeued element. New size: %zu\n", q->size);
  return data;
}

void queue_free(queue *q) {
  while (q->size > 0) {
    queue_dequeue(q);
  }
  free(q);
}

ssize_t queue_len(queue *q) { return q->size; }

static node *find_item(queue *q, int n) {
  if (DEBUG)
    printf("finding in q(%p) %d of %d\n", q, n, (int)q->size);

  if (q->size == 0)
    return NULL;

  node *cur;
  if (n >= 0) {
    cur = q->head;
    while (n-- > 0) {
      cur = cur->next;
    }
  } else {
    cur = q->tail;
    n++; // -1 should be last element in list
    while (n++ < 0) {
      cur = cur->prev;
    }
  }
  return cur;
}

void queue_enqueue_at(queue *q, void *data, int n) {
  if (q->size == 0 || n >= (int)q->size) {
    queue_enqueue(q, data);
    return;
  }

  node *res = find_item(q, n);
  node *new_node = (node *)malloc(sizeof(node));
  new_node->val = data;

  new_node->prev = res->prev;
  new_node->next = res;

  res->prev->next = new_node;
  res->prev = new_node;

  if (res == q->head) {
    q->head = new_node;
  }

  q->size++;
  if (DEBUG)
    printf("Enqueued at position %d. New size: %zu\n", n, q->size);
}

void *queue_dequeue_at(queue *q, int n) {
  if (q->size == 0)
    return NULL;

  node *res = find_item(q, n);
  if (res == NULL)
    return NULL;

  void *data = res->val;

  res->prev->next = res->next;
  res->next->prev = res->prev;

  if (res == q->head) {
    q->head = res->next;
  }
  if (res == q->tail) {
    q->tail = res->prev;
  }

  free(res);
  q->size--;

  if (DEBUG)
    printf("Dequeued at position %d. New size: %zu\n", n, q->size);
  return data;
}

#include "string.h"
void *queue_at(queue *q, int n) {
  node *res = find_item(q, n);
  return res ? res->val : NULL;
}

void queue_print_all_val(queue *q, void (*print_func)(void *)) {
  if (q->size == 0) {
    printf("queue: NULL\n");
    return;
  }

  printf("queue: ");
  node *current = q->head;
  printf("[");
  for (size_t i = 0; i < q->size - 1; i++) {
    print_func(current->val);
    printf(", ");
    current = current->next;
  }
  print_func(current->val);
  printf("]");
}
