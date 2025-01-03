#include "queue.h"
#include "string.h"
#include "values.h"

#include "env.h"

#include <stdio.h>

#define DEBUG 0

env_t *cur_env = NULL;

void queue_free(queue *q) {
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

var *queue_search_id(queue *q, string *id) {
  var *cur;
  ssize_t q_len = queue_len(q);
  for (ssize_t i = 0; i < q_len; i++) {
    cur = (var *)queue_at(q, i);
    if (cur != NULL && string_cmp(id, cur->id) == 0)
      return cur;
  }
  return NULL;
}

var *env_search(string *id) {
  env_t *env = cur_env;
  while (env) {
    var *result = queue_search_id(env->vars, id);
    if (result != NULL)
      return result;
    env = env->parent;
  }
  return NULL;
}

var *env_search_top(string *id) {
  var *result = queue_search_id(cur_env->vars, id);
  return result;
}

void env_save(string *id, value *val) {
  var *cur = env_search_top(id);
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
    var *new = (var *)malloc(sizeof(var));
    new->id = id;
    new->val = val;
    queue_enqueue(cur_env->vars, new);
  }
}

void save_var(string *id, value *val) {
  var *existing_var = queue_search_id(cur_env->vars, id);
  if (existing_var) {
    free_value(existing_var->val);
    existing_var->val = val;
  } else {
    var *new_var = (var *)malloc(sizeof(var));
    new_var->id = id;
    new_var->val = val;
    queue_enqueue(cur_env->vars, new_var);
  }
}
