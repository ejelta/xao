package testcases::index;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(testcases::base);

sub test_index_int {
    my $self=shift;

    my $odb=$self->get_odb();

    my $testq=2000;

    my $clist=$odb->fetch('/Customers');
    my $cust=$clist->get_new();

    ##
    # Normal search
    #
    $cust->add_placeholder(name => 'int',
                           type => 'integer',
                           minvalue => 0,
                           maxvalue => $testq);

    my ($fill_normal,$s1_normal,$s2_normal)=$self->measure_integer($testq,$clist);
    ## dprint "$fill_normal $s1_normal $s2_normal";

    $cust->drop_placeholder('int');

    ##
    # Indexed search
    #
    $cust->add_placeholder(name => 'int',
                           type => 'integer',
                           minvalue => 0,
                           maxvalue => $testq,
                           index => 1);
    my ($fill_index,$s1_index,$s2_index)=$self->measure_integer($testq,$clist);
    ## dprint "$fill_index $s1_index $s2_index";

    ##
    # Do we need this kind of checks for real programs? This has to do
    # only with speed optimisations, functionality is not affected..
    #
    return 0 if $odb->_driver->{no_null_indexes};

    $self->assert($s1_normal>$s1_index,
                  "Indexed search takes longer then normal ($s1_index>$s1_normal)");
}

sub measure_integer {
    my $self=shift;
    my $testq=shift;
    my $clist=shift;

    my $cust=$clist->get_new();

    my $before_fill=$self->timestamp;
    my @xx;
    for(my $i=0; $i!=$testq; $i++) {
        $cust->put(int => $i);
        push(@xx,$clist->put($cust));
    }

    my $list;
    my $before_search_1=$self->timestamp;
    for(1..1000) {
        $list=$clist->search('int', 'eq', 123);
    }
    my $after_search_1=$self->timestamp;

    $self->assert(@$list==1,
                  "Returned wrong number of objects in fill_and_measure");

    my $before_search_range=$self->timestamp;
    for(1..10) {
        $list=$clist->search([ 'int', 'ge', 123 ],
                             'and',
                             [ 'int', 'le', 234 ]);
    }
    my $after_search_range=$self->timestamp;

    my $got=scalar(@$list);
    $self->assert($got==112,
                  "Returned wrong number of objects ($got!=112)");

    foreach my $id (@xx) {
        $clist->delete($id);
    }

    ( $self->timediff($before_search_1,$before_fill),
      $self->timediff($after_search_1,$before_search_1),
      $self->timediff($after_search_range,$before_search_range)
    );
}

1;
