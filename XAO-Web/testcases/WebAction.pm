package testcases::WebAction;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::MyAction);
use XAO::Errors qw(XAO::DO::Web::Action);
use Error qw(:try);

use base qw(XAO::testcases::Web::base);

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object (page)");

    my %tests=(
        '<%MyAction%>'                                  => 'Got MODELESS',
        '<%MyAction mode="foo"%>'                       => 'Got FOO',
        '<%MyAction mode="bar"%>'                       => undef,
        '<%MyAction mode="test-one" arg="one"%>'        => 'test-one-ok',
        '<%MyAction mode="test-two" arg="two"%>'        => 'test-two-ok',
        '<%MyAction mode="test-three" format="json"%>'  => qr/^\s*\[\s*"foo"\s*,\s*"bar"/s,
        '<%MyAction mode="test-four"%>'                 => qr/status.*:.*success/s,
        #
        # Cross-polination of code cache checking
        #
        '<%MyAction2 mode="foo"%>'                      => 'MyAction2: Got FOO',
        '<%MyAction2 mode="test-one" arg="one"%>'       => 'MyAction2: test-one-ok',
    );

    foreach my $template (keys %tests) {
        my $expect=$tests{$template};

        my ($got,$err_my,$err_base,$err_unknown);
        try {
            $got=$page->expand(template => $template);
        }
        catch XAO::E::DO::Web::MyAction with {
            $err_my=''.shift;
        }
        catch XAO::E::DO::Web::Action with {
            $err_base=''.shift;
        }
        otherwise {
            $err_unknown=''.shift;
        };

        if(defined $expect) {
            $self->assert(!$err_unknown,
                "Got an UNKNOWN error '$err_unknown' for '$template'");

            $self->assert(!$err_base,
                "Got an BASE error '$err_base' for '$template'");

            $self->assert(!$err_my,
                "Got an LOCAL error '$err_my' for '$template'");

            if(ref $expect eq 'Regexp') {
                $self->assert($got =~ /$expect/,
                    "Expected '$expect', got '$got' for '$template' (regex)");
            }
            else {
                $self->assert($got eq $expect,
                    "Expected '$expect', got '$got' for '$template' (plain)");
            }
        }
        else {
            $self->assert(!defined $got,
                "Expected a failure, got '$got' for '$template'");

            $self->assert(!$err_unknown,
                "Expected a custom error, got generic '$err_unknown' for '$template'");

            $self->assert(!$err_base,
                "Expected a custom error, got generic '$err_base' for '$template'");

            $self->assert($err_my,
                "Expected an error, got no error and no result for '$template'");
        }
    }
}

###############################################################################
1;
