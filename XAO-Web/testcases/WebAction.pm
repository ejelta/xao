package testcases::WebAction;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::MyAction);
use Error qw(:try);

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object (page)");

    my $text=$page->expand(template => '<%MyAction mode="foo"%>');
    $self->assert($text eq 'Got FOO',
                  "Wrong text (got '$text', expected 'Got FOO')");

    my $errstr;
    try {
        $text=$page->expand(template => '<%MyAction mode="bar"%>');
        $errstr="Expected to fail, but returned '$text' instead";
    }
    catch XAO::E::DO::Web::MyAction with {
        $errstr='';
    }
    otherwise {
        my $e=shift;
        $errstr="Got wrong error ($e)";
    };
    $self->assert($errstr eq '',
                  $errstr);
}

1;
