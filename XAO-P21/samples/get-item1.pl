#!/usr/bin/perl 

use lib qw(../blib/lib);
use XAO::P21;

XAO::P21->new->items(
    sub {                              
#        my @zuka=map {$_ . '="' . $_[0]->{$_} . '"'} keys %{$_[0]} ;
#        print join(' ', @zuka, "\n");
        foreach my $key (keys %{$_[0]}) {
            print qq($key="$_[0]->{$key}" );
        }
        print "\n";
    });
