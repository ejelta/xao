package testcases::WebSetArg;
use strict;
use XAO::Projects;

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $template='<%SetArg name="TEST" value="NEW"%><%TEST%><%End%>';

    my %matrix=(
        t1 => {
            args => {
                TEST => 'OLD',
            },
            result => 'OLD',
        },
        t2 => {
            args => {
            },
            result => 'NEW',
        },
        t3 => {
            args => {
                TEST => undef,
            },
            result => 'NEW',
        },
    );

    foreach my $test (keys %matrix) {
        my $args=$matrix{$test}->{args};
        $args->{template}=$template;
        my $got=$page->expand($args);
        my $expect=$matrix{$test}->{result};
        $self->assert($got eq $expect,
                      "Test $test failed - expected '$expect', got '$got'");
    }
}

1;
