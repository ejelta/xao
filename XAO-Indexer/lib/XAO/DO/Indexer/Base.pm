=head1 NAME

XAO::DO::Indexer::Base -- Dynamic content management for XAO::Web

=head1 SYNOPSIS

 <%Content name="about_us"%>

=head1 DESCRIPTION

For installation and usage instruction see "INSTALLATION AND USAGE"
chapter below.

Content objec
package XAO::DO::Indexer::Base;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects qw(get_current_project);
use Digest::MD5 qw(md5_base64);
use base XAO::Objects->load(objname => 'Atom');

### use Data::Dumper;

###############################################################################

use vars qw($VERSION);
$VERSION='1.0';

###############################################################################

=item analyze_text ($@)

Splits given text strings into keywords and stores them into kw_data
hash (first argument) using unique id from the second argument.

=cut

sub analyze_text ($$$@) {
    my $self=shift;
    my $kw_data=shift;
    my $unique_id=shift;

    $kw_data->{keywords}||={};
    my $kw_info=$kw_data->{keywords};

    my $field_num=1;
    foreach my $text (@_) {
        my $kwlist=$self->analyze_text_split($field_num,$text);
        my $pos=1;
        foreach my $kw (@$kwlist) {
            $kw_data->{count_uid}->{$unique_id}->{$kw}++;
            if(! exists $kw_data->{ignore}->{$kw}) {
                push(@{$kw_info->{lc($kw)}->{$unique_id}->{$field_num}},$pos);
            }
            $pos++;
        }
        $field_num++;
    }
}

###############################################################################

sub analyze_text_split ($$$) {
    my ($self,$field_num,$text)=@_;
    my @a=split(/\W+/,lc($text));
    shift @a if @a && !$a[0];
    return \@a;
}

###############################################################################

sub init ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{index_object} ||
        throw $self "init - no 'index_object'";

    dprint ref($self)."::init - XXX, nothing's in here yet....";
}

###############################################################################

