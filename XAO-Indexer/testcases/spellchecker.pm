package testcases::spellchecker;
use strict;
use XAO::Utils;
use Data::Dumper;

use base qw(testcases::base);

sub test_spellchecker {
    my $self=shift;

    ##
    # Checking if spellchecking is available
    #
    eval "use Text::Aspell";
    if($@) {
        print STDERR "Text::Aspell is not available, skipping tests\n";
        return;
    }
    else {
        my $speller=Text::Aspell->new;
        $speller->set_option(lang => 'en_US');
        my @sugs=$speller->suggest('usggest');
        if(!@sugs || $sugs[0] ne 'suggest') {
            print STDERR "Text::Aspell is unusable (no en_US dictionary?), skipping tests\n";
            return;
        }
    }

    ##
    # Standard content
    #
    $self->generate_content();

    ##
    # Changing config to activate the spellchecker
    #
    my $config=$self->{'config'};
    $config->put('/indexer/default/spellchecker' => {
        objname     => 'Indexer::SpellChecker::Embedded',
        options     => {
            lang        => 'en_US',
        },
    });
    dprint Dumper($config->get('indexer'));
 
    ##
    # Creating a new index
    #
    my $index_list=$config->odb->fetch('/Indexes');
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
            query       => 'insewerants understant',
            name        => 147,
            speller     => {
            },
        },
    );
    foreach my $test_id (keys %matrix) {
        my $test=$matrix{$test_id};
        my $query=$test->{'query'};
        foreach my $oname (sort keys %$test) {
            next if $oname eq 'query';
            next if $oname eq 'ignored';
            next if $oname eq 'use_oid';
            next if $oname eq 'speller';
            my %rcdata;
            my $sr;
            if($test->{'ignored'} || $test->{'speller'}) {
                $sr=$test->{'use_oid'} ? $foo_index->search_by_string_oid($oname,$query,\%rcdata)
                                       : $foo_index->search_by_string($oname,$query,\%rcdata);
                if($test->{'speller'}) {
                    my $got=$rcdata{'spellchecker_words'};
                    dprint Dumper($got);
                    die "Kaboom!";
                }
                if($test->{'ignored'}) {
                    foreach my $w (keys %{$test->{'ignored'}}) {
                        my $expect=$test->{'ignored'}->{$w};
                        my $got=$rcdata{'ignored_words'}->{$w};
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
