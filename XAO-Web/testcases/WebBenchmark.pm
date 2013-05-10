package testcases::WebBenchmark;
use strict;
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
}

###############################################################################
1;
