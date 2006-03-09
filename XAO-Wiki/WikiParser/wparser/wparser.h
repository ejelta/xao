#define HEADER_IS_BLOCK
//#define COMMENT_IS_BLOCK

struct gtreflist {
int  type;
int  level;
char *text;
char *opcode;
int skip;
};

struct gtreftable {
struct gtreflist *reflist;
int reflist_allocated;
int reflist_used;
};

int parse_to_blocks(char * str, struct gtreftable *dst);
int free_reftable(struct gtreftable *reftable);
const char *blocktype2name(int type);


void Wiki_parse_debug(char *);
