package testcases::WebClipboard;
use strict;
use XAO::Projects;

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    $page->clipboard->put('foo' => 'bar');
    $page->clipboard->put('/fu/foo' => 'fubar');

    my $template='<%Clipboard mode="show" name="<%NAME/f%>" default="DFLT"%>';

    my %matrix=(
        t1 => {
            args => {
                NAME => 'nothing',
            },
            result => 'DFLT',
        },
        t2 => {
            args => {
                NAME => 'foo',
            },
            result => 'bar',
        },
        t3 => {
            args => {
                NAME => 'fu/foo',
            },
            result => 'fubar',
        },
        t4 => {
            args => {
                NAME => '/fu/foo',
            },
            result => 'fubar',
        },
        t5 => {
            args => {
                NAME => '////foo',
            },
            result => 'bar',
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
