package testcases::DOConfig;
use strict;
use XAO::SimpleHash;
use XAO::Projects;
use XAO::Objects;

use base qw(testcases::base);

sub test_base {
    my $self=shift;

    my $config=XAO::Objects->new(objname => 'Config', baseobj => 1);
    $self->assert(ref($config),
                  "Can't get config");

    my $hash=XAO::SimpleHash->new(foo => 'bar');
    $self->assert(ref($hash),
                  "Can't get SimpleHash object");

    $config->embed('hash' => $hash);

    my $got=$config->get('foo');
    $self->assert($got eq 'bar',
                  "Got wrong value from config -- '$got' ne 'bar'");

    $config->put('test' => 123);
    $got=$config->get('test');
    $self->assert($got == 123,
                  "Got wrong value after put -- '$got' != 123");

    $got=join(',',sort $config->keys);
    $self->assert($got eq 'foo,test',
                  "Got wrong keys from config -- '$got' ne 'foo,test'");
}

sub test_project {
    my $self=shift;

    my $config=XAO::Objects->new(objname => 'Config', sitename => 'test');
    $self->assert(ref($config),
                  "Can't get config");

    XAO::Projects::create_project(
        name => 'test',
        object => $config,
        set_current => 1
    );

    $config->init();

    my $got=$config->fubar('123');
    $self->assert($got eq 'X123X',
                  "Execution chain does not work for siteobj ($got ne X123X)");
}

1;
