#include "s_string.h"
#include <stdio.h>
#include <string.h>

#define STRING_CHUNK	100

string::string()
{
val=NULL;
allocated=len=0;
}

string::string(char const *s, size_t n)
{
val=NULL;
allocated=len=0;
_expand(n+1);
memcpy(val,s,n);
val[n]=0;
}

string::~string()
{
if(val) free(val);
val=NULL;
allocated=len=0;
}

void string::_expand(size_t n)
{
char *newval;
size_t ns,pages;
ns=len+n+1;
if(ns<=allocated) return;	//enough space
pages=ns/STRING_CHUNK;
if(pages*STRING_CHUNK<ns) pages++;
ns=pages*STRING_CHUNK;		//round up at chunks
allocated=ns;
newval=(char*) malloc(allocated);
if(!newval) {fprintf(stderr,"No mem");exit(100);}
if(val)
 {
   memcpy(newval,val,len+1);
   free(val);
 }
val=newval;
}

string &string::operator=(string &s)
{
size_t slen;
len=0;
if(!s.val||!*s.val)
   {
     len=0;
     if(allocated) *val=0;
     return s;
   }
slen=strlen(s.val);
_expand(slen+1);
memcpy(val,s.val,slen+1);
len=slen;
return s;
}
const char* string::operator=(const char *s)
{
size_t slen;
if(!s) {len=allocated=0;if(val) free(val);return *this;}
slen=strlen(s);
len=0;
_expand(slen+1);
memcpy(val,s,slen+1);
len=slen;
return s;
}
char string::operator=(char c)
{
len=0;
_expand(100);
if(c)
 {
  val[0]=c;
  val[1]=0;
  len=1;
 }
else
 {
   *val=0;
   len=0;
 }
return c;
}
int string::operator=(int i)
{
len=0;
_expand(32);
len=sprintf(val,"%i",i);
return i;
}
long int string::operator=(int long i)
{
len=0;
_expand(32);
len=sprintf(val,"%li",i);
return i;
}
unsigned long string::operator=(unsigned long i)
{
len=0;
_expand(32);
len=sprintf(val,"%lu",i);
return i;
}
unsigned string::operator=(unsigned i)
{
len=0;
_expand(32);
len=sprintf(val,"%u",i);
return i;
}
double string::operator=(double i)
{
len=0;
_expand(64);
len=sprintf(val,"%f",i);
return i;
}

string string::operator+(string &s)
{
string *newstr;
if(!s.val) return *this;
newstr=new string;
if(!newstr) {fprintf(stderr,"No mem");exit(100);}
newstr->_expand(s.len+len+1);
memcpy(newstr->val,val,len);
memcpy(newstr->val+len,s.val,s.len+1);
newstr->len=s.len+len;
return *newstr;
}

string string::operator+(char *s)
{
string *newstr;
size_t slen;
if(!s||!*s) return *this;
slen=strlen(s);
newstr=new string;
if(!newstr) {fprintf(stderr,"No mem");exit(100);}
newstr->_expand(slen+len+1);
memcpy(newstr->val,val,len);
memcpy(newstr->val+len,s,slen+1);
newstr->len=slen+len;
return *newstr;
}

string string::operator+(char c)
{
string *newstr;
if(!c) return *this;
newstr=new string;
newstr->_expand(1);
memcpy(newstr->val,val,len);
newstr->val[len]=c;
newstr->val[1]=0;
newstr->len=len+1;
return *newstr;
}
string string::operator+(int i)
{
char buf[32];
sprintf(buf,"%i",i);
return *this+buf;
}
string string::operator+(long int i)
{
char buf[32];
sprintf(buf,"%li",i);
return *this+buf;
}
string string::operator+(unsigned i)
{
char buf[32];
sprintf(buf,"%u",i);
return *this+buf;
}
string string::operator+(unsigned long i)
{
char buf[32];
sprintf(buf,"%lu",i);
return *this+buf;
}
string string::operator+(double i)
{
char buf[60];
sprintf(buf,"%f",i);
return *this+buf;
}

string &string::operator+=(string &s)
{
int slen;
if(!s.val||!s.len) return *this;
slen=strlen(s.val);
_expand(slen+1);
memcpy(val+len,s.val,slen+1);
len+=slen;
return *this;
}
string &string::operator+=(const char *s)
{
size_t slen;
if(!s||!*s) return *this;
slen=strlen(s);
_expand(slen+1);
memcpy(val+len,s,slen+1);
len+=slen;
return *this;
}

string &string::operator+=(char c)
{
if(!c) return *this;
_expand(1);
val[len++]=c;
val[len]=0;
return *this;
}

string &string::operator+=(int i)
{
char buf[32];
sprintf(buf,"%i",i);
return *this+=buf;
}
string &string::operator+=(long i)
{
char buf[32];
sprintf(buf,"%li",i);
return *this+=buf;
}
string &string::operator+=(unsigned i)
{
char buf[32];
sprintf(buf,"%u",i);
return *this+=buf;
}
string &string::operator+=(unsigned long i)
{
char buf[32];
sprintf(buf,"%lu",i);
return *this+=buf;
}
string &string::operator+=(double i)
{
char buf[60];
sprintf(buf,"%f",i);
return *this+=buf;
}
static char emptystring[1]={'\0'};
string::operator char*()
{
if(val) return val;
else return emptystring;
}
char string::operator *()
{
if(val) return *val;
else return 0;
}
char string::operator[](int idx)
{
if(val&&(idx<(int)len)) return val[idx];
else return 0;
}
string &string::ltrim(void)
{
char *cp;
size_t nlen,i;
if(!val||!*val) return *this;
cp=val;
while((*cp==' ')||(*cp=='\t')||(*cp=='\n')||(*cp=='\r')) cp++;
if(cp==val) return *this;	//no spaces at begin
nlen=strlen(cp);
if(!nlen) {*val=0;len=0;return *this;} //all spaces, truncate
for(i=0;i<nlen+1;i++) val[i]=cp[i];
len=nlen;
return *this;
}
string &string::rtrim(void)
{
char *cp;
if(!val||!*val) return *this;
cp=val;
while(*cp) cp++;
cp--;
while((cp>val)&&((*cp==' ')||(*cp=='\t')||(*cp=='\n')||(*cp=='\r'))) cp--;
cp++;
*cp=0;
len=strlen(val);
return *this;
}
string &string::alltrim(void)
{
ltrim();
return rtrim();
}
string &string::lcase(void)
{
if(!val) return *this;
char *cp=val;
while(*cp) {*cp=tolower(*cp);cp++;}
return *this;
}
string &string::ucase(void)
{
if(!val) return *this;
char *cp=val;
while(*cp) {*cp=toupper(*cp);cp++;}
return *this;
}
