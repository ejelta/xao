package testcases::Cache;
use strict;
use XAO::SimpleHash;
use XAO::Utils;

use base qw(testcases::base);

sub test_everything {
    my $self=shift;

    use XAO::Cache;

    my $count=0;
    my $cache=XAO::Cache->new(
        retrieve    => sub {
            my $self=ref($_[0]) && ref($_[0]) ne 'HASH' ? shift : '';
            my $args=get_args(\@_);
            return $count++ . '-' .
                   $args->{name} . '-' .
                   ($args->{subname} || '');
        },
        coords      => ['name','subname'],
        size        => 2,
        expire      => 3,
    );
    $self->assert(ref($cache),
                  "Can't create Cache");

    my $d1=$cache->get(name => 'd1');
    $self->assert($d1 eq '0-d1-',
                  "Got wrong value for d1 (expected '0-d1-', got '$d1')");

    my $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);
    $self->assert($d2 eq '1-d2-s2',
                  "Got wrong value for d2 (expected '1-d2-s2', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's3', foo => 123);
    $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);

    ##
    # Checking if it is expired
    #
    sleep(4);
    $d1=$cache->get(name => 'd1', bar => 234);
    $self->assert($d1 eq '3-d1-',
                  "Got wrong value for d1 (expected '3-d1-', got '$d1')");

    for(my $i=0; $i!=100; $i++) {
        $d2=$cache->get(name => 'd2', subname => $i);
    }

    $d1=$cache->get(name => 'd1', bar => 234);
    $self->assert($d1 eq '3-d1-',
                  "Got wrong value for d1 (expected '3-d1-', got '$d1')");

    for(my $i=100; $i!=300; $i++) {
        $d2=$cache->get(name => 'd2', subname => $i);
    }

    ##
    # At that point it should be thrown out because of size
    #
    $d1=$cache->get(name => 'd1', bar => 234);
    $self->assert($d1 eq '304-d1-',
                  "Got wrong value for d1 (expected '304-d1-', got '$d1')");
}

1;
