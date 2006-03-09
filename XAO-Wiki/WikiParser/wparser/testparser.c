#include <stdio.h>
#include <string.h>
#include "s_string.h"
#include "wparser.h"

#define BUFLEN 200

string replaceCR(char *str)
{
string s;
s="";
char *cp=str;
while(*cp)
  {
    if(*cp=='\n') s+="\\n";
    else s+=*cp;
    cp++;
  }
return s;
}

void Wiki_parse_debug(char *orig)
{
string str;
str=orig;
int i,n;
struct gtreftable reftable;
memset(&reftable,0,sizeof(struct gtreftable));
n=parse_to_blocks(str,&reftable);
for(i=0;i<n;i++)
 {
   if(reftable.reflist[i].skip) continue;
   printf("{ type => '%s',",blocktype2name(reftable.reflist[i].type));
   if(reftable.reflist[i].level)
     printf(" level => '%i',",reftable.reflist[i].level);
   printf(" content => '%s' }\n",(char*)replaceCR(reftable.reflist[i].text));
 }
free_reftable(&reftable);
}


int main(void)
{
char buf[BUFLEN+1];
int rc;
string s;
s="";
while((rc=fread(buf,1,BUFLEN,stdin))) {buf[rc]=0;s+=buf;}
Wiki_parse_debug(s);
}
