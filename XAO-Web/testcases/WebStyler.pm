package testcases::WebStyler;
use strict;
use CGI;
use XAO::Utils;
use XAO::Web;

use base qw(testcases::base);

###############################################################################

sub test_all {
    my $self=shift;

    # XXX severely incomple and needs cleaner interface. Before
    # modifying interface add tests for all old ways of calling it!

    my %matrix=(
        t1 => {
            template => '<%Styler dollars="1234.567"%>',
            result => '$1,234.57',
        },
        t2 => {
            template => '<%Styler dollars="1234.567" format="%.0f"%>',
            result => '$1,235',
        },
        t3 => {
            template => '<%Styler dollars="33.415"%>',
            result => '$33.42',
        },
        t4 => {
            template => '<%Styler dollars="33.7"%>',
            result => '$33.70',
        },
        t5 => {
            template => '<%Styler dollars="3.5999"%>',
            result => '$3.60',
        },
    );

    my $page=XAO::Objects->new(objname => 'Web::Page');
    foreach my $test (keys %matrix) {
        my $template=$matrix{$test}->{template};
        my $expect=$matrix{$test}->{result};
        my $got=$page->expand(template => $template);

        $self->assert($got eq $expect,
                      "Test $test failed - on '$template' expected '$expect', got '$got'");
    }
}

###############################################################################
1;
