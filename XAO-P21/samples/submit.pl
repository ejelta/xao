#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

my @static=('X' . substr(time, -7),"21CASH","020203","xaotst911",
            "4111111111111111","02","02",
            "John Silver",
            "123 Bad Guys Way","","Treasure Island","CA","91111",
            "INSTRUCTION 1","INSTRUCTION 2");

my @products=(
	[ "0","021200-24992","11","" ],
	[ "0","021200-24129","20","" ],
);

my $client=XAO::P21->new;

foreach my $prod (@products) {
    my $price = $client->price(customer=>"21CASH",
                               item=>$prod->[1],
                               quantity=>$prod->[2]);
    $prod->[3]=$price->{price}*$price->{mult};
}

my $seq=1;
my $result=
$client->order( join("\t", map {
           $_->[0]=$seq++;
           my $order_string=join("\t", @static, @$_, "");
           print join(':', @static, @$_, ""), "\n";
           $order_string;
           } @products) );
print "$result->[0]{result} $result->[0]{info}\n";
