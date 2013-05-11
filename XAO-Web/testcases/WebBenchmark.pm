package testcases::WebBenchmark;
use strict;
use JSON;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    my $benchmark=XAO::Objects->new(objname => 'Web::Benchmark');

    $benchmark->expand('mode' => 'system-start');

    $self->assert($page->benchmark_enabled(),
        "Benchmarking is not enabled after 'benchmark-start'");

    $benchmark->expand('mode' => 'system-stop');

    $self->assert(! $page->benchmark_enabled(),
        "Benchmarking is not disabled after 'benchmark-stop'");

    $benchmark->expand('mode' => 'system-start');

    $self->assert($page->benchmark_enabled(),
        "Benchmarking is not enabled after 'benchmark-start' (2)");

    $page->expand(template => 'blah');

    $page->expand(path => '/bits/system-test', TEST => 'foo');

    $page->expand(path => '/bits/complex-template');
    $page->expand(path => '/bits/complex-template');

    my $stats=$page->benchmark_stats();

    use Data::Dumper;
    dprint "STATS: ".Dumper($stats);

    $self->assert(ref $stats eq 'HASH',
        "Expected to get a HASH from benchmark_stats()");

    my $stats2=XAO::Objects->new(objname => 'Web::Action')->benchmark_stats();

    $self->assert(ref $stats2 eq 'HASH',
        "Expected to get a HASH from benchmark_stats()");

    my $json1=to_json($stats,{ canonical => 1 });
    my $json2=to_json($stats2,{ canonical => 1 });

    $self->assert($json1 eq $json2,
        "Expected to get identical stats from two web objects ($json1 != $json2)");

    my $count=$stats->{'p:/bits/system-test'}->{'count'} || 0;
    $self->assert($count == 1,
        "Expected p:/bits/system-test count to be 1, got $count");

    $count=$stats->{'p:/bits/complex-template'}->{'count'} || 0;
    $self->assert($count == 2,
        "Expected p:/bits/complex-template count to be 2, got $count");
}

###############################################################################
1;
