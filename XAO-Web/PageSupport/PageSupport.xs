/* This is very specific module oriented to support fast text adding
 * for XAO displaying engine. Helps a lot with template processing,
 * especially when template splits into thousands or even millions of
 * pieces.
 *
 * The idea is to have one long buffer that extends automatically and a
 * stack of positions in it that can be pushed/popped when application
 * need new portion of text.
 *
 * Andrew Maltsev, <am@xao.com>, 2000, 2002
*/
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>

#define	MAX_STACK	200
#define	CHUNK_SIZE	1000

static char *buffer=NULL;
static unsigned long bufsize=0;
static unsigned long bufpos=0;
static unsigned long pstack[MAX_STACK];
static unsigned stacktop=0;

/************************************************************************/

/* Parsing template into an array suitable for Web::Page
*/

static SV*
parse_text(pTHX_ char * template, unsigned length) {
    unsigned i;
    char *str;

    AV* parsed=newAV();

    enum {
        TEXT,
        OBJECT,
        ARGUMENT,
    } state=TEXT;

    char *text_ptr=template;

    for(i=0, str=template; i!=length; i++, str++) {
        if(*str=='<' && i+1<length && str[1]=='%') {
            if(state==TEXT) {
                if(i+3<length && str[2]=='%' && str[3]=='>') {
                    /* An way to embed '<%' -- <%%> */
                    str+=2;
                    i+=2;
                    state=TEXT;
                }
                else {
                    state=OBJECT;
                }

                if(text_ptr!=str) {
                    HV* hv=newHV();
                    hv_store(hv,"text",4,
                                newSVpvn(text_ptr,str-text_ptr),0);
                    av_push(parsed,newRV_noinc((SV*)hv));
                    text_ptr=str+2;
                }

                str++;
                i++;
            }
            else if(state==ARGUMENT) {
                fprintf(stderr,"Got here");
            }

        }
        else {
            if(state==OBJECT) {
                fprintf(stderr,"Got here O\n");
            }
        }
    }

    if(state==TEXT) {
        if(text_ptr!=str) {
            HV* hv=newHV();
            hv_store(hv,"text",4,
                        newSVpvn(text_ptr,str-text_ptr),0);
            av_push(parsed,newRV_noinc((SV*)hv));
        }
    }

    return newRV_noinc((SV*)parsed);
}

/************************************************************************/

MODULE = XAO::PageSupport		PACKAGE = XAO::PageSupport		

unsigned
level()
	CODE:
		RETVAL=stacktop;
	OUTPUT:
		RETVAL

void
reset()
	CODE:
		pstack[stacktop=0]=0;

void
push()
	CODE:
		if(stacktop+1>=MAX_STACK) {
		    fprintf(stderr,"XAO::PageSupport - maximum stack deep reached!\n");
		    return;
        }
		pstack[stacktop++]=bufpos;

SV *
pop()
	CODE:
		char *text;
		unsigned long len;
		if(!buffer) {
		    text="";
		    len=0;
        } else {
            len=bufpos;
            if(stacktop) {
                bufpos=pstack[--stacktop];
                len-=bufpos;
            } else {
                bufpos=0;
            }
            text=buffer+bufpos;
        }
		RETVAL=newSVpvn(aTHX_ text,len);
	OUTPUT:
	    RETVAL

void
addtext(text)
        unsigned int len=0;
		char * text=SvPV(aTHX_ ST(0),len);
	CODE:
		if(text && len) {
	        if(bufpos+len >= bufsize) {
	            buffer=realloc(buffer,sizeof(*buffer)*(bufsize+=len+CHUNK_SIZE));
		        if(! buffer) {
		            fprintf(stderr,
                            "XAO::PageSupport - out of memory, length=%u, bufsize=%lu, bufpos=%lu\n",
                            len,bufsize,bufpos);
                    return;
		        }
		    }
	        memcpy(buffer+bufpos,text,len);
	        bufpos+=len;
		}

SV *
parse(text)
        unsigned int length=0;
        char *template=SvPV(aTHX_ ST(0),length);
    CODE:
        RETVAL=parse_text(aTHX_ template, length);
    OUTPUT:
        RETVAL
