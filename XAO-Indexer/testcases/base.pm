package testcases::base;
use strict;
use XAO::Utils;
use XAO::Base;
use XAO::Objects;
use XAO::Projects qw(:all);

use base qw(Test::Unit::TestCase);

use constant NAME_LENGTH => 50;
use constant TEXT_LENGTH => 500;

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

    $self->{config}=$config;

    $config->odb->fetch('/')->build_structure(
        Indexes => {
            type        => 'list',
            class       => 'Data::Index',
            key         => 'index_id',
        },
        Foo => {
            type        => 'list',
            class       => 'Data::Foo',
            key         => 'foo_id',
            key_format  => 'foo_<$AUTOINC$>',
            structure   => {
                Bar => {
                    type        => 'list',
                    class       => 'Data::Bar',
                    key         => 'bar_id',
                    key_format  => 'bar_<$AUTOINC$>',
                    structure   => {
                        name => {
                            type        => 'text',
                            maxlength   => NAME_LENGTH,
                        },
                        text => {
                            type        => 'text',
                            maxlength   => TEXT_LENGTH,
                        },
                    },
                },
                name => {
                    type        => 'text',
                    maxlength   => NAME_LENGTH,
                },
                text => {
                    type        => 'text',
                    maxlength   => TEXT_LENGTH,
                },
            },
        },
    );

    $config->odb->fetch('/Indexes')->get_new->build_structure;

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
