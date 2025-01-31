#include "queue.h"
#include "string.h"
#include "value.h"

#include "env.h"

#include <stdio.h>

#define DEBUG 0

void print_error(const char *);

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
  fprintf(stderr, "env_free() (DISABLED)\n");
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

void __parse_indexes(val_t **res, queue *indexes, size_t cur_index,
                     val_t *new_val, queue *ret_queue) {
  size_t q_len = queue_len(indexes);
  queue *cur_indexes = (queue *)queue_at(indexes, cur_index);
  bool last_round = (cur_index == q_len - 1);

  size_t cur_ind_len = queue_len(cur_indexes);
  for (size_t j = 0; j < cur_ind_len; j++) {
    val_t *ind_val = (val_t *)queue_at(cur_indexes, j);

    long ind = val2int(ind_val);

    val_t **new_res;
    val_t **tmp_res = value_ptr_at(*res, ind);
    if (tmp_res) {
      // allow 2[0]
      new_res = tmp_res;
    } else {
      new_res = res;
      // Fix "1234"[1][0] -> "1234"[0]
      if ((*new_res)->val_type == STRING_TYPE) {
        last_round = true;
      }
    }

    if (!last_round) {
      __parse_indexes(new_res, indexes, cur_index + 1, new_val, ret_queue);
    } else {
      if (new_val) {
        // env_save
        if ((*new_res)->val_type == STRING_TYPE) {
          string *replace = val2string(new_val);
          string_replace_at((*new_res)->val.strval, ind, replace);
          string_free(replace);
          new_val = NULL;
        } else {
          *new_res = new_val;
        }
      } else {
        // env_search
        if ((*new_res)->val_type == STRING_TYPE) {
          string *str_res = string_create(NULL);
          string_append_char(str_res,
                             string_get_char_at((*new_res)->val.strval, ind));
          queue_enqueue(ret_queue, (void *)value_create(str_res, STRING_TYPE));
        } else {
          queue_enqueue(ret_queue, (void *)*new_res);
        }
      }
    }
  }
}

val_t *parse_indexes(val_t **res, queue *indexes, val_t *new_val) {
  if (new_val) {
    // env_save
    __parse_indexes(res, indexes, 0, new_val, NULL);
    return *res;
  } else {
    // env_search
    queue *ret_queue = queue_create();
    __parse_indexes(res, indexes, 0, new_val, ret_queue);

    size_t q_len = queue_len(ret_queue);
    if (q_len == 0) {
      queue_free(ret_queue);
      return NULL;
    } else if (q_len == 1) {
      val_t *ret = queue_at(ret_queue, 0);
      queue_free(ret_queue);
      return ret;
    } else {
      return value_create((void *)ret_queue, QUEUE_TYPE);
    }
  }
}

env_var_t *_env_search(string *id) {
  if (DEBUG)
    printf("_env_search: %s\n", string_get_chars(id));
  env_t *env = cur_env;
  for (int i = 0; i < 2; i++) {
    // search current_env first, then global env
    env_var_t *res = (env_var_t *)queue_search(env->vars, id);
    if (res != NULL) {
      if (DEBUG)
        printf("_env_search res(%p): %s\n", res,
               string_get_chars(val2string(res->val)));
      return res;
    }
    // get global env (first env)
    bool new_env = false;
    while (env->parent) {
      // TODO printf("SEARCHING LOWER ENV\n");
      new_env = true;
      env = env->parent;
    }
    if (!new_env)
      break;
  }
  if (DEBUG)
    printf("_env_search res(EMPTY)\n");
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

env_var_t *env_search_top(string *id) {
  return (env_var_t *)queue_search(cur_env->vars, id);
}

val_t *env_search(val_t *id) {
  if (id && id->val_type == STRING_TYPE) {
    env_var_t *found = _env_search(id->val.strval);
    if (found) {
      queue *indexes = id->indexes;
      val_t **res = &found->val;

      if (indexes) {
        return parse_indexes(res, indexes, NULL);
      } else {
        return *res;
      }
    }
  }
  return NULL;
}

void env_save(val_t *id, val_t *val) {
  // TODO could prob. free overwritten values...
  env_var_t *cur = _env_search(id->val.strval);
  if (DEBUG)
    printf("assign(env: %p): %s = %s", cur_env,
           string_get_chars(id->val.strval), string_get_chars(val2string(val)));

  queue *indexes = id->indexes;
  val_t **res;

  if (cur != NULL) {
    res = &cur->val;
    // id already exists -> update value
    if (DEBUG)
      printf("(old)\n");

    if (indexes) {
      if (DEBUG)
        printf("env_search found indexes\n");

      parse_indexes(res, indexes, val);
    } else {
      *res = val;
    }

  } else {
    // enqueue new value
    if (DEBUG)
      printf("(new)\n");
    env_var_t *new = (env_var_t *)malloc(sizeof(env_var_t));
    new->id = id->val.strval;
    new->val = val;
    queue_enqueue(cur_env->vars, new);
  }
}
