#!/usr/bin/perl 

use lib qw(../blib/lib);
use XAO::P21;

XAO::P21->new->cleanup_spool(file => ['foo.bar', 'baz.qux']);
