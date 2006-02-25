#ifndef __S_STRING_
#define __S_STRING_
#include <stdlib.h>
#include <ctype.h>

//size_t strlen(string &s) {return s.length();}


class string
{
char *val;
size_t len;
size_t allocated;
void _expand(size_t);
public:
string();
~string();
size_t length() {return len;}
operator char* ();
char operator*();
char operator[](int idx);
const char *operator=(const char*);
char     operator=(char);
string  &operator=(string&);
int      operator=(int);
int long operator=(int long);
unsigned operator=(unsigned);
unsigned long operator=(unsigned long);
double operator=(double);
string operator+(char*);
string operator+(string &);
string operator+(char);
string operator+(int);
string operator+(long);
string operator+(unsigned);
string operator+(unsigned long);
string operator+(double);
string &operator+=(const char*);
string &operator+=(string &);
string &operator+=(char);
string &operator+=(int);
string &operator+=(long);
string &operator+=(unsigned);
string &operator+=(unsigned long);
string &operator+=(double);
string &ltrim(void);
string &rtrim(void);
string &alltrim(void);
string &lcase(void);
string &ucase(void);
};

#endif
