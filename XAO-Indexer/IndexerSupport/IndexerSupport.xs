/* Fast sorting and merging for XAO::Indexer
 *
 * Andrew Maltsev, <am@xao.com>, 2004
*/
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* If that version of perl does not have pTHX_ macros then defining them here
*/
#ifndef	pTHX_
#define	pTHX_
#endif
#ifndef	aTHX_
#define	aTHX_
#endif

/************************************************************************/

#define TREE_DEPTH  (5)
#define LEAF_SIZE   (0x80000000>>(TREE_DEPTH*4-1))

union tree_node {
    union tree_node *nodes;
    U32 *data;
};
static union tree_node tree_root[16];

/************************************************************************/

static
void
tree_print(union tree_node *branch, U8 level) {
    U8 spnum=(level+1)*2;
    U8 i;
    for(i=0; i<16; ++i) {
        if(!branch[i].nodes) continue;
        fprintf(stderr,"%*s:idx=%x level=%u\n",spnum,".",i,level);
        if(level<TREE_DEPTH-1) {
            tree_print(branch[i].nodes,level+1);
        }
        else {
            U32 *d=branch[i].data;
            U32 j;
            for(j=0; j<LEAF_SIZE; ++j) {
                U32 pos=d[j];
                if(pos!=0xffffffff) {
                    fprintf(stderr,"%*s:::pos=%5lu value=%04x\n",
                                   spnum,".",pos,j);
                }
            }
        }
    }
}

static
void
tree_store(union tree_node *branch, U32 pos, U32 value, U8 level) {
    U8 idx=((level ? value<<(level*4) : value) >> 28) & 0xf;
    union tree_node *node=branch+idx;

    //printf("pos=%lu value=%08lx level=%u idx=%u\n",pos,value,level,idx);

    if(level<TREE_DEPTH-1) {
        if(!node->nodes) {
            node->nodes=(typeof(node->nodes))malloc(16*sizeof(union tree_node));
            memset(node->nodes,0,16*sizeof(union tree_node));
        }
        tree_store(node->nodes,pos,value,level+1);
    }
    else {
        U32 *data=node->data;
        if(!node->data) {
            data=node->data=(typeof(data))malloc(LEAF_SIZE * sizeof(*data));
            memset(data,0xff,LEAF_SIZE * sizeof(*data));
        }
        data[value&(LEAF_SIZE-1)]=pos;
    }
}

/* Only clears data blocks without even freeing their memory, since if
 * we're going to re-use the index -- it will most likely contain the same
 * ID's, only re-ordered.
*/
static
void
tree_clear(union tree_node *branch, U8 level) {
    U8 i;
    for(i=0; i<16; ++i) {
        if(level<TREE_DEPTH-1) {
            union tree_node *nodes=branch[i].nodes;
            if(nodes) {
                //printf("Clearing level=%x, i=%x\n",level,i);
                tree_clear(nodes,level+1);
            }
        }
        else {
            U32 *data=branch[i].data;
            if(data) {
                memset(data,0xff,LEAF_SIZE * sizeof(*data));
            }
        }
    }
}

/* Populating tree with data
*/
static
void
tree_init(U32 *data, U32 size) {
    U32 i;

    tree_clear(tree_root,0);

    for(i=0; i<size; ++i, ++data) {
        U32 value=*data;
        tree_store(tree_root,i,value,0);
    }
}

static
U32
tree_lookup(U32 value) {
    union tree_node *node=tree_root;
    U8 i;
    U16 vrem;
    U16 qty;

    //printf("Looking up %08lx (%lu)\n",value,value);

    for(i=0; i<TREE_DEPTH; ++i) {
        
        U8 idx=((i ? value<<(i*4) : value) >> 28) & 0xf;
        if(!node) {
            return 0xffffffff;
        }
        if(i==TREE_DEPTH-1) {
            U32 *data=node[idx].data;
            if(!data)
                return 0xffffffff;
            return data[value & (LEAF_SIZE-1)];
        }
        else {
            node=node[idx].nodes;
            //printf("i=%u idx=%u node=%p\n",i,idx,node);
        }
    }

    return 0xffffffff;
}

static
void
tree_free(union tree_node *branch, U8 level) {
    U8 i;

    if(level==0)
        //printf("Freeing branch %p, level %u\n",branch,level);

    for(i=0; i<16; ++i) {
        //printf("Freeing level=%x, i=%x\n",level,i);
        if(level<TREE_DEPTH-1) {
            union tree_node *nodes=branch[i].nodes;
            if(nodes) {
                tree_free(nodes,level+1);
                free(nodes);
                branch[i].nodes=NULL;
            }
        }
        else {
            U32 *data=branch[i].data;
            if(data) {
                free(data);
                branch[i].data=NULL;
            }
        }
    }
}

static
int
tree_compare(U32 const *a, U32 const *b) {
    U32 pa=tree_lookup(*a);
    U32 pb=tree_lookup(*b);
    return (pa>pb ? 1 : (pa<pb ? -1 : 0));
}

/************************************************************************/

MODULE = XAO::IndexerSupport		PACKAGE = XAO::IndexerSupport

 # Gets sorted array that is to be used in templated sorting of its
 # subsets later on.
 #

void
template_sort_prepare_do(full_sv)
        SV *full_sv;
    INIT:
        STRLEN full_strlen;
        U32 *full=(U32 *)SvPV(full_sv,full_strlen);
        U32 full_len=full_strlen/4;
	CODE:
        tree_init(full,full_len);

void
template_sort_do(part_sv)
        SV *part_sv;
    INIT:
        STRLEN part_strlen;
        U32 *part=(U32 *)SvPV(part_sv,part_strlen);
        U32 part_len=part_strlen/4;
	CODE:
        qsort(part,part_len,sizeof(*part),
              (int (*)(const void *,const void *))tree_compare);

int
template_sort_compare(a,b)
        U32 a;
        U32 b;
	CODE:
        RETVAL=tree_compare(&a,&b);
    OUTPUT:
        RETVAL

void
template_sort_clear()
    CODE:
        tree_clear(tree_root,0);

void
template_sort_free()
    CODE:
        tree_free(tree_root,0);

U32
template_sort_position(value)
        U32 value;
    CODE:
        RETVAL=tree_lookup(value);
    OUTPUT:
        RETVAL

void
template_sort_print_tree()
    CODE:
        tree_print(tree_root,0);
