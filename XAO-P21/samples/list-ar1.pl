#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

my $cl=XAO::P21->new;
my $result=$cl->list_open_ar(customer=>"21CASH");
foreach (@$result) {
    foreach my $key (keys %$_) {
        print qq($key="$_->{$key}" );
    }
    print "\n";
}

