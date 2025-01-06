#include "queue.h"
#include "string.h"
#include "value.h"

#include "env.h"

#include <stdio.h>

#define DEBUG 0

env_t *cur_env = NULL;

void env_push() {
  env_t *new_env = (env_t *)malloc(sizeof(env_t));
  new_env->vars = queue_create();
  new_env->parent = cur_env;
  cur_env = new_env;
  if (DEBUG)
    printf("env_push: %p\n", new_env);
}

void env_free(env_t *env) {
#ifndef NO_FREE
  if (!env)
    return;
  queue_free(env->vars);
  free(env);
#else
  printf("env_free() (DISABLED)\n");
#endif
}

void env_pop() {
  if (DEBUG)
    printf("env_pop\n");
  if (cur_env) {
    env_t *old_env = cur_env;
    cur_env = cur_env->parent;
    env_free(old_env);
  }
}

env_var_t *queue_search(queue *q, string *id) {
  env_var_t *cur;
  size_t q_len = queue_len(q);
  for (size_t i = 0; i < q_len; i++) {
    cur = (env_var_t *)queue_at(q, i);
    if (cur != NULL && string_cmp(id, cur->id) == 0)
      return cur;
  }
  return NULL;
}

env_var_t *env_search(string *id) {
  if (DEBUG)
    printf("env_search: %s\n", string_get_chars(id));
  env_t *env = cur_env;
  while (env) {
    env_var_t *res = (env_var_t *)queue_search(env->vars, id);
    if (res != NULL) {
      if (DEBUG)
        printf("env_search res(%p): %s\n", res,
               string_get_chars(val2string(res->val)));
      return res;
    }
    env = env->parent;
  }
  if (DEBUG)
    printf("env_search res()\n");
  return NULL;
}

env_var_t *env_search_top(string *id) {
  return (env_var_t *)queue_search(cur_env->vars, id);
}

void env_save(string *id, val_t *val) {
  env_var_t *cur = env_search_top(id);
  if (DEBUG)
    printf("assign(env: %p): %s = %s", cur_env, string_get_chars(id),
           string_get_chars(val2string(val)));
  if (cur != NULL) {
    // id already exists -> update value
    if (DEBUG)
      printf("(old)\n");
    cur->val = val;

  } else {
    // enqueue new value
    if (DEBUG)
      printf("(new)\n");
    env_var_t *new = (env_var_t *)malloc(sizeof(env_var_t));
    new->id = id;
    new->val = val;
    queue_enqueue(cur_env->vars, new);
  }
}
