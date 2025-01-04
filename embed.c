#include "embed.h"
#include "ast.h"
#include "string.h"

emb_t *embed_create(ast_t *embeds, string *str_end, val_type_t val_type) {
  emb_t *emb = (emb_t *)malloc(sizeof(emb_t));
  emb->embeds = embeds;
  emb->str_end = str_end;
  emb->val_type = val_type;
  return emb;
}

void embed_free(emb_t *emb) {
  string_free(emb->str_end);
  ast_free(emb->embeds);
  free(emb);
}
