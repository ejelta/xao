#include "EXTERN.h"
#include "perl.h"  
#include "XSUB.h"  

#include "wparser/wparser.h"
#include "wparser/s_string.h"

MODULE = XAO::WikiParser   PACKAGE = XAO::WikiParser

SV *
parse(text)
        STRLEN text_length=0;
        char *text=SvPV(ST(0),text_length);
        bool text_is_utf8=SvUTF8(ST(0));
    PROTOTYPE: $
    CODE:
        string str(text,text_length);

        struct gtreftable reftable;
        memset(&reftable,0,sizeof(struct gtreftable));

        unsigned n=parse_to_blocks(str,&reftable);

        AV * results=(AV *)sv_2mortal((SV *)newAV());
        for(unsigned i=0; i<n; i++) {
            if(reftable.reflist[i].skip) continue;

            HV * rh = (HV*)sv_2mortal((SV*)newHV());

            const char *blockname=blocktype2name(reftable.reflist[i].type);
            SV *nsv=newSVpvn(blockname, strlen(blockname));
            if(text_is_utf8) SvUTF8_on(nsv);
            hv_store(rh, "type", 4, nsv, 0);

            if(reftable.reflist[i].level)
              hv_store(rh, "level", 5, newSVuv(reftable.reflist[i].level),0);

            if(reftable.reflist[i].opcode) {
                nsv=newSVpvn(reftable.reflist[i].opcode, strlen(reftable.reflist[i].opcode));
                if(text_is_utf8) SvUTF8_on(nsv);
                hv_store(rh, "opcode", 6, nsv, 0);
            }

            nsv=newSVpvn(reftable.reflist[i].text, strlen(reftable.reflist[i].text));
            if(text_is_utf8) SvUTF8_on(nsv);
            hv_store(rh, "content", 7, nsv, 0);

            av_push(results, newRV((SV *)rh));
        }

        free_reftable(&reftable);

        RETVAL = newRV((SV *)results);
    OUTPUT:
        RETVAL
