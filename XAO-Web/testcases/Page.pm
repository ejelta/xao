package testcases::Page;
use strict;
use XAO::Objects;

use base qw(testcases::base);

sub test_everything {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $str='\'"!@#$%^&*()_-=[]\<>?';
    my %ttt=(
        '<%TEST%>'      => $str,
        '<%TEST/h%>'    => '\'"!@#$%^&amp;*()_-=[]\&lt;&gt;?',
        '<%TEST/f%>'    => '\'&quot;!@#$%^&amp;*()_-=[]\&lt;&gt;?',
        '<%TEST/q%>'    => '\'%22!@%23$%25^%26*()_-%3d[]\%3c%3e%3f',
    );
    foreach my $template (keys %ttt) {
        my $got=$page->expand(template => $template,
                              TEST => $str);
        $self->assert($got eq $ttt{$template},
                      "Wrong value for $template ('$got' ne '$ttt{$template}'");
    }

    $self->assert(0,
                  "Need more database and file template tests");
}

1;
