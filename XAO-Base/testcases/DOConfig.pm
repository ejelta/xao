package testcases::DOConfig;
use strict;
use XAO::Utils;
use XAO::SimpleHash;
use XAO::Projects;
use XAO::Objects;
use Error qw(:try);

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

    $self->assert(ref($config->embedded('hash')) eq 'XAO::SimpleHash',
                  "Can't use embedded() to get an object");
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

    $self->assert($config->get('LocalConfig') == 1,
                  "Initialization did not make it to the local config");

    $config->cleanup();
}

sub test_double {
    my $self=shift;

    my $c1=XAO::Objects->new(objname => 'Config', baseobj => 1);
    $self->assert(ref($c1),
                  "Can't get c1");
    $c1->embed('hash' => XAO::SimpleHash->new);

    my $c2=XAO::Objects->new(objname => 'Config', baseobj => 1);
    $self->assert(ref($c2),
                  "Can't get c2");
    $c2->embed('hash' => XAO::SimpleHash->new);
}

sub test_error {
    my $self=shift;

    use XAO::Errors qw(XAO::E::DO::Config);

    my $c=XAO::Objects->new(objname => 'Config', baseobj => 1);

    my $errstr;
    try {
        $c->embedded('foo');
        $errstr="Not failed where it should";
    }
    catch XAO::E::DO::Config with {
        $errstr='';
    }
    otherwise {
        my $e=shift;
        $errstr="Unexpected error ($e)";
    };

    $self->assert($errstr eq '',
                  $errstr);
}

1;
