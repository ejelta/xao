#define HEADER_IS_BLOCK
//#define COMMENT_IS_BLOCK

struct gtreflist {
char *type;
int  level;
char *text;
int skip;
};

struct gtreftable {
struct gtreflist *reflist;
int reflist_allocated;
int reflist_used;
};

int parse_to_blocks(char * str, struct gtreftable *dst);
int free_reftable(struct gtreftable *reftable);



void Wiki_parse_debug(char *);
