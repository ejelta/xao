#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

my $cl=XAO::P21->new;
my $result=$cl->view_open_order_details(customer=>"21CASH", order=>$ARGV[0]);

foreach (@$result) {
    foreach my $key (keys %$_) {
        print qq($key="$_->{$key}" );
    }
    print "\n";
}

