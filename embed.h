#ifndef EMBED_H
#define EMBED_H

#include "queue.h"
#include "string.h"
#include "value.h"

#include <stdlib.h>

typedef struct emb_t emb_t;
typedef struct ast_t ast_t;

struct emb_t {
  ast_t *embeds;
  string *str_end;
  val_type_t val_type;
};

emb_t *embed_create(ast_t *embeds, string *str_end, val_type_t val_type);
void embed_free(emb_t *emb);

#endif // EMBED_H
