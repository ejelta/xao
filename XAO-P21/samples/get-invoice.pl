#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

my $client=XAO::P21->new;
my ($customer, $order, $shipment) = @ARGV;
my $result=$client->invoice_recall(customer=>$customer,
                                   order=>$order,
                                   shipment=>$shipment);
print join("\n", @$result, "");
