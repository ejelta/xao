package testcases::base;
use strict;

use base qw(Test::Unit::TestCase);

sub set_up {
    my $self=shift;
}

sub tear_down {
    my $self=shift;
}

sub timestamp ($$) {
    my $self=shift;
    time;
}

sub timediff ($$$) {
    my $self=shift;
    my $t1=shift;
    my $t2=shift;
    $t1-$t2;
}

1;
