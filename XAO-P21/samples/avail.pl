#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;


XAO::P21->new->avail(item=>['021200-82221', '021200-41604'],
                     callback=>sub {
                        my $o=shift;
                        print
                            qq(ItemCode="$o->{code}: ),
                            qq(Location="$o->{location}"/$o->{location_code}, ),
                            qq(StockLevel=$o->{stock_level} $o->{unit}, $o->{description}\n);
                     });
