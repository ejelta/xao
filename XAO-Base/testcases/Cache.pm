package testcases::Cache;
use strict;
use XAO::SimpleHash;
use XAO::Utils;
use XAO::Cache;

use base qw(testcases::base);

sub test_everything {
    my $self=shift;

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

sub test_size {
    my $self=shift;

    my $counter=0;
    my $cache=XAO::Cache->new(
        retrieve    => sub {
            my $args=get_args(\@_);
            return $args->{name} . '-' . $counter++;
        },
        expire      => 10,
        size        => 0.04,
        coords      => 'name',
    );

    my @matrix=(
        aaaa    => 'aaaa-0',
        aaaa    => 'aaaa-0',
        bbbb    => 'bbbb-1',
        aaaa    => 'aaaa-0',
        bbbb    => 'bbbb-1',
        cccc    => 'cccc-2',
        bbbb    => 'bbbb-1',
        dddd    => 'dddd-3',
        aaaa    => 'aaaa-0',
        bbbb    => 'bbbb-1',
        cccc    => 'cccc-2',
        dddd    => 'dddd-3',
        eeee    => 'eeee-4',
        aaaa    => 'aaaa-5',
        bbbb    => 'bbbb-6',
        cccc    => 'cccc-7',
        dddd    => 'dddd-8',
        eeee    => 'eeee-9',
    );

    for(my $i=0; $i!=@matrix; $i+=2) {
        my $expect=$matrix[$i+1];
        my $got=$cache->get(name => $matrix[$i]);
        $self->assert($got eq $expect,
                      "Test ".($i/2)." failed (expected '$expect', got '$got')");
    }
}

sub test_drop {
    my $self=shift;

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

    $cache->get(name => 'd1');
    $cache->get(name => 'd2');
    $cache->get(name => 'd3');
    $cache->get(name => 'd4');
    $cache->get(name => 'd5');

    my @matrix=(
        d1 => {
            d1  => '5-d1-',
            d2  => '1-d2-',
            d3  => '2-d3-',
            d4  => '3-d4-',
            d5  => '4-d5-',
        },
        d5 => {
            d1  => '5-d1-',
            d2  => '1-d2-',
            d3  => '2-d3-',
            d4  => '3-d4-',
            d5  => '6-d5-',
        },
        d3 => {
            d1  => '5-d1-',
            d2  => '1-d2-',
            d3  => '7-d3-',
            d4  => '3-d4-',
            d5  => '6-d5-',
        },
        d4 => {
        },
        d2 => {
        },
        d5 => {
        },
        d1 => {
        },
        d3 => {
            d1  => '8-d1-',
            d2  => '9-d2-',
            d3  => '10-d3-',
            d4  => '11-d4-',
            d5  => '12-d5-',
        },
    );

    for(my $i=0; $i<@matrix; $i+=2) {
        my $dn=$matrix[$i];
        my $expect=$matrix[$i+1];
        $cache->drop(name => $dn);
        foreach my $en (sort keys %$expect) {
            my $got=$cache->get(name => $en);
            $self->assert($got eq $expect->{$en},
                          "Got wrong value after dropping $dn (expect '$expect->{$en}', got '$got')");
        }
    }
}

1;
