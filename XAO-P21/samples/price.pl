#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

my $client = XAO::P21->new;
my ($item, $quan) = @ARGV;
my $list = $client->price(item => $item, quantity => $quan);
print "$list->{price} $list->{mult} $list->{total}\n";