sub search ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{index_object} ||
        throw $self "search - no 'index_object'";

    my $str=$args->{search_string};
    $str='' unless defined $str;
    $str=~s/^\s*(.*?)\s*$/$1/sg;
    if(!length($str)) {
        dprint ref($self)."::search - empty search string";
        return [ ];
    }

    my $ordering=$args->{ordering} ||
        throw $self "search - no 'ordering'";

    dprint "Searching for '$str' (ordering=$ordering)";

    ##
    # We cache ignored words. Cache returns a hash reference with
    # ignored words.
    #
    my $i_cache=get_current_project()->cache(
        name        => 'indexer_ignored',
        coords      => [ 'index_id' ],
        expire      => 3,
        retrieve    => sub {
            my $index_list=shift;
            my $args=get_args(\@_);
            my $index_id=$args->{index_id};
            dprint "CACHE: retrieving ignored words for index $index_id";
            my $ign_list=$index_list->get($index_id)->get('Ignore');
            my %ignored=map {
                $ign_list->get($_)->get('keyword','count');
            } $ign_list->keys;
            return \%ignored;
        },
    );
    my $ignored=$i_cache->get($index_object->container_object, {
        index_id    => $index_object->container_key,
    });

    ##
    # Building multi-word sequences. If some words are in the
    # ignore-list we skip them, but assume that there is a word in
    # between in word sequences. For instance 'wag the dog' would become
    # { wag => 1, dog => 3 }, providing that 'the' is ignored.
    #
    my @mdata;
    $str=~s/"(.*?)"/push(@mdata,$1);" "/sge;
    my @multi;
    my @simple;
    foreach my $elt (@mdata) {
        my $s=$self->analyze_text_split(0,$elt);
        next unless @$s;
        if(@$s==1) {
            push(@simple,$s->[0]);
        }
        else {
            my @t=map { $ignored->{$_} ? undef : $_ } @$s;
            shift(@t) while @t && !defined($t[0]);
            pop(@t) while @t && !defined($t[$#t]);
            if(@t==1) {
                push(@simple,$t[0]);
            }
            else {
                push(@multi,\@t);
            }
        }
    }
    undef @mdata;

    ##
    # Simple words
    #
    push(@simple,map { $ignored->{$_} ? () : $_ }
                     @{$self->analyze_text_split(0,$str)});
    
    #dprint Dumper(\@multi),Dumper(\@simple);

    ##
    # First we search for multi-words sequences in the assumption that
    # they will provide smaller result sets or no results at all.
    #
    my @results;
    my $data_list=$index_object->get('Data');
    foreach my $marr (sort { scalar(@$b) <=> scalar(@$a) } @multi) {
        my $res=$self->search_multi($data_list,$ordering,$marr);
        #dprint "Multi Results: ",Dumper($marr),Dumper($res);
        if(!@$res) {
            return [ ];
        }
        push(@results,$res);
    }

    ##
    # Searching for simple words, position independent. Longer words first.
    #
    foreach my $kw (sort { length($b) <=> length($a) } @simple) {
        my $res=$self->search_simple($data_list,$ordering,$kw);
        #dprint "Simple Results: '$kw' ",Dumper($res);
        if(!@$res) {
            return [ ];
        }
        push(@results,$res);
    }

    ##
    # Joining all results together
    #
    my $base;
    ($base,@results)=sort { scalar(@$a) <=> scalar(@$b) } @results;
    my @cursors;
    my @final;
    BASE_ID:
    foreach my $id (@$base) {
        RESULT:
        for(my $i=0; $i<@results; $i++) {
            my $rdata=$results[$i];
            my $j=$cursors[$i] || 0;
            for(; $j<@$rdata; $j++) {
                if($id == $rdata->[$j]) {
                    $cursors[$i]=$j;
                    next RESULT;
                }
            }
            next BASE_ID;
        }
        push(@final,$id);
    }

    return \@final;
}

###############################################################################

sub search_multi ($$$$) {
    my ($self,$data_list,$ordering,$marr)=@_;

    ##
    # Converting array into a hash for easier access
    #
    my $i=0;
    my %mhash=map { $i++; defined($_) ? ($i => $_) : () } @$marr;

    ##
    # Getting results. On null results exit immediately.
    #
    my %reshash;
    my $short_data;
    my $short_wnum;
    foreach my $wnum (sort { length($mhash{$b}) <=> length($mhash{$a}) } keys %mhash) {
        my $kw=$mhash{$wnum};
        my $sr=$data_list->search('keyword','eq',$kw);
        return [ ] unless @$sr;
        my $posdata=$data_list->get($sr->[0])->get("idpos_$ordering");
        my $posdec=$self->decode_posdata($posdata);
        if(!$short_data || scalar(@$short_data)>scalar(@$posdec)) {
            $short_data=$posdec;
            $short_wnum=$wnum;
        }
        $reshash{$wnum}=$posdec;
    }

    ##
    # Joining results using word position data
    #
    my %cursors;
    my @final;

    SHORT_ID:
    foreach my $short_iddata (@$short_data) {
        my ($short_id,$short_posdata)=@$short_iddata;

        ##
        # First we find IDs where all words at least exist in some
        # positions
        #
        my %found;
        foreach my $wnum (keys %reshash) {
            next if $wnum == $short_wnum;
            my $data=$reshash{$wnum};

            my ($id,$posdata);
            my $i=$cursors{$wnum} || 0;
            for(; $i<@$data; $i++) {
                ($id,$posdata)=@{$data->[$i]};
                last if $id == $short_id;
            }
            if($i>=@$data) {
                next SHORT_ID;
            }
            $cursors{$wnum}=$i+1;
            $found{$wnum}=$posdata;
        }

        ##
        # Now, we check if there are any correct sequences of these
        # words in the same source field.
        #
        # Finding a field that is present in all found references.
        #
        SHORT_FNUM:
        foreach my $fnum (keys %$short_posdata) {
            my $short_fdata=$short_posdata->{$fnum};

            my %fdhash;
            foreach my $wnum (keys %found) {
                my $posdata=$found{$wnum};
                my $fdata=$posdata->{$fnum};
                next SHORT_FNUM unless $fdata;
                $fdhash{$wnum}=$fdata;
            }

            SHORT_POS:
            foreach my $short_pos (@$short_fdata) {
                foreach my $wnum (keys %fdhash) {
                    my $reqpos=$short_pos+$wnum-$short_wnum;
                    next SHORT_POS if $reqpos<=0;
                    if(! grep { $_ == $reqpos } @{$fdhash{$wnum}}) {
                        next SHORT_POS;
                    }
                }
                push(@final,$short_id);
                next SHORT_ID;
            }
        }
    }

    return \@final;
}

###############################################################################

sub search_simple ($$$$) {
    my ($self,$data_list,$ordering,$keyword)=@_;

    my $sr=$data_list->search('keyword','eq',$keyword);
    return [ ] unless @$sr;

    my $iddata=$data_list->get($sr->[0])->get("id_$ordering");
    return [ split(/,/,$iddata) ];
}

###############################################################################

sub update ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{index_object} ||
        throw $self "update - no 'index_object'";

    my ($coll,$coll_ids)=$self->get_collection($args);

    ##
    # Getting keyword data
    #
    dprint "Analyzing data..";
    my %kw_data;
    foreach my $coll_id (@$coll_ids) {
        my $coll_obj=$coll->get($coll_id);
        $self->analyze_object(
            collection      => $coll,
            object          => $coll_obj,
            object_id       => $coll_id,
            kw_data         => \%kw_data,
        );

        ##
        # Checking if it's time to ignore some keywords
        #
        my $count_uid=$kw_data{count_uid}->{$coll_id};
        foreach my $kw (keys %$count_uid) {
            if(++$kw_data{counts}->{$kw} > 500) {
                $kw_data{ignore}->{$kw}=1;
            }
        }
        delete $kw_data{count_uid}->{$coll_id};
    }

    ##
    # Sorting and storing
    #
    dprint "Sorting and storing..";
    $index_object->glue->transact_begin;
    my $data_list=$index_object->get('Data');
    my $nd=$data_list->get_new;
    my $ignore_list=$index_object->get('Ignore');
    my $ni=$ignore_list->get_new;

    my $now=time;
    $ni->put(create_time => $now);
    $nd->put(create_time => $now);

    foreach my $kw (keys %{$kw_data{keywords}}) {
        my $kwd=$kw_data{keywords}->{$kw};

        my $kwmd5=md5_base64($kw);
        $kwmd5=~s/\W/_/g;

        if($kw_data{ignore}->{$kw}) {
            #dprint "Ignoring $kw ($kwmd5)";
            $ni->put(
                keyword => $kw,
                count   => $kw_data{counts}->{$kw},
            );
            $ignore_list->put($kwmd5 => $ni);
            next;
        }

        #dprint "Storing $kw ($kwmd5)";

        my $o_hash=$self->get_orderings;

        foreach my $o_name (keys %$o_hash) {
            my $o_sub=$o_hash->{$o_name};
            my $iddata='';
            my $posdata='';
            foreach my $id (sort { &{$o_sub}(\%kw_data,$a,$b) } keys %$kwd) {
                $iddata.=',' if $iddata;
                $iddata.=$id;
                $posdata.=':' if $posdata;
                $posdata.="$id;" .
                          join(';',map {
                                       "$_," .
                                       join(',',@{$kwd->{$id}->{$_}})
                                   }
                                   keys %{$kwd->{$id}}
                              );
            }

            $nd->put(
                "id_$o_name"    => $iddata,
                "idpos_$o_name" => $posdata,
            );
        }

        $nd->put(
            keyword         => $kw,
            count           => $kw_data{counts}->{$kw},
        );

        $data_list->put($kwmd5 => $nd);
    }

    ##
    # Deleting outdated records
    #
    dprint "Deleting older records..";
    my $sr=$data_list->search('create_time','ne',$now);
    foreach my $id (@$sr) {
        $data_list->delete($id);
    }
    $sr=$ignore_list->search('create_time','ne',$now);
    foreach my $id (@$sr) {
        $ignore_list->delete($id);
    }

    ##
    # Committing changes into the database
    #
    dprint "Done";
    $index_object->glue->transact_commit;
}

###############################################################################

sub analyze_object ($%) {
    my $self=shift;
    throw $self "analyze_object - pure virtual method called";
}

###############################################################################

sub decode_posdata ($$) {
    my ($self,$posdata)=@_;

    my @d;
    foreach my $iddata (split(/:/,$posdata)) {
        my ($id,@poslist)=split(/;/,$iddata);
        my %wd;
        foreach my $posgroup (@poslist) {
            my ($fnum,@wnums)=split(/,/,$posgroup);
            $wd{$fnum}=\@wnums;
        }
        push(@d,[ $id, \%wd ]);
    }

    return \@d;
}

###############################################################################

sub get_collection ($%) {
    my $self=shift;
    throw $self "get_collection - pure virtual method called";
}

###############################################################################
1;
