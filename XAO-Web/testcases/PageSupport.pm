package testcases::PageSupport;
use strict;
use Data::Dumper;
use XAO::Utils;
use base qw(testcases::base);

use XAO::PageSupport;

sub test_parse {
    my $self=shift;

    eval 'use Data::Compare';
    if($@) {
        print STDERR "\n" .
                     "Perl extension Data::Compare is not available,\n" .
                     "skipping XAO::PageSupport::parse tests\n";
        return;
    }

    my %matrix=(
        '' => [
        ],
        '0' => [
            {   text    => '0',
            },
        ],
        'aaa' => [
            {   text    => 'aaa',
            },
        ],
        'aaa<%%>bbb' => [
            {   text    => 'aaa<%',
            },
            {   text    => 'bbb',
            }
        ],
        # 'aaa<%BB%>' => [
        #     {   text    => 'aaa',
        #     },
        #     {   objname => 'BB',
        #     }
        # ],
        # '<%Date style="dateonly" gmtime=  {<%VAR/f%>} %>' => [
        #     {   objname => 'Date',
        #         args    => {
        #             style   => [
        #                 {   text    => 'dateonly',
        #                 },
        #             ],
        #             gmtime  => [
        #                 {   objname => 'VAR',
        #                     flags   => 'f',
        #                 },
        #             ],
        #         },
        #     },
        # ],
    );

    foreach my $template (keys %matrix) {
        my $parsed=XAO::PageSupport::parse($template);
        my $expect=$matrix{$template};
        my $rc=Compare($expect,$parsed);
        $rc ||
            dprint "========== Expect:",Dumper($expect),
                   "========== Got:",Dumper($parsed);
        $self->assert($rc,
                      "Wrong result for '$template'");
    }
}

sub test_textadd {
    my $self=shift;

    XAO::PageSupport::addtext("123abcABC");
    XAO::PageSupport::push();
    XAO::PageSupport::addtext("INNER");

    my $inner=XAO::PageSupport::pop();
    my $outer=XAO::PageSupport::pop();

    $self->assert($inner eq 'INNER',
                  "Inner block is not correct");

    $self->assert($outer eq '123abcABC',
                  "Outer block is not correct");

    $inner=$outer='';
    for(1..10) {
        XAO::PageSupport::addtext(scalar($_ * 13) x 5);
        XAO::PageSupport::addtext("Before \0 After");
        for(1..10) {
            XAO::PageSupport::addtext(scalar($_ * 29) x 5);
            XAO::PageSupport::push();
            for(1..10) {
                XAO::PageSupport::addtext("ABCdef\200\270\300\370");
                XAO::PageSupport::addtext("\3\2\1\0AFTER");
            } 
            $inner.=XAO::PageSupport::pop();
        }
    }
    $outer=XAO::PageSupport::pop();
    $self->assert(length($inner) == 19000,
                  "Got wrong inner block length");

    my $c1=unpack('%16C*',$inner);
    $self->assert($c1 eq 56136,
                  "Wrong checksum, probably zeroes are not handled correctly");

    $self->assert(length($outer) == 1605,
                  "Got wrong outer block length");

    my $c2=unpack('%16C*',$outer);
    $self->assert($c2 eq 21829,
                  "Wrong checksum for outer");
}

1;
