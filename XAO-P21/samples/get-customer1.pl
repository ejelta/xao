#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

XAO::P21->new->custinfo(
    sub {                              
        foreach my $key (keys %{$_[0]}) {
            print qq($key="$_[0]->{$key}" );
        }
        print "\n";
    });
