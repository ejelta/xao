/* MySQL driver for XAO::FS. Does not use DBI to speed things up.
 *
 * XAO Inc., Andrew Maltsev, <am@xao.com>, July 2001
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mysql/mysql.h>

MODULE = XAO::DO::FS::Glue::MySQL PACKAGE = XAO::DO::FS::Glue::MySQL

PROTOTYPES: ENABLE

MYSQL *
connect(dbname,host,user,passwd)
        char *dbname;
        char *host;
        char *user;
        char *passwd;
    INIT:
        MYSQL *db;
    CODE:
        fprintf(stderr,"Connecting to the database (%s,%s,%s,%s)\n",
                       dbname,host,user,passwd);

        RETVAL=NULL;
        New(0,db,1,MYSQL);
        mysql_init(db);
        if(mysql_real_connect(db,host,user,passwd,dbname,0,NULL,0)) {
            RETVAL=db;

        }
    OUTPUT:
        RETVAL

void
disconnect(db)
        MYSQL *db;
    CODE:
        mysql_close(db);

