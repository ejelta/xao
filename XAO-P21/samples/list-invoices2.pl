#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

my $cl=XAO::P21->new;

my $list={};

$cl->list_all_invoices(customer=>"21CASH",
    callback=>sub { push @{$list->{$_[0]->{order}}}, $_[0]->{shipment} }
    );

foreach (keys %$list) {
    print "Order: $_\tshipments [",
        join(' ', @{$list->{$_}}), "]\n";
}
