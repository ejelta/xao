#!/usr/bin/perl 

use lib qw(../blib/lib);
use XAO::P21;

XAO::P21->new->show_spool(sub { print "$_[0]\n" });
