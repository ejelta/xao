package testcases::WebCondition;
use strict;
use XAO::Projects;

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $template=<<'EOT';
<%Condition
  v1.value="<%V1%>"
  v1.template="GOT-V1"
  v2.arg="V2"
  v2.path="/bits/WebCondition/text-v2"
  default.template={<%Page/f path="/bits/WebCondition/text-default"%>}
%><%End%>
EOT

    my %matrix=(
        t1 => {
            args => {
                V1 => 1,
            },
            result => 'GOT-V1',
        },
        t2 => {
            args => {
                V1 => '',
                V2 => ' ',
            },
            result => 'GOT-V2',
        },
        t3 => {
            args => {
                V1 => 'x',
                V2 => 'y',
            },
            result => 'GOT-V1',
        },
        t4 => {
            args => {
                V1 => '',
            },
            result => 'DEFAULT',
        },
        t5 => {
            args => {
                V1 => 0,
                V2 => '000',
            },
            result => 'GOT-V2',
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

    $template=<<'EOT';
<%Condition
  v1.length="<%V1%>"
  v1.template="GOT-V1"
  default.template="DEFAULT"
%><%End%>
EOT

    %matrix=(
        t1 => {
            args => {
                V1 => 0,
            },
            result => 'GOT-V1',
        },
        t2 => {
            args => {
                V1 => '',
            },
            result => 'DEFAULT',
        },
        t3 => {
            args => {
                V1 => 'x',
            },
            result => 'GOT-V1',
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
