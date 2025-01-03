#include "queue.h"
#include "string.h"
#include "value.h"

#include "env.h"

#include <stdio.h>

#define DEBUG 0

env_t *cur_env = NULL;

void queue_free(queue_t *q) {
  // TODO
}

void env_push() {
  env_t *new_env = (env_t *)malloc(sizeof(env_t));
  new_env->vars = queue_create();
  new_env->parent = cur_env;
  cur_env = new_env;
}

void env_free(env_t *env) {
  // TODO free queue, ...
  free(env);
}

void env_pop() {
  if (cur_env) {
    queue_free(cur_env->vars);
    env_t *old_env = cur_env;
    cur_env = cur_env->parent;
    env_free(old_env);
  }
}

var_t *queue_search(queue_t *q, string *id) {
  var_t *cur;
  ssize_t q_len = queue_len(q);
  for (ssize_t i = 0; i < q_len; i++) {
    cur = (var_t *)queue_at(q, i);
    if (cur != NULL && string_cmp(id, cur->id) == 0)
      return cur;
  }
  return NULL;
}

var_t *env_search(string *id) {
  env_t *env = cur_env;
  while (env) {
    var_t *result = (var_t *)queue_search(env->vars, id);
    if (result != NULL)
      return result;
    env = env->parent;
  }
  return NULL;
}

var_t *env_search_top(string *id) {
  return (var_t *)queue_search(cur_env->vars, id);
}

void env_save(string *id, val_t *val) {
  var_t *cur = env_search_top(id);
  if (DEBUG)
    printf("assign: %s = %d", string_get_chars(id), val->val.intval);
  if (cur != NULL) {
    // id already exists -> update value
    if (DEBUG)
      printf("(old)\n");
    free_value(cur->val);
    cur->val = val;

  } else {
    // enqueue new value
    if (DEBUG)
      printf("(new)\n");
    var_t *new = (var_t *)malloc(sizeof(var_t));
    new->id = id;
    new->val = val;
    queue_enqueue(cur_env->vars, new);
  }
}
