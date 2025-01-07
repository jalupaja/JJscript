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

env_var_t *env_search_all(string *id) {
  if (DEBUG)
    printf("env_search_all: %s\n", string_get_chars(id));
  env_t *env = cur_env;
  while (env) {
    env_var_t *res = (env_var_t *)queue_search(env->vars, id);
    if (res != NULL) {
      if (DEBUG)
        printf("env_search_all res(%p): %s\n", res,
               string_get_chars(val2string(res->val)));
      return res;
    }
    env = env->parent;
  }
  if (DEBUG)
    printf("env_search_all res()\n");
  return NULL;
}

val_t *env_search(val_t *id) {
  if (id->val_type == STRING_TYPE) {
    env_var_t *found = env_search_all(id->val.strval);
    if (found) {
      return found->val;
    }
  }
  return NULL;
}

env_var_t *env_search_top(string *id) {
  return (env_var_t *)queue_search(cur_env->vars, id);
}

void env_save(val_t *id, val_t *val) {
  // TODO could prob. free overwritten values...
  env_var_t *cur = env_search_top(id->val.strval);
  if (DEBUG)
    printf("assign(env: %p): %s = %s", cur_env,
           string_get_chars(id->val.strval), string_get_chars(val2string(val)));

  queue *indexes = id->indexes;
  val_t **to_save_to;

  if (cur != NULL) {
    to_save_to = &cur->val;
    // id already exists -> update value
    if (DEBUG)
      printf("(old)\n");

    if (indexes) {
      if (DEBUG)
        printf("env_search found indexes\n");

      size_t q_len = queue_len(indexes);
      for (size_t i = 0; i < q_len; i++) {
        long *index = (long *)queue_at(indexes, i);
        if (!index) {
          fprintf(stderr, "Found invalid index\n");
          break;
        }
        // TODO wrong
        val_t **res = value_ptr_at(*to_save_to, *index);
        printf("found value after index %ld\n", *index);
        to_save_to = res;
      }
    }
    printf("to_save_to: '%s'\n", string_get_chars(val2string(*to_save_to)));
    *to_save_to = val;

  } else {
    // enqueue new value
    if (DEBUG)
      printf("(new)\n");
    if (indexes) { // if value is supposed to be an array, copy it from lower
                   // environments, then change the value
      if (DEBUG)
        printf("env_search found indexes\n");
      cur = env_search_all(id->val.strval);

      if (cur != NULL) {
        val_t *new_val = value_copy(cur->val);
        // TODO check for integers
        to_save_to = &new_val;

        size_t q_len = queue_len(indexes);
        for (size_t i = 0; i < q_len; i++) {
          long *index = (long *)queue_at(indexes, i);
          if (!index) {
            fprintf(stderr, "Found invalid index\n");
            break;
          }
          // // TODO wrong
          val_t **res = value_ptr_at(*to_save_to, *index);
          // printf("found value after index %ld\n", *index);
          to_save_to = res;
        }
        // save value
        *to_save_to = val;

        env_var_t *new = (env_var_t *)malloc(sizeof(env_var_t));
        new->id = id->val.strval;
        new->val = new_val;
        queue_enqueue(cur_env->vars, new);
        return;
      }
    }
    env_var_t *new = (env_var_t *)malloc(sizeof(env_var_t));
    new->id = id->val.strval;
    new->val = val;
    queue_enqueue(cur_env->vars, new);
  }
}
