package testcases::Page;
use strict;
use XAO::Objects;

use base qw(testcases::base);

sub test_expand {
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

    my $got=$page->expand(path => '/system.txt',
                          TEST => 'TEST<>?');
    $self->assert($got eq 'system:[[TEST<>?][TEST&lt;&gt;?]]',
                  "Got wrong value for /system.txt: $got");

    $got=$page->expand(path => '/local.txt',
                       TEST => 'TEST<>?');
    $self->assert($got eq 'system:[[TEST<>?]{TEST&lt;&gt;?}]',
                  "Got wrong value for /local.txt: $got");
}

sub test_fs {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $odb=$page->odb;
    $self->assert(ref($odb),
                  "Can't get database reference from Page");
}

sub test_web {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $cgi=$page->cgi;
    $self->assert(ref($cgi),
                  "Can't get CGI reference from Page");
}

sub test_end {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $got=$page->expand(template => 'AAA<%End%>BBB');
    my $expect='AAA';
    $self->assert($got eq $expect,
                  "<%End%> does not work, got '$got' instead of '$expect'");
}

1;
