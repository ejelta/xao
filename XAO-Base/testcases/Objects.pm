package testcases::Objects;
use strict;
use XAO::SimpleHash;
use XAO::Utils;
use Error qw(:try);
use XAO::Errors qw(XAO::Errors::Objects);

use base qw(testcases::base);

sub test_everything {
    my $self=shift;

    use XAO::Objects;

    ##
    # Loading `test' project Config
    #
    my $obj=XAO::Objects->new(objname => 'Config',
                              sitename => 'test');

    $self->assert(ref($obj),
                  "new(Config) did not return an object reference");
    my $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::test::Config',
                  "new(Config) returned an object of wrong type ($ref)");

    use XAO::Projects;
    XAO::Projects::create_project(name => 'test',
                                  object => $obj,
                                  set_current => 1);

    $obj=XAO::Objects->new(objname => 'Test1');
    $self->assert(ref($obj),
                  "new(Test1) did not return an object reference");
    $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::test::Test1',
                  "new(Test1) returned an object of wrong type ($ref)");

    $obj=XAO::Objects->new(objname => 'Test2');
    $self->assert(ref($obj),
                  "new(Test2) did not return an object reference");
    $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::Test2',
                  "new(Test2) returned an object of wrong type ($ref)");

    $obj=XAO::Objects->new(objname => 'Test1', baseobj => 1);
    $self->assert(ref($obj),
                  "new(Test1,base) did not return an object reference");
    $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::Test1',
                  "new(Test1,base) returned an object of wrong type ($ref)");
}

1;
