##
# This test case checks how fast `dictionarized' search works. It adds two
# fields to the Customer, one just text, the second one of `words' type. Then it
# stores a couple of thousand lines or text and then searches on both fields.
#
# Success is not just when it works, but when searching on `words' is faster,
# then searching on `text'.
#
##
package testcases::dictionary;
use strict;
use XAO::Utils;
use XAO::Objects;

use base qw(testcases::base);

sub test_words {
    my $self=shift;

	##
	# Disabled temporary for the following reasons:
	# * Does not work with 5.005.03 perl's Benchmark
	# * Dictionary is going to be changed anyway, it is not usable curently.
    #
	return 0;

    my $odb=$self->get_odb();

    my $custlist=$odb->fetch('/Customers');

    my $customer=XAO::Objects->new(objname => 'Data::Customer', glue => $odb);
    $self->assert(ref($customer),
                  "Can't create Customer");

    $customer->add_placeholder(name => 'text_normal',
                               type => 'text',
                               maxlength => 1000);

    $customer->add_placeholder(name => 'text_words',
                               type => 'words',
                               maxlength => 1000);

    $customer->add_placeholder(name => 'big_1',
                               type => 'text',
                               maxlength => 1000);

    $customer->add_placeholder(name => 'big_2',
                               type => 'text',
                               maxlength => 1000);

    $customer->add_placeholder(name => 'big_3',
                               type => 'text',
                               maxlength => 1000);

    my $value='John';
    $customer->put(name => $value);
    $customer->put(text_words => $value);
    $customer->put(text_normal => $value);
    $custlist->put(words1 => $customer);
    my $c1=$odb->fetch('/Customers/words1');
    my $got=$c1->get('text_words');

    $self->assert($got eq $value,
                  "Got ($got) not what was stored ($value) (1)");

    $value='Peter John John John';
    $customer->put(name => $value);
    $customer->put(text_words => $value);
    $customer->put(text_normal => $value);
    $custlist->put(words2 => $customer);
    my $c2=$custlist->get('words2');
    $got=$c2->get('text_words');

    $self->assert($got eq $value,
                  "Got ($got) not what was stored ($value) (2)");

    $value='Ann John Marie';
    $c1->put(text_normal => $value);
    $c1->put(text_words => $value);
    $got=$c1->get('text_words');

    $self->assert($got eq $value,
                  "Got ($got) not what was stored ($value) (3)");

    my @words=qw(I am not a politician and my other habits are also good.
                 Almost everything in life is easier to get into than out of.
                 The reward of a thing well done is to have done it.
                 /earth is 98% full ... please delete anyone you can.
                 Hoping to goodness is not theologically sound. - Peanuts
                 There is a Massachusetts law requiring all dogs to have
                 their hind legs tied during the month of April.
                 live lively livery
The man scarce lives who is not more credulous than he ought to be.... The
natural disposition is always to believe.  It is acquired wisdom and experience
only that teach incredulity  and they very seldom teach it enough.
- Adam Smith
Kansas state law requires pedestrians crossing the highways at night to
wear tail lights.
Very few things actually get manufactured these days  because in an
infinitely large Universe  such as the one in which we live  most things one
could possibly imagine  and a lot of things one would rather not  grow
somewhere.  A forest was discovered recently in which most of the trees grew
ratchet screwdrivers as fruit.  The life cycle of the ratchet screwdriver is
quite interesting.  Once picked it needs a dark dusty drawer in which it can
lie undisturbed for years.  Then one night it suddenly hatches  discards its
outer skin that crumbles into dust  and emerges as a totally unidentifiable
little metal object with flanges at both ends and a sort of ridge and a hole
for a screw.  This  when found  will get thrown away.  No one knows what the
screwdriver is supposed to gain from this.  Nature  in her infinite wisdom 
is presumably working on it.
                );
    $customer->put(name => 'Search Test Customer');
    for(1..500) {
        my $str='';
        for(my $i=int(rand(80)+20); $i; $i--) {
            $str.=' ' if $str;
            $str.=$words[rand(@words)];
        }
        $customer->put(text_normal => $str);
        $customer->put(text_words => $str);
        $customer->put(big_1 => $str);
        $customer->put(big_2 => $str);
        $customer->put(big_3 => $str);
        $custlist->put($customer);
    }

    ##
    # Checking that search results on dictionary are equal to those of
    # normal field search. We do not check if these results are valid -
    # this is checked in the other test case.
    #
    foreach my $pattern (qw(a LiVe Any 9 /)) {
        my $list_normal=$custlist->search('text_normal', 'ws', $pattern);
        my $list_words=$custlist->search('text_words', 'ws', $pattern);
        my $jn=join(',',sort @{$list_normal});
        my $jw=join(',',sort @{$list_words});
        $self->assert($jn eq $jw,
                      "Search results differ ('$jn' != '$jw') for '$pattern'");
    }

    ##
    # Benchmarking dictionary now
    #
    open(SE,">&STDOUT");
    close(STDERR);
    use Benchmark qw(timethese);
    my $bm=timethese(200, {
        normal_wq   => sub {
            $custlist->search(['text_normal', 'wq', 'reward'])
        },
        words_wq    => sub {
            $custlist->search(['text_words', 'wq', 'reward'])
        },
        normal_ws   => sub {
            $custlist->search(['text_normal', 'ws', 'live'])
        },
        words_ws    => sub {
            $custlist->search(['text_words', 'ws', 'live'])
        }
    });
    ## cmpthese($bm);
    open(STDOUT,">&SE");

    my $tnwq=$bm->{normal_wq}->[0];
    my $twwq=$bm->{words_wq}->[0];
    my $tnws=$bm->{normal_ws}->[0];
    my $twws=$bm->{words_ws}->[0];
    $self->assert($tnwq > $twwq,
                  "Dictionary is slower then plain search on 'wq' ($tnwq <= $twwq)");

    ##
    # This is something to work on probably. MySQL is so fast that it is
    # faster then dictionarized search on small sets. So, we check that
    # for some relatively useful timing and that's all.
    #
    $self->assert($tnws > $twws/2,
                  "Dictionary is slower then plain search on 'ws' ($tnws <= $twws/2)");

    $customer->drop_placeholder('text_normal');
    $customer->drop_placeholder('text_words');
}

1;
