package XAO::DO::Indexer::Foo;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Indexer::Base');

###############################################################################

sub analyze_object ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $coll=$args->{collection};
    my $foo=$args->{object};
    my $foo_id=$args->{object_id};
    my $kw_data=$args->{kw_data};

    my ($name,$text)=$foo->get('name','text');

    $kw_data->{sorting}->{name}->{$foo_id}=$name;
    $kw_data->{sorting}->{text}->{$foo_id}=$text;

    my $bar_list=$foo->get('Bar');
    my $bar_names='';
    my $bar_texts='';
    foreach my $bar_id ($bar_list->keys) {
        my ($n,$t)=$bar_list->get($bar_id)->get('name','text');
        $bar_names.=$n . ' ';
        $bar_texts.=$t . ' ';
    }

    $self->analyze_text($kw_data,$foo_id,$name,$text,$bar_names,$bar_texts);
}

###############################################################################

sub get_collection ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    wantarray ||
        throw $self "get_collection - called in scalar context";

    my $index_object=$args->{index_object} ||
        throw $self "update - no 'index_object'";

    my $odb=$index_object->glue;
    my $collection=$odb->collection(class => 'Data::Foo');

    my @ids=$collection->keys;

    return ($collection,\@ids);
}

###############################################################################

sub get_orderings ($) {
    my $self=shift;
    return {
        name    => {
            seq     => 1,
            sortsub => sub {
                my ($kw_data,$a,$b)=@_;
                my $cpa=lc($kw_data->{sorting}->{name}->{$a});
                my $cpb=lc($kw_data->{sorting}->{name}->{$b});
                return ($cpa cmp $cpb);
            },
        },
        text    => {
            seq     => 2,
            sortsub => sub {
                my ($kw_data,$a,$b)=@_;
                my $cpa=lc($kw_data->{sorting}->{text}->{$a});
                my $cpb=lc($kw_data->{sorting}->{text}->{$b});
                return ($cpa cmp $cpb);
            },
        },
        name_wnum => {
            seq     => 3,
            sortsub => sub {
                my ($kw_data,$a,$b)=@_;
                my @na=split(/\s+/,$kw_data->{sorting}->{name}->{$a});
                my @nb=split(/\s+/,$kw_data->{sorting}->{name}->{$b});
                return (scalar(@na) <=> scalar(@nb));
            },
        },
    };
}

###############################################################################

sub ignore_limit ($) {
    return 120;
}

###############################################################################
1;
