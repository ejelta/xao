#!/usr/bin/perl -w

use lib qw(../blib/lib);
use XAO::P21;

my $client = XAO::P21->new;
#my $custlist = $client->custinfo(info=>\@ARGV);
my $custlist = $client->custinfo(info=>'21CASH');
undef @ARGV;

sub dumpcust {                              
        foreach my $key (keys %{$_[0]}) {
            print qq($key="$_[0]->{$key}" );
        }
        print "\n";
    }

dumpcust $_ foreach (@$custlist);

while(<>) {
    my ($cust_info, %params) = split;
    next unless $cust_info eq $custlist->[0]{cust_code};
    $custlist->[0]->{$_} = $params{$_} foreach (keys %params);
    $client->modcust($custlist->[0]);
}
