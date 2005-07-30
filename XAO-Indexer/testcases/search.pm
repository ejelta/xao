package testcases::search;
use strict;
use XAO::Utils;
use Data::Dumper;

use base qw(testcases::base);

sub test_search {
    my $self=shift;
    my $odb=$self->{config}->odb;

    $self->generate_content();

    ##
    # Creating a new index
    #
    my $index_list=$odb->fetch('/Indexes');
    my $index_new=$index_list->get_new;
    $index_new->put(indexer_objname => 'Indexer::Foo');
    $index_list->put(foo => $index_new);
    my $foo_index=$index_list->get('foo');
    dprint "Updating foo index";
    $foo_index->update;

    ##
    # Searching and checking if results we get are correct
    #
    my %matrix=(
        t01 => {
            query       => 'is',
            name        => '',
            text        => '',
        },
        t02 => {
            query       => '   "burden"',
            name        => '57,2,33,115,12,17,62,143,21,76',
        },
        t03 => {
            query       => ' BurDEN  ',
            text        => '2,76,62,33,57,12,17,21,115,143',
        },
        t04 => {
            query       => 'burden',
            name_wnum   => '57,62,2,21,76,143,12,17,33,115',
        },
        t05 => {
            query       => 'foo',
            name        => '',
        },
        t06 => {
            query       => 'should work with alien',
            name        => '93,66,14,33,133,28,129,17,120,46,88',
        },
        t07 => {
            query       => '"should work with alien"',
            name        => 17,
        },
        t08 => {
            query       => '"should the the alien"',
            name        => 17,
            ignored     => {
                the         => 150,
                should      => undef,
            }
        },
        t09 => {
            query       => '"glassy hypothesis" "A display calls"',
            name        => 147,
            ignored     => {
                a           => 145,
                display     => undef,
            },
        },
        t10 => {
            query       => 'believe',
            text        => '121,50,32,85,52,138,4,147,11,33,84,48,146,99,150,112,91,148,144,82',
        },
        t11 => {
            query       => 'believe rocket',
            text        => '32,147,146,112,91,144',
        },
        t12 => {
            query       => 'believe rocket space',
            text        => '32,147,112,91',
        },
        t13 => {
            query       => 'believe rocket space watch',
            text        => '32,147,91',
        },
        t14 => {
            query       => 'believe rocket space watch alien',
            text        => '32,91',
        },
        t15 => {
            query       => 'believe rocket space watch alien mice',
            text        => '',
        },
        t16 => {
            query       => 'believe rocket space watch',
            text        => 'foo_32,foo_147,foo_91',
            use_oid     => 1,
        },
    );
    foreach my $test_id (keys %matrix) {
        my $test=$matrix{$test_id};
        my $query=$test->{query};
        foreach my $oname (sort keys %$test) {
            next if $oname eq 'query';
            next if $oname eq 'ignored';
            next if $oname eq 'use_oid';
            my %rcdata;
            my $sr;
            if($test->{'ignored'}) {
                $sr=$test->{'use_oid'} ? $foo_index->search_by_string_oid($oname,$query,\%rcdata)
                                       : $foo_index->search_by_string($oname,$query,\%rcdata);
                foreach my $w (keys %{$test->{ignored}}) {
                    my $expect=$test->{ignored}->{$w};
                    my $got=$rcdata{ignored_words}->{$w};
                    if(defined $expect) {
                        $self->assert(defined($got),
                                      "Expected '$w' to be ignored, but it is not");
                        $self->assert($got == $expect,
                                      "Expected count $expect on ignored $w, got $got");
                    }
                    else {
                        $self->assert(!defined($got),
                                      "Expected '$w' not to be ignored, but it is (count=".($got||'').")");
                    }
                }
            }
            else {
                $sr=$test->{'use_oid'} ? $foo_index->search_by_string_oid($oname,$query)
                                       : $foo_index->search_by_string($oname,$query);
            }
            my $got=join(',',@$sr);
            my $expect=$test->{$oname};
            ### if($got ne $expect) {
            ###     dprint "===>>>> test=$test_id o=$oname got='$got' expected='$expect'";
            ### }
            $self->assert($got eq $expect,
                          "Test $test_id, ordering $oname, expected $expect, got $got");
        }
    }
}

1;
