package testcases::base;
use strict;
use CGI;
use XAO::Utils;
use XAO::Base;
use XAO::Objects;
use XAO::Projects qw(:all);

use base qw(Test::Unit::TestCase);

sub siteconfig {
    my $self=shift;
    return $self->{'siteconfig'};
}

sub set_up {
    my $self=shift;

    chomp(my $root=`pwd`);
    $root.='/testcases/testroot';
    XAO::Base::set_root($root);

    my $config=XAO::Objects->new(objname => 'Config',
                                 sitename => 'test');
    create_project(name => 'test',
                   object => $config,
                   set_current => 1);
    $config->init();

    my $cgi=CGI->new('foo=bar&test=1');

    $config->embedded('web')->enable_special_access();
    $config->cgi($cgi);
    $config->embedded('web')->disable_special_access();

    $self->{'siteconfig'}=$config;

    push @INC,$root;
}

sub tear_down {
    my $self=shift;
    drop_project('test');
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
