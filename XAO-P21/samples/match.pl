#!/usr/bin/perl 

use lib qw(../blib/lib);
use XAO::P21;

my $res = XAO::P21->new->
    find_match(refs => [ 'OLTY6GP6', 'D62CP6KT', ],
               callback => sub {                              
                    foreach my $key (keys %{$_[0]}) {
                        print qq($key="$_[0]->{$key}" );
                    }
                    print "\n";
                    });
