package testcases::linkage;
use strict;
use XAO::Utils;

use base qw(testcases::base);

sub test_linkage {
    my $self=shift;
    my $odb=$self->get_odb;

    my $customer=$odb->fetch('/Customers/c1');
    $self->assert($customer, "Can't load a customer");

    $self->assert(defined($customer->can('container_object')),
                  "Can't call container_object() on FS::Hash object!");

    my $list=$customer->container_object;
    $self->assert(ref($list),
                  "Can't get container_object for customer");
    $self->assert($list->get('c2')->container_key eq 'c2',
                  "Something is wrong with the customers list");

    $self->assert(defined($list->can('container_object')),
                  "Can't call container_object() on FS::List object!");

    my $global=$list->container_object;
    $self->assert(ref($global) && $global->get('project'),
                  "Got wrong global object from List");
}

1;
